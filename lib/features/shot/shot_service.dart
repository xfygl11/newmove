import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;

import '../../agent/active_image.dart';
import '../../agent/active_llm.dart';
import '../../agent/active_video.dart';
import '../../core/app_log.dart';
import '../../core/json_values.dart';
import '../../core/status_constants.dart';
import '../../core/network/image_provider_adapter.dart';
import '../../core/network/video_provider_adapter.dart';
import '../../core/storage/shot_file_store.dart';
import '../../core/storage/storage_rules.dart';
import '../../core/storage/video_file_store.dart';
import '../../data/app_database.dart';
import '../../data/daos/asset_dao.dart';
import '../../data/daos/asset_ref_dao.dart';
import '../../data/daos/beat_dao.dart';
import '../../data/daos/generation_attempt_dao.dart';
import '../../data/daos/revision_dao.dart';
import '../../data/daos/scene_dao.dart';
import '../../data/daos/script_dao.dart';
import '../../data/daos/shot_dao.dart';
import '../../data/daos/shot_frame_dao.dart';
import '../../data/daos/video_task_dao.dart';
import '../../data/daos/provider_dao.dart';
import '../provider_config/provider_models.dart';
import '../script/script_models.dart';
import 'shot_agents.dart';
import 'shot_models.dart';
import 'segment_budget.dart';
import 'video_prompt.dart';

