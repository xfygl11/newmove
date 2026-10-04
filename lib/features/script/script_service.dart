import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../agent/active_llm.dart';
import '../../core/json_values.dart';
import '../../data/app_database.dart';
import '../../data/daos/cascade_dao.dart';
import '../../data/daos/novel_dao.dart';
import '../../data/daos/scene_dao.dart';
import '../../data/daos/script_dao.dart';
import '../../data/daos/script_revision_dao.dart';
import '../../data/daos/truth_file_dao.dart';
import '../novel/truth_file_kinds.dart';
import '../novel/truth_file_store.dart';
import 'script_agents.dart';
import 'script_models.dart';

/// 小说→剧本的业务编排：构建改编上下文、调用 Agent、落库与版本管理。
class ScriptService {
  ScriptService({
    required this.db,
    required this.scriptDao,
    required this.sceneDao,
    required this.revisionDao,
    required this.novelDao,
    required this.truthDao,
    required this.cascadeDao,
    required this.agents,
  });

  final AppDatabase db;
  final ScriptDao scriptDao;
  final SceneDao sceneDao;
  final ScriptRevisionDao revisionDao;
  final NovelDao novelDao;
  final TruthFileDao truthDao;
  final CascadeDao cascadeDao;
  final ScriptAgents agents;

  // ---- 改编（T2.1/T2.2） ----

  Future<String> buildAdaptationPrompt({
    required int bookId,
    required List<String> sourceTexts,
    required String fidelityMode,
  }) async {
    final book = await novelDao.findBook(bookId);
    final texts = await TruthFileStore(
      dao: truthDao,
      bookId: bookId,
    ).readAllText();

    final buf = StringBuffer();
    buf.writeln('【作品命题】${book?.premise ?? ''}');
    buf.writeln('【世界观】${book?.world ?? ''}');
    buf.writeln('【风格指南】${book?.styleGuide ?? ''}');
    buf.writeln('【角色矩阵】${texts[TruthFileKind.characterMatrix] ?? '{}'}');
    buf.writeln('【世界事实】${texts[TruthFileKind.worldFacts] ?? '{}'}');
    buf.writeln('【未闭合伏笔】${texts[TruthFileKind.hooks] ?? '{}'}');
    buf.writeln('【资源状态】${texts[TruthFileKind.resources] ?? '{}'}');
    buf.writeln('【忠实度模式】$fidelityMode');
    buf.writeln('【改编原文】');
    for (final t in sourceTexts) {
      buf.writeln(t);
      buf.writeln('---');
    }
    buf.writeln('请按规则把以上原文改编为分场剧本 JSON。');
    return buf.toString();
  }

  /// 调用 LLM 改编并持久化；若 [existing] 非空则先保存旧版本再递增 version。
  Future<Script> adaptChapters({
    required int bookId,
    Script? existing,
    String? title,
    required List<String> sourceTexts,
    required String fidelityMode,
    required ActiveLlm llm,
  }) async {
    final prompt = await buildAdaptationPrompt(
      bookId: bookId,
      sourceTexts: sourceTexts,
      fidelityMode: fidelityMode,
    );
    final result = await agents.adapt(prompt: prompt, llm: llm);

    final book = await novelDao.findBook(bookId);
    final resolvedTitle = title?.isNotEmpty == true
        ? title!
        : '${book?.title ?? '改编剧本'}·剧本';

    if (existing == null) {
      final content = jsonEncode(result.toJson());
      return db.transaction(() async {
        final id = await scriptDao.insert(
          ScriptsCompanion.insert(
            bookId: bookId,
            title: resolvedTitle,
            version: Value(1),
            fidelityMode: Value(fidelityMode),
            content: Value(content),
          ),
        );
        await _insertScenes(id, result.scenes);
        return (await scriptDao.find(id))!;
      });
    }

    // 先保存旧版本快照、再删场次（含节拍），最后才更新父行：
    // 删除失败时正文保持旧版，不会出现「正文新版 + 场次旧版」的错位。
    final newContent = jsonEncode(result.toJson());
    await db.transaction(() async {
      await revisionDao.insert(
        ScriptRevisionsCompanion.insert(
          scriptId: existing.id,
          version: existing.version,
          content: Value(existing.content),
        ),
      );
      await cascadeDao.deleteScenesCascade(existing.id);
      await _insertScenes(existing.id, result.scenes);
      await scriptDao.updateRow(
        existing.copyWith(
          version: existing.version + 1,
          fidelityMode: fidelityMode,
          status: '草案',
          content: newContent,
        ),
      );
    });
    return (await scriptDao.find(existing.id))!;
  }

  // ---- 提案确认（T2.3） ----

  List<AdaptationProposal> listProposals(Script script) {
    final content = _parseContent(script.content);
    return [
      for (final p in jsonList(content['proposals']))
        AdaptationProposal.fromJson(jsonMap(p)),
    ];
  }

  /// 确认 / 拒绝某条改编提案，写回 script.content。
  Future<void> setProposalAccepted(
    Script script, {
    required String proposalId,
    required bool accepted,
  }) async {
    final content = _parseContent(script.content);
    final proposals = listProposals(script);
    content['proposals'] = [
      for (final p in proposals)
        (p.id == proposalId ? p.copyWith(accepted: accepted) : p).toJson(),
    ];
    await scriptDao.updateRow(script.copyWith(content: jsonEncode(content)));
  }

  // ---- 定稿（T2.5） ----

  Future<void> finalizeScript(int scriptId) async {
    final script = await scriptDao.find(scriptId);
    if (script != null) {
      await scriptDao.updateRow(script.copyWith(status: '定稿'));
    }
  }

  // ---- 场次编辑 ----

  Future<void> updateScene(int sceneId, ScenesCompanion data) async {
    await sceneDao.updateById(sceneId, data);
  }

  Future<List<ScriptRevision>> listVersions(int scriptId) {
    return revisionDao.listByScript(scriptId);
  }

  // ---- 内部辅助 ----

  /// 仅插入场次；删除旧场次由调用方在事务内走 [CascadeDao.deleteScenesCascade]。
  Future<void> _insertScenes(int scriptId, List<AdaptedScene> scenes) async {
    for (final s in scenes) {
      await sceneDao.insert(
        ScenesCompanion.insert(
          scriptId: scriptId,
          seq: s.seq,
          location: s.location,
          time: s.time,
          characters: Value(jsonEncode(s.characters)),
          summary: Value(s.summary.isEmpty ? null : s.summary),
          action: Value(s.action),
          startState: Value(s.startState.isEmpty ? null : s.startState),
          endState: Value(s.endState.isEmpty ? null : s.endState),
          transition: Value(s.transition.isEmpty ? null : s.transition),
          dialogue: Value(jsonEncode([for (final d in s.dialogue) d.toJson()])),
          sound: Value(jsonEncode({'music': s.music, 'sfx': s.sfx})),
        ),
      );
    }
  }

  Map<String, dynamic> _parseContent(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // 内容损坏时按空处理。
    }
    return <String, dynamic>{};
  }
}
