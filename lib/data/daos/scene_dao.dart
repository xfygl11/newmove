import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'scene_dao.g.dart';

/// 场次数据访问对象。
@DriftAccessor(tables: [Scenes])
class SceneDao extends DatabaseAccessor<AppDatabase> with _$SceneDaoMixin {
  SceneDao(super.db);

  Future<List<Scene>> listByScript(int scriptId) {
    return (select(scenes)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
  }

  Stream<List<Scene>> watchByScript(int scriptId) {
    return (select(scenes)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .watch();
  }

  Future<Scene?> find(int id) {
    return (select(scenes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Scene?> watch(int id) {
    return (select(scenes)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insert(ScenesCompanion entry) {
    return into(scenes).insert(entry);
  }

  Future<bool> updateRow(Scene row) {
    return update(scenes).replace(row);
  }

  Future<int> updateById(int id, ScenesCompanion entry) {
    return (update(scenes)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> deleteById(int id) {
    return (delete(scenes)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByScript(int scriptId) {
    return (delete(scenes)..where((t) => t.scriptId.equals(scriptId))).go();
  }
}
