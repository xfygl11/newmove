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

  /// M38：按镜头 + 角色查询同槽位全部版本参考图。
  Future<List<AssetRef>> listByShotAndRole(int shotId, String role) {
    return (select(assetRefs)
          ..where((t) => t.shotId.equals(shotId) & t.role.equals(role))
          ..orderBy([(t) => OrderingTerm.asc(t.version)]))
        .get();
  }

  /// M38：按镜头查询当前生效的参考图（isActive=1 或 null 表示生效）。
  Future<List<AssetRef>> listActiveByShot(int shotId) {
    return (select(assetRefs)
          ..where((t) => t.shotId.equals(shotId) & (t.isActive.equals(1) | t.isActive.isNull()))
          ..orderBy([(t) => OrderingTerm.asc(t.order)]))
        .get();
  }

  /// M38：设置指定引用为生效版本，同槽位其他版本设为非生效。
  Future<void> setActive(int id) async {
    final ref = await (select(assetRefs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (ref == null) return;

    await db.transaction(() async {
      // 同槽位其他版本设为非生效。
      await (update(assetRefs)
            ..where((t) =>
                t.shotId.equals(ref.shotId) &
                t.role.equals(ref.role) &
                (t.isActive.equals(1) | t.isActive.isNull())))
          .write(const AssetRefsCompanion(isActive: Value(0)));
      // 当前版本设为生效。
      await (update(assetRefs)..where((t) => t.id.equals(id)))
          .write(const AssetRefsCompanion(isActive: Value(1)));
    });
  }

  /// M38：获取同槽位下一个版本号（取最大值 +1，无记录返回 1）。
  Future<int> nextVersion(int shotId, String role) async {
    final rows = await (select(assetRefs)
          ..where((t) => t.shotId.equals(shotId) & t.role.equals(role))
          ..orderBy([(t) => OrderingTerm.desc(t.version)])
          ..limit(1))
        .get();
    if (rows.isEmpty) return 1;
    return (rows.single.version ?? 0) + 1;
  }
}
