// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_ab_test_dao.dart';

// ignore_for_file: type=lint
mixin _$PromptAbTestDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $AssetsTable get assets => attachedDatabase.assets;
  $PromptAbTestsTable get promptAbTests => attachedDatabase.promptAbTests;
  PromptAbTestDaoManager get managers => PromptAbTestDaoManager(this);
}

class PromptAbTestDaoManager {
  final _$PromptAbTestDaoMixin _db;
  PromptAbTestDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$PromptAbTestsTableTableManager get promptAbTests =>
      $$PromptAbTestsTableTableManager(_db.attachedDatabase, _db.promptAbTests);
}
