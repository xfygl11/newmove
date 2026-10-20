import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'import_log_dao.g.dart';

/// 导入日志 DAO（M35）。
///
/// 跟踪章节文本导入的每一步（读取/编码探测/标题提取/内容切片），
/// 失败后可定位到具体步骤。借鉴 AIComicBuilder 的 `import_logs`。
@DriftAccessor(tables: [ImportLogs])
class ImportLogDao extends DatabaseAccessor<AppDatabase>
    with _$ImportLogDaoMixin {
  ImportLogDao(super.db);

  /// 某项目的全部导入日志，最新在前。
  Future<List<ImportLog>> listByProject(int projectId, {int limit = 50}) {
    final query = select(importLogs)
      ..where((t) => t.projectId.equals(projectId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.get();
  }

  /// 全局导入（无项目上下文）的日志。
  Future<List<ImportLog>> listGlobal({int limit = 50}) {
    final query = select(importLogs)
      ..where((t) => t.projectId.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.get();
  }

  /// 新建导入日志。
  Future<int> insertLog({
    required String step,
    required String status,
    String message = '',
    String metadata = '{}',
    int? projectId,
  }) {
    return into(importLogs).insert(
      ImportLogsCompanion.insert(
        step: step,
        status: status,
        message: Value(message),
        metadata: Value(metadata),
        projectId: Value(projectId),
      ),
    );
  }

  /// 删除某项目的全部导入日志。
  Future<void> deleteByProject(int projectId) {
    return (delete(importLogs)..where((t) => t.projectId.equals(projectId)))
        .go();
  }
}
