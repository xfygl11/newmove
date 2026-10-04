import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'asset_ref_dao.g.dart';

/// 镜头-资产引用（参考图绑定）数据访问对象。
@DriftAccessor(tables: [AssetRefs])
class AssetRefDao extends DatabaseAccessor<AppDatabase>
    with _$AssetRefDaoMixin {
  AssetRefDao(super.db);

  Future<List<AssetRef>> listByShot(int shotId) {
    return (select(assetRefs)
          ..where((t) => t.shotId.equals(shotId))
          ..orderBy([(t) => OrderingTerm.asc(t.order)]))
        .get();
  }

  Stream<List<AssetRef>> watchByShot(int shotId) {
    return (select(assetRefs)
          ..where((t) => t.shotId.equals(shotId))
          ..orderBy([(t) => OrderingTerm.asc(t.order)]))
        .watch();
  }

  Future<List<AssetRef>> listByAsset(int assetId) {
    return (select(assetRefs)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([(t) => OrderingTerm.asc(t.order)]))
        .get();
  }

  Future<int> insert(AssetRefsCompanion entry) {
    return into(assetRefs).insert(entry);
  }

  Future<int> deleteById(int id) {
    return (delete(assetRefs)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByShot(int shotId) {
    return (delete(assetRefs)..where((t) => t.shotId.equals(shotId))).go();
  }

  Future<int> deleteByAsset(int assetId) {
    return (delete(assetRefs)..where((t) => t.assetId.equals(assetId))).go();
  }

  /// 跨镜头查询：某资产被哪些镜头引用（任务中心/资产影响面用）。
  Stream<List<AssetRef>> watchByAsset(int assetId) {
    return (select(assetRefs)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([(t) => OrderingTerm.asc(t.order)]))
        .watch();
  }
}