/// 分镜图的业务编排：上下文构建、导演落库、多参考图生成、衔接校验、视频生成。
class ShotService {
  ShotService({
    required this.db,
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
    required this.revisionDao,
    required this.attemptDao,
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

  /// 产物版本快照（M14 T16.6 / M18 T20.1）。
  ///
  /// 必填：曾是可选项，生产 provider 漏注入导致 M17 分镜侧快照与台账一行未执行，
  /// 而测试夹具犯了同样的省略所以全绿。改必填后由编译期守住。
  final RevisionDao revisionDao;

  /// 生成尝试台账（M14 T16.5.4 / M18 T20.1）。同样必填，理由同上。
  final GenerationAttemptDao attemptDao;

  /// 数据库实例：多表重建统一走 [AppDatabase.transaction]。
  final AppDatabase db;

  /// 单次轮询超时：网络半连接不返回时不阻塞整轮轮询。
  static const pollTimeout = Duration(seconds: 30);

  /// 一次轮询总时长上限（含下载产物），防止下载卡死拖住后台刷新。
  static const pollAllTimeout = Duration(seconds: 90);

  /// 任务存活上限：超过仍无进展即判超时，避免「生成中」永久挂起。
  static const pollStaleAfter = Duration(hours: 3);

  /// 正在轮询的任务：taskId → 进行中的 Future（去重锁）。
  static final Map<int, Future<VideoTask>> _pollingTasks = {};

  // ---- 产物版本快照与生成尝试台账（M14 T16.6 / T16.5.4） ----

  /// 组装镜头产物快照：提示词 / 状态 / 产物路径 / 帧 / 参考绑定。
  Future<String> snapshotOf(Shot shot) async {
    final frames = await shotFrameDao.listByShot(shot.id);
    final refs = await assetRefDao.listByShot(shot.id);
    final assets = {
      for (final a in await assetDao.listByScript(shot.scriptId)) a.id: a,
    };
    return jsonEncode({
      'globalSeq': shot.globalSeq,
      'batch': shot.batch,
      'durationMs': shot.durationMs,
      'timeRange': shot.globalTimeRange,
      'beatRefs': jsonList(shot.beatRefs),
      'shotType': shot.shotType,
      'sceneId': shot.sceneId,
      'prompt': shot.prompt,
      'status': shot.status,
      'outputPath': shot.outputPath,
      'outputType': shot.outputType,
      'frames': [
        for (final f in frames)
          {
            {
              'seq': f.seq,
              'timeRange': f.timeRange,
              'subject': f.subject,
              'shotSize': f.shotSize,
              'angle': f.angle,
              'camera': f.camera,
              'blocking': f.blocking,
              'performance': f.performance,
              'dialogue': f.dialogue,
            },
          },
      ],
      'refs': [
        for (final r in refs)
          {
            {
              'assetId': r.assetId,
              'name': assets[r.assetId]?.name,
              'role': r.role,
              'order': r.order,
            },
          },
      ],
    });
  }

  /// 保存一次产物快照。失败不得阻塞生成主流程，但必须留痕。
  Future<void> _saveShotSnapshot(
    int shotId,
    String kind,
    String summary,
  ) async {
    final shot = await shotDao.find(shotId);
    if (shot == null) return;
    try {
      await revisionDao.saveShot(
        shotId: shotId,
        kind: kind,
        snapshot: await snapshotOf(shot),
        summary: summary,
      );
    } catch (e, st) {
      appLog(
        'shot_snapshot',
        'shot=$shotId kind=$kind',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// 登记一次生成尝试：返回台账 id，用于结束后回写结果；失败返回 null。
  Future<int?> _recordAttempt({
    required String subjectType,
    required int subjectId,
    required String subjectLabel,
    required String prompt,
    required String params,
    List<Map<String, dynamic>> refs = const [],
    Map<String, dynamic> before = const {},
    int grantLimit = 1,
    int? bookId,
  }) async {
    try {
      return await attemptDao.insert(
        GenerationAttemptsCompanion.insert(
          projectId: Value(
            bookId == null ? null : await attemptDao.projectOfBook(bookId),
          ),
          subjectType: subjectType,
          subjectId: Value(subjectId),
          subjectLabel: Value(subjectLabel),
          prompt: prompt,
          params: Value(params),
          refs: Value(jsonEncode(refs)),
          before: Value(jsonEncode(before)),
          attemptNo: Value(
            await attemptDao.nextAttemptNo(subjectType, subjectId),
          ),
          grantLimit: Value(grantLimit),
          grantFingerprint: Value(
            _fingerprint(subjectType, subjectId, prompt, refs, grantLimit),
          ),
          status: const Value(AttemptStatuses.running),
        ),
      );
    } catch (e, st) {
      appLog(
        'attempt_start',
        '$subjectType#$subjectId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// 回写尝试结果。
  Future<void> _finishAttempt({
    int? id,
    required String status,
    String? resultPath,
    String? error,
  }) async {
    if (id == null) return;
    try {
      await attemptDao.finishAttempt(
        id: id,
        status: status,
        resultPath: resultPath,
        errorMessage: error,
      );
    } catch (e, st) {
      appLog('attempt_finish', '#$id -> $status', error: e, stackTrace: st);
    }
  }

  /// 授权指纹：数量 / 提示词 / 模式 / 引用顺序的摘要，供临执行复核比对。
  static String _fingerprint(
    String subjectType,
    int subjectId,
    String prompt,
    List<Map<String, dynamic>> refs,
    int grantLimit,
  ) {
    final sb = StringBuffer('$subjectType|$subjectId|$grantLimit|');
    sb.write(refs.map((r) => '${r['assetId']}:${r['role']}').join(','));
    sb.write('|');
    sb.write(prompt.length > 300 ? prompt.substring(0, 300) : prompt);
    return Object.hashAll(sb.toString().codeUnits).toRadixString(16);
  }

  /// 组装镜头参考文件台账行，顺序即上传顺序。
  Future<List<Map<String, dynamic>>> _refRowsOf(Shot shot) async {
    final refs = await assetRefDao.listByShot(shot.id);
    return [
      for (final r in refs)
        {
          'assetId': r.assetId,
          'role': r.role,
          'order': r.order,
          'variantOf': (await assetDao.find(r.assetId))?.variantOf,
        },
    ];
  }

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
    buf.writeln('【画面风格】${effectiveArtStyle(script?.artStyle)}');
    buf.writeln('【可用资产清单（仅可绑定这些 stableId）】');
    buf.writeln(
      jsonEncode([
        for (final a in assets)
          {'stableId': a.stableId, 'type': a.type, 'name': a.name},
      ]),
    );
    buf.writeln('【分段与节拍】');
    buf.writeln(
      jsonEncode([
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
      ]),
    );
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
    final directionAttempt = await _recordAttempt(
      subjectType: AttemptSubjects.shotDirection,
      subjectId: scriptId,
      subjectLabel: '剧本 #$scriptId 重新导演',
      prompt: context,
      params: jsonEncode({
        'provider': llm.provider.label,
        'model': llm.modelId,
        'maxOutputTokens': llm.model.maxOutputTokens,
        'budgetTokens': llm.budgetTokens,
      }),
      bookId: (await scriptDao.find(scriptId))?.bookId,
    );
    final result = await agents.direct(prompt: context, llm: llm);
    await _finishAttempt(
      id: directionAttempt,
      status: AttemptStatuses.succeeded,
    );

    final shots = await shotDao.listByScript(scriptId);
    final drafts = _matchDrafts(result.shots, shots);
    final assets = {
      for (final a in await assetDao.listByScript(scriptId)) a.stableId: a,
    };

    var frameCount = 0;
    var refCount = 0;

    // 重建整体包进一个事务：任一镜头的删帧/删绑定中断时全部回滚，
    // 不留「提示词已更新但帧为空」的半截状态。
    return db.transaction(() async {
      for (final draft in drafts) {
        final shot = shots.firstWhere((s) => s.globalSeq == draft.globalSeq);

        // 幂等：已出视频（或视频仍在生成中）的镜头不因重导降级，
        // 否则对应视频任务仍「成功」而镜头回退到待分镜图，状态自相矛盾。
        final nextStatus =
            shot.status == ShotStatuses.videoDone ||
                shot.status == ShotStatuses.videoGenerating
            ? shot.status
            : ShotStatuses.awaitingImage;
        await shotDao.updateById(
          shot.id,
          ShotsCompanion(
            shotType: Value(ShotDraft.normalizeShotType(draft.shotType)),
            prompt: Value(draft.prompt),
            status: Value(nextStatus),
            // M19 T21.12 段级摄影参数：空字段也显式写回，重导可清掉旧值。
            composition: Value(draft.composition),
            lens: Value(draft.lens),
            cameraPosition: Value(draft.cameraPosition),
            eyeline: Value(draft.eyeline),
            focus: Value(draft.focus),
            stability: Value(draft.stability),
            blocking: Value(draft.blocking),
            dialogueStartRatio: Value(draft.dialogueStartRatio),
            dialogueEndRatio: Value(draft.dialogueEndRatio),
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

      for (final draft in drafts) {
        await _saveShotSnapshot(
          shots.firstWhere((s) => s.globalSeq == draft.globalSeq).id,
          'direction',
          '重新导演：提示词与帧已更新',
        );
      }
      return ShotDirectionSummary(
        shotCount: drafts.length,
        frameCount: frameCount,
        refCount: refCount,
      );
    });
  }

  // ---- 分镜图生成（T6.4） ----

  /// 生成分镜图（0 参考文生图 / ≥1 参考图生图），成功后写入产物路径。
  Future<Shot> generate({
    required int shotId,
    required ActiveImage image,
    GenerationCancelToken? cancelToken,
  }) async {
    final shot = await shotDao.find(shotId);
    if (shot == null) throw StateError('镜头不存在：$shotId');
    if (shot.prompt.isEmpty) throw StateError('镜头尚未生成分镜提示词');

    // 台账在调用前写入：提示词、参数、参考顺序与调用前状态，之后的编辑不回写。
    final prompt = await _resolvePrompt(
      shot,
      await assetRefDao.listByShot(shotId),
    );
    final attemptId = await _recordAttempt(
      subjectType: AttemptSubjects.shotImage,
      subjectId: shotId,
      subjectLabel: shot.globalSeq,
      prompt: prompt,
      params: jsonEncode({
        'provider': image.provider.label,
        'model': image.modelId,
        'protocol': image.protocol,
      }),
      refs: await _refRowsOf(shot),
      before: {'status': shot.status, 'outputPath': shot.outputPath},
      bookId: (await scriptDao.find(shot.scriptId))?.bookId,
    );

    await shotDao.updateById(
      shotId,
      ShotsCompanion(status: const Value(ShotStatuses.generating)),
    );

    try {
      cancelToken?.throwIfCancelled();
      final bytes = await _generateBytes(shot, image, cancelToken: cancelToken);
      cancelToken?.throwIfCancelled();
      final path = await fileStore.save(shotId, bytes);
      cancelToken?.throwIfCancelled();
      await shotDao.updateById(
        shotId,
        ShotsCompanion(
          outputPath: Value(path),
          status: const Value(ShotStatuses.reviewing),
          // 刚按当前提示词出过图，失效标记清除（M19 T21.14）。
          isStale: const Value(0),
        ),
      );
      await _saveShotSnapshot(shotId, 'image', '分镜图已生成');
      await _finishAttempt(
        id: attemptId,
        status: AttemptStatuses.succeeded,
        resultPath: path,
      );
      return (await shotDao.find(shotId))!;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        cancelToken?.cancel();
      }
      await _finishAttempt(
        id: attemptId,
        status: AttemptStatuses.cancelled,
        error: '已取消',
      );
      // 失败回滚到「待分镜图」，保留提示词便于重试。
      await shotDao.updateById(
        shotId,
        ShotsCompanion(status: const Value(ShotStatuses.awaitingImage)),
      );
      rethrow;
    } catch (e) {
      await _finishAttempt(
        id: attemptId,
        status: AttemptStatuses.failed,
        error: '$e',
      );
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
    GenerationCancelToken? cancelToken,
  }) async {
    var success = 0;
    var failed = 0;
    var pending = 0;
    var cancelled = false;
    final total = shotIds.length;

    for (var i = 0; i < shotIds.length; i++) {
      if (cancelToken?.cancelled ?? false) {
        cancelled = true;
        pending = total - i;
        break;
      }
      onProgress?.call(i, total, shotIds[i]);
      try {
        await generate(
          shotId: shotIds[i],
          image: image,
          cancelToken: cancelToken,
        );
        cancelToken?.throwIfCancelled();
        success++;
      } on StateError catch (_) {
        if (cancelToken?.cancelled ?? false) {
          cancelled = true;
          pending = total - i - 1;
          break;
        }
        failed++;
      } catch (_) {
        failed++;
      }
    }
    if (!cancelled) {
      onProgress?.call(total, total, -1);
    }

    return ShotBatchResult(
      success: success,
      failed: failed,
      cancelled: cancelled,
      pending: pending,
    );
  }

  /// 组装参考图并按需替换 {{ref N}}，调用适配器生成图片字节。
  Future<Uint8List> _generateBytes(
    Shot shot,
    ActiveImage image, {
    GenerationCancelToken? cancelToken,
  }) async {
    final refs = await assetRefDao.listByShot(shot.id);
    final prompt = await _resolvePrompt(shot, refs);

    if (refs.isEmpty) {
      final result = await imageAdapter.textToImage(
        baseUrl: image.baseUrl,
        apiKey: image.apiKey,
        model: image.modelId,
        prompt: prompt,
        size: image.imageSize,
        protocol: image.protocol,
        cancelToken: cancelToken?.dioToken,
      );
      cancelToken?.throwIfCancelled();
      return _bytesOf(result);
    }

    // 参考图仅取已采用或已生成图（待验收）的资产；无图资产跳过。
    final paths = <String>[];
    for (final ref in refs) {
      cancelToken?.throwIfCancelled();
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
        size: image.imageSize,
        protocol: image.protocol,
        cancelToken: cancelToken?.dioToken,
      );
      cancelToken?.throwIfCancelled();
      return _bytesOf(result);
    }

    if (paths.length == 1) {
      final result = await imageAdapter.imageToImage(
        baseUrl: image.baseUrl,
        apiKey: image.apiKey,
        model: image.modelId,
        prompt: prompt,
        size: image.imageSize,
        referencePath: paths.single,
        protocol: image.protocol,
        cancelToken: cancelToken?.dioToken,
      );
      cancelToken?.throwIfCancelled();
      return _bytesOf(result);
    }

    final result = await imageAdapter.imageToImageMulti(
      baseUrl: image.baseUrl,
      apiKey: image.apiKey,
      model: image.modelId,
      prompt: prompt,
      size: image.imageSize,
      referencePaths: paths,
      protocol: image.protocol,
      cancelToken: cancelToken?.dioToken,
    );
    cancelToken?.throwIfCancelled();
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
    throw ImageGenerationException('供应商未返回图片数据');
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
      final sizeGap = (_shotSizeRank(a.shotType) - _shotSizeRank(b.shotType))
          .abs();
      final angleA = await _angleDegreesOf(a.id);
      final angleB = await _angleDegreesOf(b.id);
      final angleGap = (angleA - angleB).abs();

      if (subjectSame && sizeGap < 2 && angleGap < 90) {
        issues.add(
          ShotTransitionIssue(
            fromSeq: a.globalSeq,
            toSeq: b.globalSeq,
            reason: 'no_contrast',
            message:
                '${a.globalSeq} 与 ${b.globalSeq} 主体相同、'
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

  // ---- 时长预算校验（T18.4 / A2.3 / A3） ----

  /// 某剧本的时长与容量校验结果（M16）。
  ///
  /// 与 [listTransitionIssues] 分工：那边管画面区分度，这里管时长与容量。
  /// 都是纯校验、只提示不改数据。
  Future<List<SegmentBudgetIssue>> listBudgetIssues(
    int scriptId, {
    ProviderModel? videoModel,
  }) async {
    final script = await scriptDao.find(scriptId);
    if (script == null) return const [];
    final segments = await shotDao.listByScript(scriptId);
    final beats = await beatDao.listByScript(scriptId);
    return SegmentBudget(
      script: script,
      segments: segments,
      beats: beats,
      videoModel: videoModel,
    ).validate();
  }

  /// 校验结果里需要用户明确确认才能继续的 error 级条目。
  List<SegmentBudgetIssue> errorIssuesOf(List<SegmentBudgetIssue> issues) {
    return [
      for (final i in issues)
        if (i.isError) i,
    ];
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
    GenerationCancelToken? cancelToken,
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
    // 画风随剧本走：未设置时用统一默认值，避免跨段视觉漂移。
    final frames = await shotFrameDao.listByShot(shotId);
    final script = await scriptDao.find(shot.scriptId);
    final prompt = const VideoPromptBuilder().build(
      shot: shot,
      frames: frames,
      refs: refs,
      assetById: {
        for (final a in await assetDao.listByScript(shot.scriptId)) a.id: a,
      },
      artStyle: effectiveArtStyle(script?.artStyle),
      durationSec: params.durationSec,
    );

    // 台账在提交前写入：视频提示词与完整参数，供事后查证。
    final attemptId = await _recordAttempt(
      subjectType: AttemptSubjects.shotVideo,
      subjectId: shotId,
      subjectLabel: shot.globalSeq,
      prompt: prompt,
      params: jsonEncode(actualParams.encode()),
      refs: await _refRowsOf(shot),
      before: {'status': shot.status, 'outputPath': shot.outputPath},
      bookId: (await scriptDao.find(shot.scriptId))?.bookId,
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
        protocol: video.protocol,
        cancelToken: cancelToken?.dioToken,
      );
      final id = await videoTaskDao.insert(
        VideoTasksCompanion.insert(
          shotId: shotId,
          taskId: taskId,
          providerId: video.provider.id,
          status: const Value(VideoTaskStatuses.generating),
          paramsJson: Value(actualParams.encode()),
        ),
      );
      await _finishAttempt(id: attemptId, status: AttemptStatuses.succeeded);
      return (await videoTaskDao.find(id))!;
    } catch (e) {
      await _finishAttempt(
        id: attemptId,
        status: AttemptStatuses.failed,
        error: '$e',
      );
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
  /// 去重锁下沉到本方法：同一任务的并发轮询共享同一个 Future，任务中心与镜头
  /// 详情页同时触发时不会重复下载覆盖产物。
  /// 单次请求超时见 [pollTimeout]，整个任务（含下载）上限见 [pollAllTimeout]。
  /// 进行中的视频轮询取消令牌：按 taskId 索引，[cancelVideoTask] 用它中断在途请求。
  final Map<int, GenerationCancelToken> _videoCancelTokens = {};

  Future<VideoTask> pollVideoTask(int videoTaskId) {
    final token = GenerationCancelToken();
    _videoCancelTokens[videoTaskId] = token;
    final existing = _pollingTasks[videoTaskId];
    if (existing != null) return existing;
    final future = _pollVideoTaskOnce(videoTaskId, cancelToken: token)
        .timeout(pollAllTimeout)
        .whenComplete(() {
          _pollingTasks.remove(videoTaskId);
          _videoCancelTokens.remove(videoTaskId);
          token.cancel();
        });
    _pollingTasks[videoTaskId] = future;
    return future;
  }

  Future<VideoTask> _pollVideoTaskOnce(
    int videoTaskId, {
    GenerationCancelToken? cancelToken,
  }) async {
    final task = await videoTaskDao.find(videoTaskId);
    if (task == null) throw StateError('视频任务不存在：$videoTaskId');
    if (VideoTaskStatuses.terminal.contains(task.status)) {
      return task;
    }

    // 僵尸检测：超过存活上限仍无进展即判失败，不永久挂起在「生成中」。
    if (task.updatedAt.isBefore(DateTime.now().subtract(pollStaleAfter))) {
      return _markVideoFailed(
        task,
        '任务超时未返回结果（超过 ${pollStaleAfter.inHours} 小时）',
      );
    }

    // 恢复供应商配置与 Key。
    final provider = await _findProvider(task.providerId);
    if (provider == null) {
      return _markVideoFailed(task, '供应商配置已删除，无法恢复轮询');
    }
    // 供应商配置在任务提交后被改动（含换 Key）时置失败，避免用错凭据轮询。
    if (provider.updatedAt.isAfter(task.updatedAt)) {
      return _markVideoFailed(task, '供应商配置已变更，请重新生成');
    }
    final apiKey = await readProviderKey?.call(task.providerId);
    if (apiKey == null || apiKey.isEmpty) {
      return _markVideoFailed(task, '供应商 API Key 不可用');
    }

    // 轮询需传 protocol + model（openai-videos 协议需要 model_name 参数）。
    final decodedParams = VideoGenParams.decode(task.paramsJson);
    final modelId = decodedParams.modelId;

    try {
      final snapshot = await videoAdapter
          .poll(
            baseUrl: provider.baseUrl,
            apiKey: apiKey,
            taskId: task.taskId,
            model: modelId,
            protocol: provider.protocol,
            cancelToken: cancelToken?.dioToken,
          )
          .timeout(pollTimeout);

      if (snapshot.isSuccess) {
        return await db.transaction(() async {
          // 取产物字节并落盘。
          final Uint8List bytes;
          if (snapshot.base64 != null) {
            bytes = base64Decode(snapshot.base64!);
          } else if (snapshot.url != null) {
            bytes = await videoAdapter
                .downloadUrl(snapshot.url!, cancelToken: cancelToken?.dioToken)
                .timeout(pollTimeout);
          } else {
            return _markVideoFailed(task, '供应商未返回视频数据');
          }
          final path = await videoFileStore.save(task.shotId, bytes);
          await videoTaskDao.updateById(
            task.id,
            VideoTasksCompanion(
              status: const Value(VideoTaskStatuses.succeeded),
              outputPath: Value(path),
              updatedAt: Value(DateTime.now()),
            ),
          );
          await shotDao.updateById(
            task.shotId,
            ShotsCompanion(
              outputPath: Value(path),
              status: const Value(ShotStatuses.videoDone),
              // 视频已按当前提示词出片，失效标记清除（M19 T21.14）。
              isStale: const Value(0),
            ),
          );
          return (await videoTaskDao.find(task.id))!;
        });
      }

      if (snapshot.isFailed) {
        return await _markVideoFailed(task, snapshot.error ?? '视频生成失败');
      }

      // 仍在生成中：刷新 updatedAt 作为存活证明。
      await videoTaskDao.updateById(
        task.id,
        VideoTasksCompanion(
          status: const Value(VideoTaskStatuses.generating),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await videoTaskDao.find(task.id))!;
    } on DioException catch (e) {
      // 供应商明确报错（非网络层）标记失败，其余网络异常保持生成中待重试。
      final isNetwork =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.cancel;
      if (isNetwork) return task;
      return await _markVideoFailed(task, '供应商返回错误：${_describeError(e)}');
    } on TimeoutException {
      // 单次请求超时：标记失败，避免下一周期反复卡住整轮轮询。
      return _markVideoFailed(task, '查询超时（${pollTimeout.inSeconds}s 无响应）');
    } catch (_) {
      // 网络异常不标记失败，保持生成中，下次轮询重试。
      return task;
    }
  }

  String _describeError(DioException e) {
    final raw = e.response?.data;
    final message = raw is Map ? (raw['error'] ?? raw['message']) : raw;
    final text = message?.toString() ?? e.message ?? e.type.name;
    return text.length > 300 ? text.substring(0, 300) : text;
  }

  /// 标记任务失败并回滚镜头状态到「分镜图已确认」。
  Future<VideoTask> _markVideoFailed(VideoTask task, String error) async {
    await videoTaskDao.updateById(
      task.id,
      VideoTasksCompanion(
        status: const Value(VideoTaskStatuses.failed),
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
    return submitVideo(shotId: task.shotId, video: video, params: params);
  }

  /// 取消进行中的视频任务（本地取消：停轮询 + 回滚镜头到分镜图已确认）。
  ///
  /// 供应商无取消端点，故仅置本地状态；已产生的远端任务结果不再拉取。
  /// 取消视频任务：仅本地停止追踪。
  ///
  /// 通用视频协议没有标准取消端点，远端任务可能仍在运行并继续计费，
  /// 因此把这一点写进 error 字段由 UI 展示，而不是假装远端已停。
  Future<VideoTask> cancelVideoTask(int videoTaskId) async {
    final task = await videoTaskDao.find(videoTaskId);
    if (task == null) throw StateError('视频任务不存在：$videoTaskId');
    if (!VideoTaskStatuses.inProgress.contains(task.status)) return task;
    // 中断在途轮询请求：此前只改库不改网络，Dio 请求会一直等到 5 分钟
    // receiveTimeout，用户点「取消」看不到任何响应。
    _videoCancelTokens.remove(videoTaskId)?.cancel();
    await videoTaskDao.updateById(
      task.id,
      VideoTasksCompanion(
        status: const Value(VideoTaskStatuses.cancelled),
        error: const Value('已取消：本地停止追踪，远端任务可能仍在运行'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await shotDao.updateById(
      task.shotId,
      ShotsCompanion(
        status: const Value(ShotStatuses.confirmed),
        outputType: const Value('image'),
      ),
    );
    return (await videoTaskDao.find(task.id))!;
  }

  /// 切换镜头采用的视频版本（媒体历史，改 outputPath 指向历史成功任务）。
  Future<void> selectVideoVersion({
    required int shotId,
    required String outputPath,
  }) async {
    if (!File(outputPath).existsSync()) throw StateError('视频文件不存在');
    await shotDao.updateById(
      shotId,
      ShotsCompanion(
        outputPath: Value(outputPath),
        outputType: const Value('video'),
        status: const Value(ShotStatuses.videoDone),
      ),
    );
  }

  /// 切换到分镜图历史版本（M17 T19.3）。
  ///
  /// 只改 `outputPath` 指针并补写一条快照，不重建对象、不重跑生成。
  /// `outputType` 保持 `image`：分镜图与视频共用 `outputPath` 列，靠它区分。
  Future<void> selectImageVersion({
    required int shotId,
    required String outputPath,
  }) async {
    final shot = await shotDao.find(shotId);
    if (shot == null) throw StateError('镜头不存在：$shotId');
    if (!File(outputPath).existsSync()) throw StateError('图片文件不存在');
    await shotDao.updateById(
      shotId,
      ShotsCompanion(
        outputPath: Value(outputPath),
        outputType: const Value('image'),
        status: const Value(ShotStatuses.confirmed),
      ),
    );
    await _saveShotSnapshot(shotId, 'image', '切换到历史版本');
  }

  /// 用本地文件替换分镜图（M17 T19.3）。先查长度再复制，避免超大文件载入内存。
  Future<void> replaceImage({
    required int shotId,
    required String sourcePath,
  }) async {
    final shot = await shotDao.find(shotId);
    if (shot == null) throw StateError('镜头不存在：$shotId');
    final source = File(sourcePath);
    if (!source.existsSync()) throw StateError('文件不存在：$sourcePath');
    if (source.lengthSync() > StorageLimits.maxReplaceableFileBytes) {
      throw StateError('文件超过 100MB 上限');
    }
    final path = await fileStore.saveFromPath(shotId, sourcePath);
    await shotDao.updateById(
      shotId,
      ShotsCompanion(
        outputPath: Value(path),
        outputType: const Value('image'),
        status: const Value(ShotStatuses.confirmed),
      ),
    );
    await _saveShotSnapshot(shotId, 'image', '手动替换分镜图');
  }

  /// 用本地文件替换镜头视频产物（≤100MB，导入私有目录）。
  Future<void> replaceVideo({
    required int shotId,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!source.existsSync()) throw StateError('文件不存在：$sourcePath');
    // 先校验大小再复制，避免超大文件先全量载入内存导致 OOM。
    if (source.lengthSync() > StorageLimits.maxReplaceableFileBytes) {
      throw StateError('文件超过 100MB 上限');
    }
    final path = await videoFileStore.saveFromPath(shotId, sourcePath);
    await shotDao.updateById(
      shotId,
      ShotsCompanion(
        outputPath: Value(path),
        outputType: const Value('video'),
        status: const Value(ShotStatuses.videoDone),
      ),
    );
    await _saveShotSnapshot(shotId, 'video', '手动替换视频：$path');
  }

  // ---- 验收与编辑 ----

  /// 用户编辑分镜提示词（保留 {{ref N}} 占位）。
  Future<void> updatePrompt({
    required int shotId,
    required String prompt,
  }) async {
    await shotDao.updateById(shotId, ShotsCompanion(prompt: Value(prompt)));
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
  const ShotBatchResult({
    required this.success,
    required this.failed,
    this.cancelled = false,
    this.pending = 0,
  });

  final int success;
  final int failed;
  final bool cancelled;
  final int pending;
}

/// 批量生成取消令牌。
///
/// UI 侧持有引用并置位；循环检查点与在途 Dio 请求都能感知取消，
/// 而不是只在 for 循环顶部判断一次。
class GenerationCancelToken {
  bool cancelled = false;
  final CancelToken _dio = CancelToken();
  bool _cancelled = false;

  /// 透传给 Dio 的取消令牌。
  CancelToken get dioToken => _dio;

  /// 置位取消。可重复调用，只有第一次会真正中断在途请求。
  void cancel([Object? reason]) {
    cancelled = true;
    if (_cancelled) return;
    _cancelled = true;
    _dio.cancel(reason ?? '用户取消');
  }

  /// 被取消时抛 [StateError]，由生成流程按普通失败处理并回滚状态。
  void throwIfCancelled() {
    if (cancelled) throw StateError('已取消');
  }
}
