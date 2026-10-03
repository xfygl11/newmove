// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_dao.dart';

// ignore_for_file: type=lint
mixin _$ScriptDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  ScriptDaoManager get managers => ScriptDaoManager(this);
}

class ScriptDaoManager {
  final _$ScriptDaoMixin _db;
  ScriptDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
}
