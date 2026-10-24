// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_progress_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ReadingProgressesTable get readingProgresses =>
      attachedDatabase.readingProgresses;
  ReadingProgressDaoManager get managers => ReadingProgressDaoManager(this);
}

class ReadingProgressDaoManager {
  final _$ReadingProgressDaoMixin _db;
  ReadingProgressDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ReadingProgressesTableTableManager get readingProgresses =>
      $$ReadingProgressesTableTableManager(
        _db.attachedDatabase,
        _db.readingProgresses,
      );
}
