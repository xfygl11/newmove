import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../../agent/active_image.dart';
import '../../agent/active_llm.dart';
import '../../agent/active_video.dart';
import '../../core/network/image_provider_adapter.dart';
import '../../core/network/video_provider_adapter.dart';
import '../../core/storage/shot_file_store.dart';
import '../../core/storage/video_file_store.dart';
import '../../data/app_database.dart';
import '../../data/daos/asset_dao.dart';
import '../../data/daos/asset_ref_dao.dart';
import '../../data/daos/beat_dao.dart';
import '../../data/daos/scene_dao.dart';
import '../../data/daos/script_dao.dart';
import '../../data/daos/shot_dao.dart';
import '../../data/daos/shot_frame_dao.dart';
import '../../data/daos/video_task_dao.dart';
import '../../data/daos/provider_dao.dart';
import '../provider_config/provider_models.dart';
import 'shot_agents.dart';
import 'shot_models.dart';
import 'video_prompt.dart';

/// 分镜图的业务编排：上下文构建、导演落库、多参考图生成、衔接校验、视频生成。
class ShotService {
  ShotService({
    required this.scriptDao,
    required this.sceneDao,
    required this.beatDao,
    required this.shotDao,
    required this.shotFrameDao,
    required this.assetRefDao,
    required this.assetDao,
    required this.agents,
    required this.imageAdapter,
    required this.fileStore,
    required this.videoAdapter,
    required this.videoFileStore,
    required this.videoTaskDao,
    required this.providerDao,
  });

  final ScriptDao scriptDao;
  final SceneDao sceneDao;
  final BeatDao beatDao;
  final ShotDao shotDao;
  final ShotFrameDao shotFrameDao;
  final AssetRefDao assetRefDao;
  final AssetDao assetDao;
  final ShotAgents agents;
  final ImageProviderAdapter imageAdapter;
  final ShotFileStore fileStore;
  final VideoProviderAdapter videoAdapter;
  final VideoFileStore videoFileStore;
  final VideoTaskDao videoTaskDao;
  final ProviderDao providerDao;

  // ---- 分镜提示词（T6.2 / T6.3） ----

  /// 构建 ShotDirector 上下文：分段 + 节拍摘要 + 可用资产清单。
  Future<String> buildDirectionContext(int scriptId) async {
    final script = await scriptDao.find(scriptId);
    final scenes = await sceneDao.listByScript(scriptId);
    final beats = await beatDao.listByScript(scriptId);
    final shots = await shotDao.listByScript(scriptId);
    final assets = await assetDao.listByScript(scriptId);

    final beatById = <String, Beat>{for (final b in beats) b.sourceRef: b};
    final sceneBySeq = <int, Scene>{for (final s in scenes) s.seq: s};

    final buf = StringBuffer();
    buf.writeln('【画面风格】${script?.artStyle ?? '日式 2D 动画，干净线稿，柔和上色'}');
    buf.writeln('【可用资产清单（仅可绑定这些 stableId）】');
    buf.writeln(jsonEncode([
      for (final a in assets)
        {
          'stableId': a.stableId,
          'type': a.type,
          'name': a.name,
        },
    ]));
    buf.writeln('【分段与节拍】');
    buf.writeln(jsonEncode([
      for (final s in shots)
        {
          'globalSeq': s.globalSeq,
          'batch': s.batch,
          'durationMs': s.durationMs,
          'globalTimeRange': s.globalTimeRange,
          'beatRefs': _decodeList(s.beatRefs),
          'assetStates': _decodeMap(s.assetStates),
          'beats': [
            for (final ref in _decodeList(s.beatRefs))
              if (beatById[ref] != null)
                {
                  'id': beatById[ref]!.sourceRef,
                  'type': beatById[ref]!.type,
                  'who': beatById[ref]!.who,
                  'content': beatById[ref]!.content,
                },
          ],
          'scene': () {
            final scene = sceneBySeq[s.sceneId];
            if (scene == null) return null;
            return {'location': scene.location, 'time': scene.time};
          }(),
        },
    ]));
    buf.writeln('请按规则输出分镜提示词 JSON。');
    return buf.toString();
  }

