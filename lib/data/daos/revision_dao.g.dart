// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revision_dao.dart';

// ignore_for_file: type=lint
mixin _$RevisionDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $ShotsTable get shots => attachedDatabase.shots;
  $ShotRevisionsTable get shotRevisions => attachedDatabase.shotRevisions;
  $AssetsTable get assets => attachedDatabase.assets;
  $AssetRevisionsTable get assetRevisions => attachedDatabase.assetRevisions;
  RevisionDaoManager get managers => RevisionDaoManager(this);
}

class RevisionDaoManager {
  final _$RevisionDaoMixin _db;
  RevisionDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$ShotsTableTableManager get shots =>
      $$ShotsTableTableManager(_db.attachedDatabase, _db.shots);
  $$ShotRevisionsTableTableManager get shotRevisions =>
      $$ShotRevisionsTableTableManager(_db.attachedDatabase, _db.shotRevisions);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$AssetRevisionsTableTableManager get assetRevisions =>
      $$AssetRevisionsTableTableManager(
        _db.attachedDatabase,
        _db.assetRevisions,
      );
}
