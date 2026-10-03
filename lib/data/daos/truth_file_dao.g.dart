// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'truth_file_dao.dart';

// ignore_for_file: type=lint
mixin _$TruthFileDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $TruthFilesTable get truthFiles => attachedDatabase.truthFiles;
  TruthFileDaoManager get managers => TruthFileDaoManager(this);
}

class TruthFileDaoManager {
  final _$TruthFileDaoMixin _db;
  TruthFileDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$TruthFilesTableTableManager get truthFiles =>
      $$TruthFilesTableTableManager(_db.attachedDatabase, _db.truthFiles);
}