  /// 从分镜草案中筛出与该剧本现有分段匹配的条目（防 LLM 幻觉编号）。
  List<ShotDraft> _matchDrafts(List<ShotDraft> drafts, List<Shot> shots) {
    final known = <String>{for (final s in shots) s.globalSeq};
    return [
      for (final d in drafts)
        if (known.contains(d.globalSeq)) d,
    ];
  }

  /// 生成全部镜头的分镜提示词并落库（整体替换帧与参考绑定）。
  Future<ShotDirectionSummary> directAndSave({
    required int scriptId,
    required ActiveLlm llm,
  }) async {
    final context = await buildDirectionContext(scriptId);
    final result = await agents.direct(prompt: context, llm: llm);

    final shots = await shotDao.listByScript(scriptId);
    final drafts = _matchDrafts(result.shots, shots);
    final assets = {
      for (final a in await assetDao.listByScript(scriptId)) a.stableId: a,
    };

    var frameCount = 0;
    var refCount = 0;

    for (final draft in drafts) {
      final shot = shots.firstWhere((s) => s.globalSeq == draft.globalSeq);

      await shotDao.updateById(
        shot.id,
        ShotsCompanion(
          shotType: Value(ShotDraft.normalizeShotType(draft.shotType)),
          prompt: Value(draft.prompt),
          status: const Value(ShotStatuses.awaitingImage),
        ),
      );

      // 帧与参考绑定整体替换。
      await shotFrameDao.deleteByShot(shot.id);
      for (final f in draft.frames) {
        await shotFrameDao.insert(
          ShotFramesCompanion.insert(
            shotId: shot.id,
            seq: f.seq,
            timeRange: f.timeRange.isEmpty ? '-' : f.timeRange,
            subject: f.subject.isEmpty ? '未指定' : f.subject,
            shotSize: f.shotSize.isEmpty ? draft.shotType : f.shotSize,
            angle: f.angle,
            camera: Value(f.camera),
            blocking: Value(f.blocking),
            performance: Value(f.performance),
            dialogue: Value(f.dialogue),
          ),
        );
        frameCount++;
      }

      await assetRefDao.deleteByShot(shot.id);
      for (final r in draft.refs) {
        final asset = assets[r.stableId];
        // stableId 解析失败时跳过，不编造绑定。
        if (asset == null) continue;
        await assetRefDao.insert(
          AssetRefsCompanion.insert(
            shotId: shot.id,
            assetId: asset.id,
            role: r.role,
            order: Value(refCount),
          ),
        );
        refCount++;
      }
    }

    return ShotDirectionSummary(
      shotCount: drafts.length,
      frameCount: frameCount,
      refCount: refCount,
    );
  }

  // ---- 分镜图生成（T6.4） ----

  /// 生成分镜图（0 参考文生图 / ≥1 参考图生图），成功后写入产物路径。
  Future<Shot> generate({
    required int shotId,
    required ActiveImage image,
  }) async {
    final shot = await shotDao.find(shotId);
    if (shot == null) throw StateError('镜头不存在：$shotId');
    if (shot.prompt.isEmpty) throw StateError('镜头尚未生成分镜提示词');

    await shotDao.updateById(
      shotId,
      ShotsCompanion(status: const Value(ShotStatuses.generating)),
    );

    try {
      final bytes = await _generateBytes(shot, image);
      final path = await fileStore.save(shotId, bytes);
      await shotDao.updateById(
        shotId,
        ShotsCompanion(
          outputPath: Value(path),
          status: const Value(ShotStatuses.reviewing),
        ),
      );
      return (await shotDao.find(shotId))!;
    } catch (_) {
      // 失败回滚到「待分镜图」，保留提示词便于重试。
      await shotDao.updateById(
        shotId,
        ShotsCompanion(status: const Value(ShotStatuses.awaitingImage)),
      );
      rethrow;
    }
  }

