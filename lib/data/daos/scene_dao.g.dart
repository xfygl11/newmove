// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_dao.dart';

// ignore_for_file: type=lint
mixin _$SceneDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $ScenesTable get scenes => attachedDatabase.scenes;
  SceneDaoManager get managers => SceneDaoManager(this);
}

class SceneDaoManager {
  final _$SceneDaoMixin _db;
  SceneDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$ScenesTableTableManager get scenes =>
      $$ScenesTableTableManager(_db.attachedDatabase, _db.scenes);
}
