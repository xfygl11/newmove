import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../../agent/active_image.dart';
import '../../agent/active_llm.dart';
import '../../core/network/image_provider_adapter.dart';
import '../../core/storage/asset_file_store.dart';
import '../../data/app_database.dart';
import '../../data/daos/asset_dao.dart';
import '../../data/daos/beat_dao.dart';
import '../../data/daos/generation_attempt_dao.dart';
import '../../data/daos/revision_dao.dart';
import '../../data/daos/script_dao.dart';
import '../../data/daos/shot_dao.dart';
import '../script/script_models.dart';
import 'asset_agents.dart';
import 'asset_models.dart';

/// 资产图片的业务编排：清单提取落库、生成、验收、变体。
class AssetService {
  /// 变体提示词追加语句：提示词与确认框共用，保证展示即执行。
  static const String variantPromptSuffix = '保持与基础图同一角色身份，仅做指定变化。';

  AssetService({
    required this.assetDao,
    required this.beatDao,
    required this.shotDao,
    required this.scriptDao,
    required this.agents,
    required this.imageAdapter,
    required this.fileStore,
    this.revisionDao,
    this.attemptDao,
  });

  final AssetDao assetDao;
  final BeatDao beatDao;
  final ShotDao shotDao;
  final ScriptDao scriptDao;
  final AssetAgents agents;
  final ImageProviderAdapter imageAdapter;
  final AssetFileStore fileStore;

  /// 产物版本快照（M14 T16.6）。未注入时跳过。
  final RevisionDao? revisionDao;

  /// 生成尝试台账（M14 T16.5.4）。未注入时跳过。
  AttemptRecorder? get _recorder {
    final dao = attemptDao;
    return dao == null ? null : AttemptRecorder(dao);
  }

  /// 生成尝试台账（M14 T16.5.4）。未注入时跳过。
  final GenerationAttemptDao? attemptDao;

  // ---- 清单提取（T5.2） ----

  Future<String> buildSkeletonContext(int scriptId) async {
    final script = await scriptDao.find(scriptId);
    final beats = await beatDao.listByScript(scriptId);
    final shots = await shotDao.listByScript(scriptId);
    final buf = StringBuffer();
    // 风格必须出现在这里：资产 prompt 的「已确认风格」占位符全靠它填，
    // 缺失时 LLM 只能自由发挥，跨资产画风会飘。
    buf.writeln('【画面风格】${effectiveArtStyle(script?.artStyle)}');
    buf.writeln('【原子节拍】');
    buf.writeln(
      jsonEncode([
        for (final b in beats)
          {
            'seq': b.seq,
            'type': b.type,
            'who': b.who,
            'content': b.content,
            'object': b.object,
            'sourceRef': b.sourceRef,
          },
      ]),
    );
    buf.writeln('【分段与出镜状态】');
    buf.writeln(
      jsonEncode([
        for (final s in shots)
          {
            'globalSeq': s.globalSeq,
            'beatRefs': _decodeList(s.beatRefs),
            'assetStates': _decodeMap(s.assetStates),
          },
      ]),
    );
    buf.writeln('请按规则提取资产清单 JSON。');
    return buf.toString();
  }

