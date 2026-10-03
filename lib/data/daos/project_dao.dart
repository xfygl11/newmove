import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'project_dao.g.dart';

/// 项目数据访问对象。
@DriftAccessor(tables: [Projects])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  /// 按更新时间倒序列出全部项目。
  Future<List<Project>> listAll() {
    return (select(projects)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// 监听项目列表变化（更新时间倒序）。
  Stream<List<Project>> watchAll() {
    return (select(projects)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<Project?> findById(int id) {
    return (select(projects)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertProject(ProjectsCompanion entry) {
    return into(projects).insert(entry);
  }

  /// 全量覆盖更新（row 来自 watch/select，revision 由调用方处理）。
  Future<bool> replaceProject(Project row) {
    return update(projects).replace(row);
  }

  Future<int> deleteProject(int id) {
    return (delete(projects)..where((t) => t.id.equals(id))).go();
  }
}
