import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../agent/active_llm.dart';
import '../../data/app_database.dart';
import '../../data/daos/beat_dao.dart';
import '../../data/daos/cascade_dao.dart';
import '../../data/daos/scene_dao.dart';
import '../../data/daos/script_dao.dart';
import '../../data/daos/shot_dao.dart';
import 'skeleton_agents.dart';
import 'skeleton_models.dart';

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
  });

  final AppDatabase db;
  final ScriptDao scriptDao;
  final SceneDao sceneDao;
  final BeatDao beatDao;
  final ShotDao shotDao;
  final CascadeDao cascadeDao;
  final SkeletonAgents agents;

  /// 默认单段时长上限（Seedance 2.0 单段 15s）。
  static const int defaultDurationCapMs = 15000;

  // ---- 提取（T3.2） ----

  String buildExtractionPrompt({
    required Script script,
    required List<Scene> scenes,
    int durationCapMs = defaultDurationCapMs,
  }) {
    final buf = StringBuffer();
    buf.writeln('【剧本标题】${script.title}');
    buf.writeln('【目标模型单段上限】${durationCapMs}ms');
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
    int durationCapMs = defaultDurationCapMs,
  }) async {
    final prompt = buildExtractionPrompt(
      script: script,
      scenes: scenes,
      durationCapMs: durationCapMs,
    );
    final result = await agents.extract(prompt: prompt, llm: llm);

    final sceneIdBySeq = <int, int>{for (final s in scenes) s.seq: s.id};

    // 删旧 + 插新整体包在事务内：中途失败整段回滚，不会留下空骨架。
    await db.transaction(() async {
      await cascadeDao.deleteSkeletonCascade(script.id);

      for (var i = 0; i < result.beats.length; i++) {
        final b = result.beats[i];
        final sceneId = sceneIdBySeq[b.sceneSeq];
        if (sceneId == null) {
          // 场景引用无法解析时跳过，避免外键失败；由校验/日志暴露。
          continue;
        }
        await beatDao.insert(
          BeatsCompanion.insert(
            sceneId: sceneId,
            seq: i + 1,
            type: b.type.isEmpty ? '动作' : b.type,
            who: Value(b.who),
            content: b.content,
            object: Value(b.object.isEmpty ? null : b.object),
            sourceRef: b.id.isEmpty ? 'E${i + 1}' : b.id,
            estDurationMs: Value(b.estDurationMs),
            tags: Value(jsonEncode(b.tags)),
          ),
        );
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
          ),
        );
      }
    });

    return SkeletonExtractionSummary(
      beatCount: result.beats.length,
      segmentCount: result.segments.length,
      globalDurationMs: result.globalDurationMs,
    );
  }

  // ---- 源剧情账本 E## 映射校验（T3.3） ----

  Future<List<SkeletonIssue>> listIssues(int scriptId) async {
    final beats = await beatDao.listByScript(scriptId);
    final shots = await shotDao.listByScript(scriptId);

    final knownRefs = <String>{for (final b in beats) b.sourceRef};
    final usedRefs = <String>{};
    final issues = <SkeletonIssue>[];

    for (final s in shots) {
      for (final ref in _decodeStringList(s.beatRefs)) {
        usedRefs.add(ref);
        if (!knownRefs.contains(ref)) {
          issues.add(
            SkeletonIssue(
              kind: 'unknown_ref',
              ref: ref,
              message: '${s.globalSeq} 引用了不存在的节拍 $ref',
            ),
          );
        }
      }
    }

    for (final b in beats) {
      if (!usedRefs.contains(b.sourceRef)) {
        issues.add(
          SkeletonIssue(
            kind: 'unmapped_beat',
            ref: b.sourceRef,
            message: '${b.sourceRef} 未映射到任何段',
          ),
        );
      }
    }
    return issues;
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
