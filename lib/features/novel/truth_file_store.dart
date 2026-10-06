import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../core/json_values.dart';
import '../../data/app_database.dart';
import '../../data/daos/character_relation_dao.dart';
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
/// TruthFile 并发写冲突：期望的 revision 与库中不一致，说明有另一处
/// （如 Settler 固化与用户手工编辑）在同一个读改写窗口内各写了一次，
/// 后写者若不校验就会整表覆盖并静默丢失前者修改。
class ConcurrentWriteConflict implements Exception {
  ConcurrentWriteConflict(this.kind, this.expected, this.actual);

  final String kind;
  final int expected;
  final int actual;

  @override
  String toString() =>
      'TruthFile 并发写冲突：$kind 期望 revision=$expected，库中已是 $actual';
}

/// 伏笔生命周期状态机（对齐 InkOS hook-arbiter 的防倒退约束）。
///
/// 允许方向：`open → progressing → deferred → resolved | superseded`。
/// `resolved` / `superseded` 是终态，不允许再变更；`progressing` 不允许回退到
/// `open`，`deferred` 不允许回退到 `open` / `progressing`。
class HookStates {
  HookStates._();

  static const open = 'open';
  static const progressing = 'progressing';
  static const deferred = 'deferred';
  static const resolved = 'resolved';
  static const superseded = 'superseded';

  static const Map<String, Set<String>> transitions = {
    open: {progressing, deferred, resolved, superseded},
    progressing: {deferred, resolved, superseded},
    deferred: {resolved, superseded},
    resolved: <String>{},
    superseded: <String>{},
  };

  /// 展示用标签，未知状态原样返回。
  static String label(String? status) =>
      {
        open: '未闭合',
        progressing: '推进中',
        deferred: '搁置',
        resolved: '已回收',
        superseded: '已废弃',
      }[status] ??
      (status ?? '未闭合');

  /// [to] 是否为合法目标状态。空串与未知值一律拒绝。
  static bool isValid(String to) => transitions.containsKey(to);