  /// 批量生成：按传入顺序串行执行，模拟排队 → 提交 → 生成中 → 成功/失败。
  ///
  /// 单个失败不中断后续任务，最终返回成功数量；失败明细由调用方从状态推断。
  Future<ShotBatchResult> generateSelected({
    required List<int> shotIds,
    required ActiveImage image,
    void Function(int done, int total, int shotId)? onProgress,
  }) async {
    var success = 0;
    var failed = 0;
    final total = shotIds.length;

    for (var i = 0; i < shotIds.length; i++) {
      onProgress?.call(i, total, shotIds[i]);
      try {
        await generate(shotId: shotIds[i], image: image);
        success++;
      } catch (_) {
        failed++;
      }
    }
    onProgress?.call(total, total, -1);

    return ShotBatchResult(success: success, failed: failed);
  }

  /// 组装参考图并按需替换 {{ref N}}，调用适配器生成图片字节。
  Future<Uint8List> _generateBytes(Shot shot, ActiveImage image) async {
    final refs = await assetRefDao.listByShot(shot.id);
    final prompt = await _resolvePrompt(shot, refs);

    if (refs.isEmpty) {
      final result = await imageAdapter.textToImage(
        baseUrl: image.baseUrl,
        apiKey: image.apiKey,
        model: image.modelId,
        prompt: prompt,
      );
      return _bytesOf(result);
    }

    // 参考图仅取已采用或已生成图（待验收）的资产；无图资产跳过。
    final paths = <String>[];
    for (final ref in refs) {
      final asset = await assetDao.find(ref.assetId);
      final path = asset?.imagePath;
      if (path == null || path.isEmpty || !File(path).existsSync()) continue;
      paths.add(path);
    }

    if (paths.isEmpty) {
      final result = await imageAdapter.textToImage(
        baseUrl: image.baseUrl,
        apiKey: image.apiKey,
        model: image.modelId,
        prompt: prompt,
      );
      return _bytesOf(result);
    }

    if (paths.length == 1) {
      final result = await imageAdapter.imageToImage(
        baseUrl: image.baseUrl,
        apiKey: image.apiKey,
        model: image.modelId,
        prompt: prompt,
        referencePath: paths.single,
      );
      return _bytesOf(result);
    }

    final result = await imageAdapter.imageToImageMulti(
      baseUrl: image.baseUrl,
      apiKey: image.apiKey,
      model: image.modelId,
      prompt: prompt,
      referencePaths: paths,
    );
    return _bytesOf(result);
  }

  /// 把提示词中的 {{ref N}} 替换为「参考图 N（资产名）」的语义描述。
  Future<String> _resolvePrompt(Shot shot, List<AssetRef> refs) async {
    var prompt = shot.prompt;
    for (var i = 0; i < refs.length; i++) {
      final asset = await assetDao.find(refs[i].assetId);
      if (asset == null) continue;
      prompt = prompt.replaceAll(
        '{{ref${i + 1}}}',
        '参考图${i + 1}（${asset.type}·${asset.name}）',
      );
    }
    return prompt;
  }

  /// 从生成结果中取字节；远程 URL 时下载。
  Future<Uint8List> _bytesOf(ImageGenerationResult result) async {
    final bytes = result.bytes;
    if (bytes != null) return bytes;
    final url = result.url;
    if (url != null && url.isNotEmpty) {
      return imageAdapter.downloadUrl(url);
    }
    throw StateError('供应商未返回图片数据');
  }

  // ---- 衔接校验（T6.5 / A7） ----

