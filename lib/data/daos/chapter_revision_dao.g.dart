// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter_revision_dao.dart';

// ignore_for_file: type=lint
mixin _$ChapterRevisionDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ChaptersTable get chapters => attachedDatabase.chapters;
  $ChapterRevisionsTable get chapterRevisions =>
      attachedDatabase.chapterRevisions;
  ChapterRevisionDaoManager get managers => ChapterRevisionDaoManager(this);
}

class ChapterRevisionDaoManager {
  final _$ChapterRevisionDaoMixin _db;
  ChapterRevisionDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db.attachedDatabase, _db.chapters);
  $$ChapterRevisionsTableTableManager get chapterRevisions =>
      $$ChapterRevisionsTableTableManager(
        _db.attachedDatabase,
        _db.chapterRevisions,
      );
}
