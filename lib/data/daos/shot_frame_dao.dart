import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'shot_frame_dao.g.dart';

/// 镜头内画面数据访问对象（M5 分镜使用，M3 仅建立数据层）。
@DriftAccessor(tables: [ShotFrames])
class ShotFrameDao extends DatabaseAccessor<AppDatabase>
    with _$ShotFrameDaoMixin {
  ShotFrameDao(super.db);

  Future<List<ShotFrame>> listByShot(int shotId) {
    return (select(shotFrames)
          ..where((t) => t.shotId.equals(shotId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
  }

  Stream<List<ShotFrame>> watchByShot(int shotId) {
    return (select(shotFrames)
          ..where((t) => t.shotId.equals(shotId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .watch();
  }

  Future<ShotFrame?> find(int id) {
    return (select(
      shotFrames,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(ShotFramesCompanion entry) {
    return into(shotFrames).insert(entry);
  }

  Future<bool> updateRow(ShotFrame row) {
    return update(shotFrames).replace(row);
  }

  Future<int> updateById(int id, ShotFramesCompanion entry) {
    return (update(shotFrames)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> deleteById(int id) {
    return (delete(shotFrames)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByShot(int shotId) {
    return (delete(shotFrames)..where((t) => t.shotId.equals(shotId))).go();
  }
}
