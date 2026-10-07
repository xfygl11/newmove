import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../agent/active_llm.dart';
import '../../core/gate_issue.dart';
import '../../data/app_database.dart';
import '../../data/daos/beat_dao.dart';
import '../../data/daos/generation_attempt_dao.dart';
import '../../data/daos/cascade_dao.dart';
import '../../data/daos/scene_dao.dart';
import '../../data/daos/script_dao.dart';
import '../../data/daos/revision_dao.dart';
import '../../data/daos/shot_dao.dart';
import '../provider_config/provider_models.dart';
import '../shot/segment_budget.dart';
import 'skeleton_agents.dart';
import 'skeleton_gate.dart';

/// 剧本骨架的业务编排：构建导演上下文、调用 Agent、落库与完整性校验。
class SkeletonService {
  SkeletonService({
    required this.db,
    required this.scriptDao,
    required this.sceneDao,
    required this.beatDao,
    required this.shotDao,
    required this.cascadeDao,
    required this.agents,
    required this.revisionDao,
    required GenerationAttemptDao attemptDao,
  }) : _attempts = AttemptRecorder(attemptDao);

  final AppDatabase db;
  final ScriptDao scriptDao;
  final SceneDao sceneDao;
  final BeatDao beatDao;
  final ShotDao shotDao;
  final CascadeDao cascadeDao;

  /// 产物版本快照（M18：五 service 的 revisionDao 一律 required，编译期防线）。
  /// 骨架是结构数据，重提取删除 Shots 时快照因外键级联清除，暂无独立快照语义，
  /// 注入点为未来骨架快照机制预留。
  final RevisionDao revisionDao;

  /// 生成尝试台账（M18 T20.1 起必填，见 [AttemptRecorder]）。
  final AttemptRecorder _attempts;

  static String _paramsOf(ActiveLlm llm) => jsonEncode({
    'model': llm.modelId,
    'provider': llm.provider.label,
    'maxToken': llm.model.maxOutputTokens,
    'budgetTokens': llm.budgetTokens,
  });

  Future<int?> _start({
    required String subjectType,
    int? subjectId,
    required String subjectLabel,
    required String prompt,
    required String params,
    Map<String, dynamic> before = const {},
    int? bookId,
  }) {
    return _attempts.start(
      subjectType: subjectType,
      subjectId: subjectId,
      subjectLabel: subjectLabel,
      prompt: prompt,
      params: params,
      before: before,
      bookId: bookId,
    );
  }

  Future<void> _finish(int? id, String status, {String? error}) async {
    await _attempts.finish(id: id, status: status, error: error);
  }

  final SkeletonAgents agents;

  // ---- 提取（T3.2 / T18.3） ----

  /// 解析该剧本的分段预算：剧本集参数 + 当前视频模型能力。
  static SegmentBudget budgetFor(Script script, {ProviderModel? videoModel}) {
    return SegmentBudget(
      script: script,
      segments: const [],
      beats: const [],
      videoModel: videoModel,
    );
  }

  String buildExtractionPrompt({
    required Script script,
    required List<Scene> scenes,
    ProviderModel? videoModel,
  }) {
    final budget = budgetFor(script, videoModel: videoModel);
    final buf = StringBuffer();
    buf.writeln('【剧本标题】${script.title}');
    buf.writeln('【单段时长硬上限】${budget.maxSegmentMs}ms（不可超过）');
    buf.writeln('【合段预算】${budget.mergeBudgetMs}ms（已扣除 10% 呼吸余量）');
    if (script.targetDurationMs > 0) {
      buf.writeln(
        '【目标总时长】${script.targetDurationMs}ms'
        '（理论最少 ${budget.theoreticalMinSegments(script.targetDurationMs)} 段，'
        '只作下限参考）',
      );
    }
    buf.writeln('【单批最多段数】${budget.maxBatchSegments}');
    buf.writeln('【定稿剧本（分场 JSON）】');
    buf.writeln(
      jsonEncode({
        'scenes': [for (final s in scenes) _sceneToJson(s)],
      }),
    );
    buf.writeln('请按规则提取骨架 JSON。');
    return buf.toString();
  }

