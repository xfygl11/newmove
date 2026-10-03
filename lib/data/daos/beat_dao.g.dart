// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beat_dao.dart';

// ignore_for_file: type=lint
mixin _$BeatDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $ScenesTable get scenes => attachedDatabase.scenes;
  $BeatsTable get beats => attachedDatabase.beats;
  BeatDaoManager get managers => BeatDaoManager(this);
}

class BeatDaoManager {
  final _$BeatDaoMixin _db;
  BeatDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$ScenesTableTableManager get scenes =>
      $$ScenesTableTableManager(_db.attachedDatabase, _db.scenes);
  $$BeatsTableTableManager get beats =>
      $$BeatsTableTableManager(_db.attachedDatabase, _db.beats);
}
