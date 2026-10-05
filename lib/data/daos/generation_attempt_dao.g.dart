// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_attempt_dao.dart';

// ignore_for_file: type=lint
mixin _$GenerationAttemptDaoMixin on DatabaseAccessor<AppDatabase> {
  $GenerationAttemptsTable get generationAttempts =>
      attachedDatabase.generationAttempts;
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  GenerationAttemptDaoManager get managers => GenerationAttemptDaoManager(this);
}

class GenerationAttemptDaoManager {
  final _$GenerationAttemptDaoMixin _db;
  GenerationAttemptDaoManager(this._db);
  $$GenerationAttemptsTableTableManager get generationAttempts =>
      $$GenerationAttemptsTableTableManager(
        _db.attachedDatabase,
        _db.generationAttempts,
      );
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
}