  /// [from] → [to] 是否允许。[from] 为 null 表示新建条目，任何合法目标状态都允许。
  static bool allows(String? from, String to) {
    if (!isValid(to)) return false;
    if (from == null) return true;
    final fromKey = transitions.containsKey(from) ? from : open;
    return transitions[fromKey]!.contains(to);
  }
}

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

  /// 读取原始行，含 revision，供需要乐观锁的读改写路径使用。
  Future<TruthFile?> readRow(String kind) => dao.findByKind(bookId, kind);

  Future<void> write(
    String kind,
    Map<String, dynamic> content, {
    int? expectedRevision,
  }) async {
    final existing = await dao.findByKind(bookId, kind);
    if (existing != null &&
        expectedRevision != null &&
        existing.revision != expectedRevision) {
      throw ConcurrentWriteConflict(kind, expectedRevision, existing.revision);
    }
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
  ///
  /// 整体包在事务里：中途抛错（非法状态转移、并发写冲突、内容损坏）必须整段
  /// 回滚。否则前面几类已提交、后面几类没写，用户看到的是半套固化结果——
  /// 下一轮写作会基于残缺的真相继续跑，且没有任何痕迹。
  Future<void> applyDelta(SettleDelta delta, int chapterNumber) {
    return dao.attachedDatabase.transaction(() async {
      await _applyFacts(delta, chapterNumber);
      await _applyCharacters(delta);
      await _applyRelations(delta, chapterNumber);
      await _applyResources(delta);
      await _applyHooks(delta);
      await _applySummary(delta);
      if (delta.authorIntent.trim().isNotEmpty) {
        await _writeTextLocked(TruthFileKind.authorIntent, delta.authorIntent);
      }
      if (delta.currentFocus.trim().isNotEmpty) {
        await _writeTextLocked(TruthFileKind.currentFocus, delta.currentFocus);
      }
    });
  }

  /// 覆盖写入单字段文本，带乐观锁。
  Future<void> _writeTextLocked(String kind, String text) async {
    final row = await readRow(kind);
    await write(kind, {'text': text}, expectedRevision: row?.revision);
  }

  Future<void> _applyFacts(SettleDelta delta, int chapterNumber) async {
    final row = await readRow(TruthFileKind.worldFacts);
    final current = _contentOf(row);
    final facts = [for (final f in jsonList(current['facts'])) jsonMap(f)];

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

    await write(TruthFileKind.worldFacts, {
      'facts': facts,
    }, expectedRevision: row?.revision);
  }

  Future<void> _applyCharacters(SettleDelta delta) async {
    if (delta.characters.isEmpty) return;
    final row = await readRow(TruthFileKind.characterMatrix);
    final current = _contentOf(row);
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

    await write(TruthFileKind.characterMatrix, {
      'characters': list,
    }, expectedRevision: row?.revision);
  }

  /// 追加角色关系历史（M24 T25.3）。
  ///
  /// character_matrix 里的 `relations` 是自由文本快照，按字段覆盖后反转就无从
  /// 追溯；这里把每次确立的关系追加成独立行，同一 (source, target) 只留最新一行
  /// 为 isCurrent = 1。仍在 applyDelta 的事务里，任一条写入失败整段回滚。
  Future<void> _applyRelations(SettleDelta delta, int chapterNumber) async {
    if (delta.relationOps.isEmpty) return;
    final relations = CharacterRelationDao(dao.attachedDatabase);
    for (final op in delta.relationOps) {
      final source = jsonString(op['source']).trim();
      final target = jsonString(op['target']).trim();
      // 缺起点的关系落不成边，跳过而不是报错：Settler 漏字段不该让整轮固化回滚。
      if (source.isEmpty || target.isEmpty) continue;
      await relations.appendRelation(
        bookId: bookId,
        source: source,
        target: target,
        description: jsonString(op['description']),
        chapterSeq: chapterNumber,
      );
    }
  }

  Future<void> _applyResources(SettleDelta delta) async {
    if (delta.resources.isEmpty) return;
    final row = await readRow(TruthFileKind.resources);
    final current = _contentOf(row);
    final items = [for (final i in jsonList(current['items'])) jsonMap(i)];

    for (final res in delta.resources) {
      final idx = items.indexWhere((i) => i['name'] == res['name']);
      if (idx >= 0) {
        items[idx] = {...items[idx], ...res};
      } else {
        items.add(res);
      }
    }

    await write(TruthFileKind.resources, {
      'items': items,
    }, expectedRevision: row?.revision);
  }

  Future<void> _applyHooks(SettleDelta delta) async {
    if (delta.hookUpsert.isEmpty && delta.hookResolve.isEmpty) return;
    final row = await readRow(TruthFileKind.hooks);
    final current = _contentOf(row);
    final hooks = [for (final h in jsonList(current['hooks'])) jsonMap(h)];
    final rejected = <String>[];

    for (final up in delta.hookUpsert) {
      final idx = hooks.indexWhere((h) => h['id'] == up['id']);
      // 不直接 as String：LLM 可能回数字或布尔（{"status":1}），强转会抛
      // TypeError 并中断整轮固化。统一归一成字符串，非法值交给 allows 拒绝。
      final next = (up['status']?.toString() ?? '').trim();
      if (next.isEmpty) {
        // 新建且未给状态时默认 open；历史条目无状态视为 open。
        up['status'] = HookStates.open;
      }
      final target = up['status']?.toString() ?? '';
      final from = idx >= 0 ? hooks[idx]['status']?.toString() : null;
      if (!HookStates.allows(from, target)) {
        rejected.add('${up['id']} ${HookStates.label(from)} → $target');
        continue;
      }
      if (idx >= 0) {
        hooks[idx] = {...hooks[idx], ...up};
      } else {
        hooks.add(up);
      }
    }
    for (final id in delta.hookResolve) {
      final idx = hooks.indexWhere((h) => h['id'] == id);
      if (idx < 0) continue;
      final from = hooks[idx]['status']?.toString();
      if (!HookStates.allows(from, HookStates.resolved)) {
        rejected.add('$id ${HookStates.label(from)} → resolved');
        continue;
      }
      hooks[idx]['status'] = HookStates.resolved;
    }

    await write(TruthFileKind.hooks, {
      'hooks': hooks,
    }, expectedRevision: row?.revision);
    if (rejected.isNotEmpty) {
      // 终态不可回退：不阻塞整章固化，但把被拒转移记入内容，用户可在伏笔池查证。
      final updated = await readRow(TruthFileKind.hooks);
      await write(TruthFileKind.hooks, {
        ..._contentOf(updated),
        'rejectedTransitions': rejected,
      }, expectedRevision: updated?.revision);
    }
  }

  Future<void> _applySummary(SettleDelta delta) async {
    final summary = delta.chapterSummary;
    if (summary == null) return;
    final row = await readRow(TruthFileKind.chapterSummaries);
    final current = _contentOf(row);
    final rows = [for (final r in jsonList(current['rows'])) jsonMap(r)];

    final chapter = summary['chapter'];
    final idx = rows.indexWhere((r) => r['chapter'] == chapter);
    if (idx >= 0) {
      rows[idx] = {...rows[idx], ...summary};
    } else {
      rows.add(summary);
    }

    await write(TruthFileKind.chapterSummaries, {
      'rows': rows,
    }, expectedRevision: row?.revision);
  }

  /// 从原始行解出内容，null 或损坏时按空对象处理。
  Map<String, dynamic> _contentOf(TruthFile? row) {
    if (row == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(row.content);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // 内容损坏时按空处理。
    }
    return <String, dynamic>{};
  }
}