  /// 相邻段 A7 衔接校验：主体不同 / 景别差≥2 / 角度差≥90°，三者全不满足时告警。
  Future<List<ShotTransitionIssue>> listTransitionIssues(int scriptId) async {
    final shots = await shotDao.listByScript(scriptId);
    final issues = <ShotTransitionIssue>[];

    for (var i = 0; i < shots.length - 1; i++) {
      final a = shots[i];
      final b = shots[i + 1];
      if (a.status == ShotStatuses.awaitingPrompt ||
          b.status == ShotStatuses.awaitingPrompt) {
        // 尚未生成分镜提示词的段不参与校验。
        continue;
      }

      final subjectA = await _subjectsOf(a.id);
      final subjectB = await _subjectsOf(b.id);
      final subjectSame = subjectA.intersection(subjectB).isNotEmpty;
      final sizeGap =
          (_shotSizeRank(a.shotType) - _shotSizeRank(b.shotType)).abs();
      final angleA = await _angleDegreesOf(a.id);
      final angleB = await _angleDegreesOf(b.id);
      final angleGap = (angleA - angleB).abs();

      if (subjectSame && sizeGap < 2 && angleGap < 90) {
        issues.add(
          ShotTransitionIssue(
            fromSeq: a.globalSeq,
            toSeq: b.globalSeq,
            reason: 'no_contrast',
            message: '${a.globalSeq} 与 ${b.globalSeq} 主体相同、'
                '景别差 $sizeGap 档、角度差 $angleGap°，缺少画面区分度（A7）',
          ),
        );
      }
    }
    return issues;
  }

  /// 用帧的主体集合代表段主体。
  Future<Set<String>> _subjectsOf(int shotId) async {
    final frames = await shotFrameDao.listByShot(shotId);
    return {for (final f in frames) f.subject};
  }

  /// 用首帧的角度近似段角度。
  Future<int> _angleDegreesOf(int shotId) async {
    final frames = await shotFrameDao.listByShot(shotId);
    if (frames.isEmpty) return 0;
    return _angleDegrees(frames.first.angle);
  }

  /// 景别档位：远景1 全景2 中景3 近景4 特写5。
  int _shotSizeRank(String? shotType) {
    final text = shotType ?? '';
    if (text.contains('特')) return 5;
    if (text.contains('近')) return 4;
    if (text.contains('全')) return 2;
    if (text.contains('远')) return 1;
    return 3;
  }

  /// 粗略角度近似值：平视/侧面 0°，俯/仰 45°，背面 180°。
  int _angleDegrees(String? angle) {
    final text = angle ?? '';
    if (text.contains('背')) return 180;
    if (text.contains('俯') || text.contains('仰')) return 45;
    return 0;
  }

  // ---- 视频生成（M6：T7.1–T7.4） ----

  /// 提交视频生成任务（排队 → 生成中），返回任务行。
  ///
  /// 前置条件：镜头已有分镜图（作为首帧参考）与提示词。
  /// 参考图取已生成分镜图 + 已采用资产图，上限 9 张。
  Future<VideoTask> submitVideo({
    required int shotId,
    required ActiveVideo video,
    required VideoGenParams params,
  }) async {
    final shot = await shotDao.find(shotId);
    if (shot == null) throw StateError('镜头不存在：$shotId');
    if (shot.prompt.isEmpty) throw StateError('镜头尚未生成分镜提示词');

    // 组装参考图：分镜图优先，其次已采用资产图。
    // 首帧通道开启时，分镜图改走 `first_frame` 角色，不再计入普通参考。
    final referencePaths = <String>[];
    String? firstFramePath;
    final storyboardPath = shot.outputPath;
    if (params.useFirstFrame &&
        storyboardPath != null &&
        storyboardPath.isNotEmpty &&
        File(storyboardPath).existsSync()) {
      firstFramePath = storyboardPath;
    } else if (storyboardPath != null &&
        storyboardPath.isNotEmpty &&
        File(storyboardPath).existsSync()) {
      referencePaths.add(storyboardPath);
    }
    // 模型参考上限（能力字段；缺省回退 9）。
    final providerModels = ProviderModelCodec.decode(video.provider.models);
    final selectedModel = providerModels.firstWhere(
      (m) => m.id == params.modelId,
      orElse: () => video.model,
    );
    final maxRefs = selectedModel.maxImageRefs ?? 9;

    final refs = await assetRefDao.listByShot(shotId);
    for (final ref in refs) {
      if (referencePaths.length + (firstFramePath == null ? 0 : 1) >= maxRefs) {
        break;
      }
      final asset = await assetDao.find(ref.assetId);
      final path = asset?.imagePath;
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        referencePaths.add(path);
      }
    }
    final actualParams = VideoGenParams(
      modelId: params.modelId,
      durationSec: params.durationSec,
      ratio: params.ratio,
      resolution: params.resolution,
      generateAudio: params.generateAudio,
      referenceCount: referencePaths.length + (firstFramePath == null ? 0 : 1),
      useFirstFrame: firstFramePath != null,
    );

