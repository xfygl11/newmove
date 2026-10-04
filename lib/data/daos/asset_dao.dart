import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'asset_dao.g.dart';

/// 资产（角色 / 场景 / 道具）数据访问对象。
@DriftAccessor(tables: [Assets])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Future<List<Asset>> listByScript(int scriptId) {
    return (select(assets)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.type),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Stream<List<Asset>> watchByScript(int scriptId) {
    return (select(assets)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.type),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<List<Asset>> listByScriptAndType(int scriptId, String type) {
    return (select(assets)
          ..where((t) => t.scriptId.equals(scriptId) & t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<List<Asset>> listByStableId(int scriptId, String stableId) {
    return (select(assets)..where(
          (t) => t.scriptId.equals(scriptId) & t.stableId.equals(stableId),
        ))
        .get();
  }

  Future<Asset?> find(int id) {
    return (select(assets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Asset?> watch(int id) {
    return (select(assets)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insert(AssetsCompanion entry) {
    return into(assets).insert(entry);
  }

  Future<bool> updateRow(Asset row) {
    return update(assets).replace(row);
  }

  Future<int> updateById(int id, AssetsCompanion entry) {
    return (update(assets)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> deleteById(int id) {
    return (delete(assets)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByScript(int scriptId) {
    return (delete(assets)..where((t) => t.scriptId.equals(scriptId))).go();
  }

  /// 跨剧本查询：进行中的资产任务（任务中心用）。
  /// 状态取「生成中 / 待验收」。
  Stream<List<Asset>> watchActive() {
    return (select(assets)
          ..where((t) => t.status.isIn(['生成中', '待验收']))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }
}
