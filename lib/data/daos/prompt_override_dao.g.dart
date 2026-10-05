// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_override_dao.dart';

// ignore_for_file: type=lint
mixin _$PromptOverrideDaoMixin on DatabaseAccessor<AppDatabase> {
  $PromptOverridesTable get promptOverrides => attachedDatabase.promptOverrides;
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  PromptOverrideDaoManager get managers => PromptOverrideDaoManager(this);
}

class PromptOverrideDaoManager {
  final _$PromptOverrideDaoMixin _db;
  PromptOverrideDaoManager(this._db);
  $$PromptOverridesTableTableManager get promptOverrides =>
      $$PromptOverridesTableTableManager(
        _db.attachedDatabase,
        _db.promptOverrides,
      );
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
}