  /// 提取资产清单并按 stableId 去重合并后落库（复用项跳过）。
  Future<AssetExtractionSummary> extractAndSave({
    required int scriptId,
    required ActiveLlm llm,
  }) async {
    final context = await buildSkeletonContext(scriptId);
    final rec = _recorder;
    final attemptId = rec == null
        ? null
        : await rec.start(
            subjectType: AttemptSubjects.assetExtract,
            subjectId: scriptId,
            subjectLabel: '资产提取',
            prompt: context,
            params: jsonEncode({
              'provider': llm.provider.label,
              'model': llm.modelId,
              'maxToken': llm.model.maxOutputTokens,
              'budgetTokens': llm.budgetTokens,
            }),
          );
    final result = await agents.extract(skeletonContext: context, llm: llm);

    try {
      // stableId -> 已存在/本轮新建的资产，用于复用与变体父解析。
      final byStableId = <String, Asset>{
        for (final a in await assetDao.listByScript(scriptId)) a.stableId: a,
      };

      var created = 0;
      var reused = 0;
      var variants = 0;

      // 第一遍：新建非变体资产。
      for (final d in result.drafts) {
        if (d.stableId.isEmpty || d.name.isEmpty) continue;
        if (d.variantOf != null) continue;
        if (byStableId.containsKey(d.stableId)) {
          reused++;
          continue;
        }
        final id = await assetDao.insert(
          AssetsCompanion.insert(
            scriptId: scriptId,
            type: _normalizeType(d.type),
            name: d.name,
            stableId: d.stableId,
            appearanceAnchor: Value(jsonEncode(d.appearanceAnchor)),
            boardLayout: Value(_normalizeBoardLayout(d.type, d.boardLayout)),
            prompt: Value(d.prompt),
            status: const Value(AssetStatuses.pending),
          ),
        );
        byStableId[d.stableId] = (await assetDao.find(id))!;
        created++;
      }

      // 第二遍：新建变体（父资产可能本轮刚建，也可能复用已存在）。
      for (final d in result.drafts) {
        if (d.variantOf == null) continue;
        if (d.stableId.isEmpty || d.name.isEmpty) continue;
        if (byStableId.containsKey(d.stableId)) {
          reused++;
          continue;
        }
        final parent = byStableId[d.variantOf];
        final id = await assetDao.insert(
          AssetsCompanion.insert(
            scriptId: scriptId,
            type: _normalizeType(d.type),
            name: d.name,
            stableId: d.stableId,
            variantOf: Value(parent?.id),
            appearanceAnchor: Value(jsonEncode(d.appearanceAnchor)),
            boardLayout: Value(_normalizeBoardLayout(d.type, d.boardLayout)),
            prompt: Value(d.prompt),
            status: const Value(AssetStatuses.pending),
          ),
        );
        byStableId[d.stableId] = (await assetDao.find(id))!;
        variants++;
      }

      await rec?.finish(
        id: attemptId,
        status: AttemptStatuses.succeeded,
        resultPath: '新建 $created / 变体 $variants / 复用 $reused',
      );
      return AssetExtractionSummary(
        created: created,
        reused: reused,
        variants: variants,
      );
    } catch (e) {
      await rec?.finish(
        id: attemptId,
        status: AttemptStatuses.failed,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ---- 产物版本快照与生成尝试台账（M14 T16.6 / T16.5.4） ----

  /// 资产产物快照：名称 / 类型 / 提示词 / 图片 / 变体父 / 外观锚点。
  String _snapshotOf(Asset asset) {
    return jsonEncode({
      'name': asset.name,
      'type': asset.type,
      'stableId': asset.stableId,
      'variantOf': asset.variantOf,
      'appearanceAnchor': asset.appearanceAnchor,
      'boardLayout': asset.boardLayout,
      'prompt': asset.prompt,
      'imagePath': asset.imagePath,
      'status': asset.status,
    });
  }

  Future<void> _saveSnapshot(
    Asset asset, {
    required String kind,
    required String summary,
  }) async {
    final dao = revisionDao;
    if (dao == null) return;
    try {
      await dao.saveAsset(
        assetId: asset.id,
        kind: kind,
        snapshot: _snapshotOf(asset),
        summary: summary,
      );
    } catch (_) {
      // 快照失败不得阻塞生成主流程。
    }
  }

  Future<int?> _recordAttempt({
    required String subjectType,
    required Asset asset,
    required ActiveImage image,
  }) async {
    final dao = attemptDao;
    if (dao == null) return null;
    try {
      return await dao.insert(
        GenerationAttemptsCompanion.insert(
          subjectType: subjectType,
          subjectId: Value(asset.id),
          subjectLabel: Value('${asset.type}「${asset.name}」'),
          prompt: asset.prompt,
          params: Value(
            jsonEncode({
              'provider': image.provider.label,
              'model': image.modelId,
              'protocol': image.protocol,
            }),
          ),
          before: Value(
            jsonEncode({'status': asset.status, 'imagePath': asset.imagePath}),
          ),
          attemptNo: Value(await dao.nextAttemptNo(subjectType, asset.id)),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _finishAttempt({
    int? id,
    required String status,
    String? resultPath,
    String? error,
  }) async {
    final dao = attemptDao;
    if (dao == null || id == null) return;
    try {
      await dao.finishAttempt(
        id: id,
        status: status,
        resultPath: resultPath,
        errorMessage: error,
      );
    } catch (_) {
      // 台账回写失败不影响主流程。
    }
  }

  // ---- 生成 / 验收（T5.4 / T5.5） ----

  Future<Asset> generate({
    required int assetId,
    required ActiveImage image,
  }) async {
    final asset = await assetDao.find(assetId);
    if (asset == null) throw StateError('资产不存在：$assetId');

    // 台账在调用前写入，之后的编辑不回写这一行。
    final attemptId = await _recordAttempt(
      subjectType: AttemptSubjects.assetImage,
      asset: asset,
      image: image,
    );

    await assetDao.updateById(
      assetId,
      AssetsCompanion(status: const Value(AssetStatuses.generating)),
    );

    try {
      final bytes = await _generateBytes(asset, image);
      final path = await fileStore.save(assetId, bytes);

      await assetDao.updateById(
        assetId,
        AssetsCompanion(
          imagePath: Value(path),
          status: const Value(AssetStatuses.reviewing),
        ),
      );
      await _saveSnapshot(asset, kind: 'image', summary: '资产图已生成');
      await _finishAttempt(
        id: attemptId,
        status: AttemptStatuses.succeeded,
        resultPath: path,
      );
      return (await assetDao.find(assetId))!;
    } catch (e) {
      await _finishAttempt(
        id: attemptId,
        status: AttemptStatuses.failed,
        error: '$e',
      );
      await assetDao.updateById(
        assetId,
        AssetsCompanion(status: const Value(AssetStatuses.pending)),
      );
      rethrow;
    }
  }

  Future<void> adopt(int assetId) async {
    await assetDao.updateById(
      assetId,
      AssetsCompanion(status: const Value(AssetStatuses.accepted)),
    );
  }

  Future<void> discard(int assetId) async {
    await assetDao.updateById(
      assetId,
      AssetsCompanion(status: const Value(AssetStatuses.discarded)),
    );
  }

  Future<Asset> regenerate({required int assetId, required ActiveImage image}) {
    return generate(assetId: assetId, image: image);
  }

  /// 基于已采用基础图做图生图变体（T5.6）。
  Future<Asset> createVariant({
    required int assetId,
    required ActiveImage image,
  }) async {
    final base = await assetDao.find(assetId);
    if (base == null) throw StateError('基础资产不存在：$assetId');
    if (base.imagePath == null || base.imagePath!.isEmpty) {
      throw StateError('基础资产尚未生成图片');
    }

    final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final newId = await assetDao.insert(
      AssetsCompanion.insert(
        scriptId: base.scriptId,
        type: base.type,
        name: '${base.name}·变体',
        stableId: '${base.stableId}_v$suffix',
        variantOf: Value(base.id),
        appearanceAnchor: Value(base.appearanceAnchor),
        boardLayout: Value(base.boardLayout),
        prompt: Value('${base.prompt}\n$variantPromptSuffix'),
        status: const Value(AssetStatuses.pending),
      ),
    );

    return generate(assetId: newId, image: image);
  }

  // ---- 内部辅助 ----

  Future<Uint8List> _generateBytes(Asset asset, ActiveImage image) async {
    // 变体优先走图生图，保持身份一致。
    if (asset.variantOf != null) {
      final parent = await assetDao.find(asset.variantOf!);
      final reference = parent?.imagePath;
      if (reference != null && reference.isNotEmpty) {
        final result = await imageAdapter.imageToImage(
          baseUrl: image.baseUrl,
          apiKey: image.apiKey,
          model: image.modelId,
          prompt: asset.prompt,
          referencePath: reference,
          protocol: image.protocol,
        );
        return _resolveBytes(result);
      }
    }

    final result = await imageAdapter.textToImage(
      baseUrl: image.baseUrl,
      apiKey: image.apiKey,
      model: image.modelId,
      prompt: asset.prompt,
      size: image.imageSize,
      protocol: image.protocol,
    );
    return _resolveBytes(result);
  }

  Future<Uint8List> _resolveBytes(ImageGenerationResult result) async {
    final bytes = result.bytes;
    if (bytes != null && bytes.isNotEmpty) return bytes;
    final url = result.url;
    if (url != null && url.isNotEmpty) return imageAdapter.downloadUrl(url);
    throw ImageGenerationException('供应商未返回图片数据');
  }

  String _normalizeType(String type) {
    return AssetTypes.all.contains(type) ? type : AssetTypes.character;
  }

  String _normalizeBoardLayout(String type, String boardLayout) {
    if (boardLayout.isNotEmpty) return boardLayout;
    return switch (type) {
      AssetTypes.character => BoardLayouts.fourView,
      AssetTypes.scene => BoardLayouts.mainView,
      _ => BoardLayouts.grid2x2,
    };
  }

  dynamic _decodeList(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return const [];
    }
  }

  dynamic _decodeMap(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return const {};
    }
  }
}

/// 一次资产清单提取的落库结果摘要。
class AssetExtractionSummary {
  const AssetExtractionSummary({
    required this.created,
    required this.reused,
    required this.variants,
  });

  final int created;
  final int reused;
  final int variants;
}
