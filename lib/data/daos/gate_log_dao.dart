import 'package:drift/drift.dart';

import '../../core/app_log.dart';
import '../../core/gate_issue.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'gate_log_dao.g.dart';

/// 质量门运行日志（M24 T25.4）。
///
/// `GenerationAttempts` 台账记消耗算力的调用，本地校验不消耗算力，混进算力台账
/// 会稀释「哪次生成花了钱」的可读性。这里单独记账，报表页可以统计
/// 「哪条门最常响」与「哪些门从未命中」。
///
/// 只有 INSERT。命中才落行：通过的运行不记录，所以「从未命中」的列表同时包含
/// 「从没跑过」与「跑了但一直通过」——对提示词调优而言两者是同一条信息，
/// 都说明这条门当前没有给出任何信号。`ok` 列保留 0 / 1 两种取值，
/// 命中写 0，供后续需要记录通过项时扩展。
@DriftAccessor(tables: [GateLogs])
class GateLogDao extends DatabaseAccessor<AppDatabase>
    with _$GateLogDaoMixin {
  GateLogDao(super.db);

  /// 登记一次本地质量门校验：每道命中的门码写一行。
  ///
  /// 写入失败只留痕不阻塞——门是提示能力，留痕失败不该让用户看不到体检结果。
  Future<bool> recordValidation({
    required String subjectType,
    required String subjectLabel,
    required List<String> gates,
    required List<GateIssue> issues,
    int? projectId,
    String? subjectId,
  }) async {
    if (issues.isEmpty) return true;
    try {
      await attachedDatabase.transaction(() async {
        final byCode = <String, List<GateIssue>>{};
        for (final issue in issues) {
          byCode.putIfAbsent(issue.code, () => <GateIssue>[]).add(issue);
        }
        for (final entry in byCode.entries) {
          await into(gateLogs).insert(
            GateLogsCompanion.insert(
              subjectType: subjectType,
              subjectLabel: subjectLabel,
              gateId: entry.key,
              ok: const Value(0),
              detail: Value(_detail(gates, entry.value)),
              subjectId: Value(subjectId),
              projectId: Value(projectId),
            ),
          );
        }
      });
      return true;
    } catch (e, st) {
      appLog('gate_log_record', subjectLabel, error: e, stackTrace: st);
      return false;
    }
  }

  /// 全部日志，按时间倒序，报表页明细列表的数据源。
  Future<List<GateLog>> all({int? projectId}) async {
    final rows = await _rowsWhere(projectId).get();
    // createdAt 只有秒级精度，同秒内写入按主键倒序兜底，保证顺序稳定。
    rows.sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
    return rows;
  }

  /// 每道门码的命中次数，降序，报表页「最常响」榜单的数据源。
  Future<Map<String, int>> hitsByGate({int? projectId}) async {
    final rows = await _rowsWhere(projectId).get();
    final hits = <String, int>{};
    for (final row in rows) {
      if (row.ok == 0) {
        hits.update(row.gateId, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final ranked = hits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final entry in ranked) entry.key: entry.value};
  }

  /// 曾出现过记录的门码，报表页「从未命中」榜单用它与全量门码做差集。
  Future<Set<String>> seenGateIds({int? projectId}) async {
    final rows = await _rowsWhere(projectId).get();
    return {for (final row in rows) row.gateId};
  }

  /// 日志总条数，报表页显示空态用。
  Future<int> countRuns({int? projectId}) async {
    final rows = await _rowsWhere(projectId).get();
    return rows.length;
  }

  /// 按项目过滤的查询；projectId 为空时返回全量。
  Selectable<GateLog> _rowsWhere(int? projectId) {
    final query = select(gateLogs);
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    return query;
  }

  /// 项目删除时清理其质量门日志；projectId 为空的全局记录保留。
  Future<void> deleteByProject(int projectId) {
    return (delete(gateLogs)..where((t) => t.projectId.equals(projectId))).go();
  }

  /// 命中摘要：门族名、条数、首条 locator。
  static String _detail(List<String> gates, List<GateIssue> issues) {
    final locators = issues.map((issue) => issue.locator).toSet().join(' / ');
    return '${gates.join('、')} · ${issues.length} 条 · $locators';
  }
}
