// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_ref_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetRefDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $ShotsTable get shots => attachedDatabase.shots;
  $AssetsTable get assets => attachedDatabase.assets;
  $AssetRefsTable get assetRefs => attachedDatabase.assetRefs;
  AssetRefDaoManager get managers => AssetRefDaoManager(this);
}

class AssetRefDaoManager {
  final _$AssetRefDaoMixin _db;
  AssetRefDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$ShotsTableTableManager get shots =>
      $$ShotsTableTableManager(_db.attachedDatabase, _db.shots);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$AssetRefsTableTableManager get assetRefs =>
      $$AssetRefsTableTableManager(_db.attachedDatabase, _db.assetRefs);
}
