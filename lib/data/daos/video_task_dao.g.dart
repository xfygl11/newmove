// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_task_dao.dart';

// ignore_for_file: type=lint
mixin _$VideoTaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $ShotsTable get shots => attachedDatabase.shots;
  $VideoTasksTable get videoTasks => attachedDatabase.videoTasks;
  VideoTaskDaoManager get managers => VideoTaskDaoManager(this);
}

class VideoTaskDaoManager {
  final _$VideoTaskDaoMixin _db;
  VideoTaskDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$ShotsTableTableManager get shots =>
      $$ShotsTableTableManager(_db.attachedDatabase, _db.shots);
  $$VideoTasksTableTableManager get videoTasks =>
      $$VideoTasksTableTableManager(_db.attachedDatabase, _db.videoTasks);
}