    // 构造 A9 视频提示词（时长取参数面板选择值）。
    final frames = await shotFrameDao.listByShot(shotId);
    final prompt = const VideoPromptBuilder().build(
      shot: shot,
      frames: frames,
      refs: refs,
      assetById: {
        for (final a in await assetDao.listByScript(shot.scriptId)) a.id: a,
      },
      durationSec: params.durationSec,
    );

    // 提交（状态：视频生成中）。
    await shotDao.updateById(
      shotId,
      ShotsCompanion(
        modelVersion: Value(params.modelId),
        status: const Value(ShotStatuses.videoGenerating),
        outputType: const Value('video'),
      ),
    );

    try {
      final taskId = await videoAdapter.submit(
        baseUrl: video.baseUrl,
        apiKey: video.apiKey,
        model: params.modelId,
        prompt: prompt,
        durationSec: params.durationSec,
        ratio: params.ratio,
        resolution: params.resolution,
        referencePaths: referencePaths,
        firstFramePath: firstFramePath,
        maxImageRefs: maxRefs,
        generateAudio: params.generateAudio,
      );
      final id = await videoTaskDao.insert(
        VideoTasksCompanion.insert(
          shotId: shotId,
          taskId: taskId,
          providerId: video.provider.id,
          status: const Value('生成中'),
          paramsJson: Value(actualParams.encode()),
        ),
      );
      return (await videoTaskDao.find(id))!;
    } catch (e) {
      // 提交失败回滚镜头状态。
      await shotDao.updateById(
        shotId,
        ShotsCompanion(
          status: const Value(ShotStatuses.confirmed),
          outputType: const Value('image'),
        ),
      );
      rethrow;
    }
  }

  /// 轮询一次视频任务；完成时回填产物路径与镜头状态。
  ///
  /// 返回更新后的任务；仍在生成中返回原状态。
  Future<VideoTask> pollVideoTask(int videoTaskId) async {
    final task = await videoTaskDao.find(videoTaskId);
    if (task == null) throw StateError('视频任务不存在：$videoTaskId');
    if (task.status == '成功' || task.status == '失败') return task;

    // 恢复供应商配置与 Key。
    final provider = await _findProvider(task.providerId);
    if (provider == null) {
      return _markVideoFailed(task, '供应商配置已删除，无法恢复轮询');
    }
    final apiKey = await readProviderKey?.call(task.providerId);
    if (apiKey == null || apiKey.isEmpty) {
      return _markVideoFailed(task, '供应商 API Key 不可用');
    }

    try {
      final snapshot = await videoAdapter.poll(
        baseUrl: provider.baseUrl,
        apiKey: apiKey,
        taskId: task.taskId,
      );

      if (snapshot.isSuccess) {
        // 取产物字节并落盘。
        final Uint8List bytes;
        if (snapshot.base64 != null) {
          bytes = base64Decode(snapshot.base64!);
        } else if (snapshot.url != null) {
          bytes = await videoAdapter.downloadUrl(snapshot.url!);
        } else {
          return await _markVideoFailed(task, '供应商未返回视频数据');
        }
        final path = await videoFileStore.save(task.shotId, bytes);
        await videoTaskDao.updateById(
          task.id,
          VideoTasksCompanion(
            status: const Value('成功'),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await shotDao.updateById(
          task.shotId,
          ShotsCompanion(
            outputPath: Value(path),
            status: const Value(ShotStatuses.videoDone),
          ),
        );
        return (await videoTaskDao.find(task.id))!;
      }

      if (snapshot.isFailed) {
        return await _markVideoFailed(task, snapshot.error ?? '视频生成失败');
      }

      // 仍在生成中。
      await videoTaskDao.updateById(
        task.id,
        VideoTasksCompanion(
          status: const Value('生成中'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await videoTaskDao.find(task.id))!;
    } catch (e) {
      // 网络异常不标记失败，保持生成中，下次轮询重试。
      return task;
    }
  }

  /// 标记任务失败并回滚镜头状态到「分镜图已确认」。
  Future<VideoTask> _markVideoFailed(VideoTask task, String error) async {
    await videoTaskDao.updateById(
      task.id,
      VideoTasksCompanion(
        status: const Value('失败'),
        error: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await shotDao.updateById(
      task.shotId,
      ShotsCompanion(status: const Value(ShotStatuses.confirmed)),
    );
    return (await videoTaskDao.find(task.id))!;
  }

  /// 按配置 id 查供应商行。
  Future<ProviderConfig?> _findProvider(String id) {
    return providerDao.findById(id);
  }

  /// 供应商 Key 读取回调（由 provider 层注入，避免 Service 依赖 secure storage）。
  Future<String?> Function(String providerId)? readProviderKey;

  /// 确认视频（视频完成 → 用户确认，当前等同保持视频完成）。
  Future<void> confirmVideo(int shotId) async {
    await shotDao.updateById(
      shotId,
      ShotsCompanion(status: const Value(ShotStatuses.videoDone)),
    );
  }

  /// 重试失败的视频任务：复用原参数快照重新提交。
  Future<VideoTask> retryVideo({
    required int videoTaskId,
    required ActiveVideo video,
  }) async {
    final task = await videoTaskDao.find(videoTaskId);
    if (task == null) throw StateError('视频任务不存在：$videoTaskId');
    final params = VideoGenParams.decode(task.paramsJson);
    return submitVideo(
      shotId: task.shotId,
      video: video,
      params: params,
    );
  }

  // ---- 验收与编辑 ----

  /// 用户编辑分镜提示词（保留 {{ref N}} 占位）。
  Future<void> updatePrompt({
    required int shotId,
    required String prompt,
  }) async {
    await shotDao.updateById(
      shotId,
      ShotsCompanion(prompt: Value(prompt)),
    );
  }

  /// 确认分镜图（待验收 → 分镜图已确认）。
  Future<void> confirmShot(int shotId) async {
    await shotDao.updateById(
      shotId,
      ShotsCompanion(status: const Value(ShotStatuses.confirmed)),
    );
  }

  /// 驳回分镜图（待验收 → 待分镜图），可修改提示词后重新生成。
  Future<void> rejectShot(int shotId) async {
    await shotDao.updateById(
      shotId,
      ShotsCompanion(status: const Value(ShotStatuses.awaitingImage)),
    );
  }

  // ---- 内部辅助 ----

  List<String> _decodeList(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return [for (final v in decoded) v.toString()];
    } on FormatException {
      // 落库内容异常时按空处理。
    }
    return const [];
  }

  Map<String, dynamic> _decodeMap(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // 落库内容异常时按空处理。
    }
    return <String, dynamic>{};
  }
}

/// 一次分镜导演的落库结果摘要。
class ShotDirectionSummary {
  const ShotDirectionSummary({
    required this.shotCount,
    required this.frameCount,
    required this.refCount,
  });

  final int shotCount;
  final int frameCount;
  final int refCount;
}

/// 一次批量生成的结果摘要。
class ShotBatchResult {
  const ShotBatchResult({required this.success, required this.failed});

  final int success;
  final int failed;
}