  /// 提取骨架并整体替换该剧本的旧节拍/分段。
  Future<SkeletonExtractionSummary> extract({
    required Script script,
    required List<Scene> scenes,
    required ActiveLlm llm,
    ProviderModel? videoModel,
  }) async {
    final prompt = buildExtractionPrompt(
      script: script,
      scenes: scenes,
      videoModel: videoModel,
    );
    // 删除前留痕：已出图 / 出视频分段的产物路径记入台账 before。重提取会
    // 级联清除 ShotRevisions 快照（外键随 Shots 删除），磁盘文件不删但 DB
    // 引用消失，台账是找回旧产物的唯一线索。
    final oldShots = await shotDao.listByScript(script.id);
    final attempt = await _start(
      subjectType: AttemptSubjects.skeletonExtract,
      subjectId: script.id,
      subjectLabel: script.title,
      prompt: prompt,
      params: _paramsOf(llm),
      before: {
        'shots': [
          for (final s in oldShots)
            if ((s.outputPath ?? '').isNotEmpty)
              {'globalSeq': s.globalSeq, 'outputPath': s.outputPath},
        ],
      },
      bookId: script.bookId,
    );
    try {
      final result = await agents.extract(prompt: prompt, llm: llm, bookId: script.bookId);
      final sceneIdBySeq = <int, int>{for (final s in scenes) s.seq: s.id};

      var insertedBeats = 0;
      // 删旧 + 插新整体包在事务内：中途失败整段回滚，不会留下空骨架。
      await db.transaction(() async {
        await cascadeDao.deleteSkeletonCascade(script.id);

        // 记录实际落库的节拍及其场次，用于给镜头补 sceneId 与真实节拍数。
        final sceneIdByBeatRef = <String, int>{};
        for (var i = 0; i < result.beats.length; i++) {
          final b = result.beats[i];
          final sceneId = sceneIdBySeq[b.sceneSeq];
          if (sceneId == null) {
            // 场景引用无法解析时跳过，避免外键失败；由校验/日志暴露。
            continue;
          }
          final sourceRef = b.id.isEmpty ? 'E${i + 1}' : b.id;
          await beatDao.insert(
            BeatsCompanion.insert(
              sceneId: sceneId,
              seq: i + 1,
              type: b.type.isEmpty ? '动作' : b.type,
              who: Value(b.who),
              content: b.content,
              object: Value(b.object.isEmpty ? null : b.object),
              sourceRef: sourceRef,
              estDurationMs: Value(b.estDurationMs),
              tags: Value(jsonEncode(b.tags)),
            ),
          );
          sceneIdByBeatRef[sourceRef] = sceneId;
          insertedBeats++;
        }

        for (final seg in result.segments) {
          await shotDao.insert(
            ShotsCompanion.insert(
              scriptId: script.id,
              globalSeq: seg.id,
              batch: Value(seg.batch),
              durationMs: Value(seg.durationMs),
              globalTimeRange: seg.globalTimeRange.isEmpty
                  ? '-'
                  : seg.globalTimeRange,
              beatRefs: Value(jsonEncode(seg.beatRefs)),
              assetStates: Value(jsonEncode(seg.assets.toJson())),
              // 场次用于导演上下文注入 location / time；取本段首个节拍所属场次。
              sceneId: Value(
                seg.beatRefs.isNotEmpty
                    ? sceneIdByBeatRef[seg.beatRefs.first]
                    : null,
              ),
            ),
          );
        }
      });

      await _finish(attempt, AttemptStatuses.succeeded);
      return SkeletonExtractionSummary(
        // 报告落库条数而非 LLM 原始条数：场景引用无法解析的节拍被静默跳过，
        // 报告全量会让用户以为库里有条数不符的数据。
        beatCount: insertedBeats,
        segmentCount: result.segments.length,
        globalDurationMs: result.globalDurationMs,
      );
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
  }

  // ---- 源剧情账本 E## 认领覆盖校验（T3.3 / M22 T23.2） ----

  /// 认领覆盖体检：编号唯一、每拍恰好认领一次、段内顺序不倒流、无未知引用。
  /// 纯校验，只提示不改数据。
  Future<List<GateIssue>> listCoverageIssues(int scriptId) async {
    final beats = await beatDao.listByScript(scriptId);
    final shots = await shotDao.listByScript(scriptId);
    return SkeletonGate.coverage(
      beats: SkeletonGate.beatOrder(beats),
      shots: shots,
    );
  }

  // ---- 内部辅助 ----

  Map<String, dynamic> _sceneToJson(Scene s) {
    return {
      'seq': s.seq,
      'location': s.location,
      'time': s.time,
      'characters': _decodeStringList(s.characters),
      'summary': s.summary ?? '',
      'action': s.action,
      'dialogue': _decode(s.dialogue),
      'sound': _decode(s.sound),
      'startState': s.startState ?? '',
      'endState': s.endState ?? '',
      'transition': s.transition ?? '',
    };
  }

  dynamic _decode(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  List<String> _decodeStringList(String value) {
    final decoded = _decode(value);
    if (decoded is List) return [for (final v in decoded) v.toString()];
    return const [];
  }
}

/// 一次骨架提取的落库结果摘要。
class SkeletonExtractionSummary {
  const SkeletonExtractionSummary({
    required this.beatCount,
    required this.segmentCount,
    required this.globalDurationMs,
  });

  final int beatCount;
  final int segmentCount;
  final int globalDurationMs;
}
