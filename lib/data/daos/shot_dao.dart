import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'shot_dao.g.dart';

/// 镜头 / 片段数据访问对象。
@DriftAccessor(tables: [Shots])
class ShotDao extends DatabaseAccessor<AppDatabase> with _$ShotDaoMixin {
  ShotDao(super.db);

  Future<List<Shot>> listByScript(int scriptId) {
    return (select(shots)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([(t) => OrderingTerm.asc(t.globalSeq)]))
        .get();
  }

  Stream<List<Shot>> watchByScript(int scriptId) {
    return (select(shots)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([(t) => OrderingTerm.asc(t.globalSeq)]))
        .watch();
  }

  Future<Shot?> find(int id) {
    return (select(shots)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Shot?> watch(int id) {
    return (select(shots)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insert(ShotsCompanion entry) {
    return into(shots).insert(entry);
  }

  Future<bool> updateRow(Shot row) {
    return update(shots).replace(row);
  }

  Future<int> updateById(int id, ShotsCompanion entry) {
    return (update(shots)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> deleteById(int id) {
    return (delete(shots)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByScript(int scriptId) {
    return (delete(shots)..where((t) => t.scriptId.equals(scriptId))).go();
  }

  /// 跨剧本查询：进行中的镜头任务（任务中心用）。
  /// 状态取「生成中 / 待分镜图 / 待验收」。
  Stream<List<Shot>> watchActive() {
    return (select(shots)
          ..where(
            (t) =>
                t.status.isIn(['生成中', '待分镜图', '待验收']),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }
}
