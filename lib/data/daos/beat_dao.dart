import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'beat_dao.g.dart';

/// 原子节拍数据访问对象。
@DriftAccessor(tables: [Beats, Scenes])
class BeatDao extends DatabaseAccessor<AppDatabase> with _$BeatDaoMixin {
  BeatDao(super.db);

  /// 按剧本列出节拍（场次序 + 节拍序升序）。
  Future<List<Beat>> listByScript(int scriptId) async {
    final query = select(beats).join([
      innerJoin(scenes, scenes.id.equalsExp(beats.sceneId)),
    ])
      ..where(scenes.scriptId.equals(scriptId))
      ..orderBy([OrderingTerm.asc(beats.seq)]);
    final rows = await query.get();
    return [for (final r in rows) r.readTable(beats)];
  }

  Stream<List<Beat>> watchByScript(int scriptId) {
    final query = select(beats).join([
      innerJoin(scenes, scenes.id.equalsExp(beats.sceneId)),
    ])
      ..where(scenes.scriptId.equals(scriptId))
      ..orderBy([OrderingTerm.asc(beats.seq)]);
    return query.watch().map(
          (rows) => [for (final r in rows) r.readTable(beats)],
        );
  }

  Future<List<Beat>> listByScene(int sceneId) {
    return (select(beats)
          ..where((t) => t.sceneId.equals(sceneId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
  }

  Future<Beat?> find(int id) {
    return (select(beats)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(BeatsCompanion entry) {
    return into(beats).insert(entry);
  }

  Future<bool> updateRow(Beat row) {
    return update(beats).replace(row);
  }

  Future<int> updateById(int id, BeatsCompanion entry) {
    return (update(beats)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> deleteById(int id) {
    return (delete(beats)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByScene(int sceneId) {
    return (delete(beats)..where((t) => t.sceneId.equals(sceneId))).go();
  }

  Future<int> deleteByScript(int scriptId) {
    final sceneIds = selectOnly(scenes)
      ..addColumns([scenes.id])
      ..where(scenes.scriptId.equals(scriptId));
    return (delete(beats)..where((t) => t.sceneId.isInQuery(sceneIds))).go();
  }
}
