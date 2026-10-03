// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_revision_dao.dart';

// ignore_for_file: type=lint
mixin _$ScriptRevisionDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $ScriptRevisionsTable get scriptRevisions => attachedDatabase.scriptRevisions;
  ScriptRevisionDaoManager get managers => ScriptRevisionDaoManager(this);
}

class ScriptRevisionDaoManager {
  final _$ScriptRevisionDaoMixin _db;
  ScriptRevisionDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$ScriptRevisionsTableTableManager get scriptRevisions =>
      $$ScriptRevisionsTableTableManager(
        _db.attachedDatabase,
        _db.scriptRevisions,
      );
}
