// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shot_dao.dart';

// ignore_for_file: type=lint
mixin _$ShotDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $ShotsTable get shots => attachedDatabase.shots;
  ShotDaoManager get managers => ShotDaoManager(this);
}

class ShotDaoManager {
  final _$ShotDaoMixin _db;
  ShotDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$ShotsTableTableManager get shots =>
      $$ShotsTableTableManager(_db.attachedDatabase, _db.shots);
}
