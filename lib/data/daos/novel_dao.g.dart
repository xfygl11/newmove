// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_dao.dart';

// ignore_for_file: type=lint
mixin _$NovelDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ChaptersTable get chapters => attachedDatabase.chapters;
  NovelDaoManager get managers => NovelDaoManager(this);
}

class NovelDaoManager {
  final _$NovelDaoMixin _db;
  NovelDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db.attachedDatabase, _db.chapters);
}
