import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../core/json_values.dart';
import '../../data/app_database.dart';
import '../../data/daos/truth_file_dao.dart';
import 'novel_models.dart';
import 'truth_file_kinds.dart';

/// TruthFile 7 类状态的读写与 delta 应用。
///
/// JSON 结构约定：
/// - world_facts: `{ "facts": [...] }`
/// - character_matrix: `{ "characters": [...] }`
/// - resources: `{ "items": [...] }`
/// - hooks: `{ "hooks": [...] }`
/// - chapter_summaries: `{ "rows": [...] }`
/// - author_intent / current_focus: `{ "text": "..." }`
class TruthFileStore {
  TruthFileStore({required this.dao, required this.bookId});

  final TruthFileDao dao;
  final int bookId;

  Future<Map<String, dynamic>> read(String kind) async {
    final row = await dao.findByKind(bookId, kind);
    if (row == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(row.content);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // 内容损坏时按空处理。
    }
    return <String, dynamic>{};
  }

  Future<void> write(String kind, Map<String, dynamic> content) async {
    final existing = await dao.findByKind(bookId, kind);
    await dao.upsert(
      TruthFilesCompanion.insert(
        bookId: bookId,
        kind: kind,
        content: Value(jsonEncode(content)),
        revision: Value(existing == null ? 1 : existing.revision + 1),
      ),
    );
  }

  /// 读取全部 7 类状态，返回 kind -> JSON 文本，用于注入 LLM 上下文。
  Future<Map<String, String>> readAllText() async {
    final rows = await dao.listByBook(bookId);
    return {for (final r in rows) r.kind: r.content};
  }

  /// 把 SettleDelta 应用到 7 类状态。
  Future<void> applyDelta(SettleDelta delta, int chapterNumber) async {
    await _applyFacts(delta, chapterNumber);
    await _applyCharacters(delta);
    await _applyResources(delta);
    await _applyHooks(delta);
    await _applySummary(delta);
    if (delta.authorIntent.trim().isNotEmpty) {
      await write(TruthFileKind.authorIntent, {'text': delta.authorIntent});
    }
    if (delta.currentFocus.trim().isNotEmpty) {
      await write(TruthFileKind.currentFocus, {'text': delta.currentFocus});
    }
  }

  Future<void> _applyFacts(SettleDelta delta, int chapterNumber) async {
    final current = await read(TruthFileKind.worldFacts);
    final facts = [
      for (final f in (current['facts'] as List<dynamic>? ?? const []))
        (f as Map).cast<String, dynamic>(),
    ];

    // 失效：匹配未过期事实，设 validUntilChapter。
    for (final expire in delta.factExpire) {
      for (final f in facts) {
        if (f['validUntilChapter'] != null) continue;
        if (f['subject'] == expire['subject'] &&
            f['predicate'] == expire['predicate'] &&
            f['object'] == expire['object']) {
          f['validUntilChapter'] = chapterNumber;
        }
      }
    }

    // 新增：追加事实，补生效章节。
    for (final up in delta.factUpsert) {
      facts.add({
        'subject': up['subject'],
        'predicate': up['predicate'],
        'object': up['object'],
        'validFromChapter': up['validFromChapter'] ?? chapterNumber,
        'validUntilChapter': null,
        'sourceChapter': up['sourceChapter'] ?? chapterNumber,
      });
    }

    await write(TruthFileKind.worldFacts, {'facts': facts});
  }

  Future<void> _applyCharacters(SettleDelta delta) async {
    if (delta.characters.isEmpty) return;
    final current = await read(TruthFileKind.characterMatrix);
    final list = [for (final c in jsonList(current['characters'])) jsonMap(c)];

    for (final spec in delta.characters) {
      final idx = list.indexWhere((c) => c['name'] == spec.name);
      final json = spec.toJson();
      if (idx >= 0) {
        list[idx] = {...list[idx], ...json};
      } else {
        list.add(json);
      }
    }

    await write(TruthFileKind.characterMatrix, {'characters': list});
  }

  Future<void> _applyResources(SettleDelta delta) async {
    if (delta.resources.isEmpty) return;
    final current = await read(TruthFileKind.resources);
    final items = [for (final i in jsonList(current['items'])) jsonMap(i)];

    for (final res in delta.resources) {
      final idx = items.indexWhere((i) => i['name'] == res['name']);
      if (idx >= 0) {
        items[idx] = {...items[idx], ...res};
      } else {
        items.add(res);
      }
    }

    await write(TruthFileKind.resources, {'items': items});
  }

  Future<void> _applyHooks(SettleDelta delta) async {
    if (delta.hookUpsert.isEmpty && delta.hookResolve.isEmpty) return;
    final current = await read(TruthFileKind.hooks);
    final hooks = [for (final h in jsonList(current['hooks'])) jsonMap(h)];

    for (final up in delta.hookUpsert) {
      final idx = hooks.indexWhere((h) => h['id'] == up['id']);
      if (idx >= 0) {
        hooks[idx] = {...hooks[idx], ...up};
      } else {
        hooks.add(up);
      }
    }
    for (final id in delta.hookResolve) {
      final idx = hooks.indexWhere((h) => h['id'] == id);
      if (idx >= 0) hooks[idx]['status'] = 'resolved';
    }

    await write(TruthFileKind.hooks, {'hooks': hooks});
  }

  Future<void> _applySummary(SettleDelta delta) async {
    final summary = delta.chapterSummary;
    if (summary == null) return;
    final current = await read(TruthFileKind.chapterSummaries);
    final rows = [for (final r in jsonList(current['rows'])) jsonMap(r)];

    final chapter = summary['chapter'];
    final idx = rows.indexWhere((r) => r['chapter'] == chapter);
    if (idx >= 0) {
      rows[idx] = {...rows[idx], ...summary};
    } else {
      rows.add(summary);
    }

    await write(TruthFileKind.chapterSummaries, {'rows': rows});
  }
}
