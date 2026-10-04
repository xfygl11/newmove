import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'revision_dao.g.dart';

/// 镜头 / 资产产物版本快照数据访问对象（M14 T16.6）。
///
/// 每次重新导演、重新生成分镜图、重新生成资产图、替换视频都写一条快照，
/// 同时把该对象先前唯一的 `current` 降级为 `superseded`，由一个事务保证
/// 「同一对象至多一条 current」这一不变量。
@DriftAccessor(tables: [ShotRevisions, AssetRevisions])
class RevisionDao extends DatabaseAccessor<AppDatabase>
    with _$RevisionDaoMixin {
  RevisionDao(super.db);

  /// 保存镜头产物快照，把先前同 kind 的 `current` 降级。
  Future<void> saveShot({
    required int shotId,
    required String kind,
    required String snapshot,
    String summary = '',
  }) {
    return db.transaction(() async {
      await _demoteShot(shotId, kind);
      final revision =
          (await _allShotRevisions(shotId))
              .fold<int>(0, (m, r) => r.revision > m ? r.revision : m) +
          1;
      await into(shotRevisions).insert(
        ShotRevisionsCompanion.insert(
          shotId: shotId,
          revision: revision,
          kind: kind,
          state: const Value('current'),
          snapshot: Value(snapshot),
          summary: Value(summary),
        ),
      );
    });
  }

  /// 保存资产产物快照，把先前同 kind 的 `current` 降级。
  Future<void> saveAsset({
    required int assetId,
    required String kind,
    required String snapshot,
    String summary = '',
  }) {
    return db.transaction(() async {
      await _demoteAsset(assetId, kind);
      final revision =
          (await _allAssetRevisions(assetId))
              .fold<int>(0, (m, r) => r.revision > m ? r.revision : m) +
          1;
      await into(assetRevisions).insert(
        AssetRevisionsCompanion.insert(
          assetId: assetId,
          revision: revision,
          kind: kind,
          state: const Value('current'),
          snapshot: Value(snapshot),
          summary: Value(summary),
        ),
      );
    });
  }

  Future<void> _demoteShot(int shotId, String kind) {
    return (update(shotRevisions)..where(
          (t) =>
              t.shotId.equals(shotId) &
              t.kind.equals(kind) &
              t.state.equals('current'),
        ))
        .write(const ShotRevisionsCompanion(state: Value('superseded')));
  }

  Future<void> _demoteAsset(int assetId, String kind) {
    return (update(assetRevisions)..where(
          (t) =>
              t.assetId.equals(assetId) &
              t.kind.equals(kind) &
              t.state.equals('current'),
        ))
        .write(const AssetRevisionsCompanion(state: Value('superseded')));
  }

  Future<List<ShotRevision>> _allShotRevisions(int shotId) {
    return (select(shotRevisions)..where((t) => t.shotId.equals(shotId))).get();
  }

  Future<List<AssetRevision>> _allAssetRevisions(int assetId) {
    return (select(
      assetRevisions,
    )..where((t) => t.assetId.equals(assetId))).get();
  }

  Future<List<ShotRevision>> listShots(int shotId) {
    return (select(shotRevisions)
          ..where((t) => t.shotId.equals(shotId))
          ..orderBy([(t) => OrderingTerm.desc(t.revision)]))
        .get();
  }

  Future<List<AssetRevision>> listAssets(int assetId) {
    return (select(assetRevisions)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([(t) => OrderingTerm.desc(t.revision)]))
        .get();
  }

  /// 随镜头删除（级联删除路径调用，与 Shots 删除同事务）。
  Future<void> deleteShots(int shotId) {
    return (delete(shotRevisions)..where((t) => t.shotId.equals(shotId))).go();
  }

  Future<void> deleteAssets(int assetId) {
    return (delete(
      assetRevisions,
    )..where((t) => t.assetId.equals(assetId))).go();
  }
}
