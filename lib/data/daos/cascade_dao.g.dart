// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cascade_dao.dart';

// ignore_for_file: type=lint
mixin _$CascadeDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $ChaptersTable get chapters => attachedDatabase.chapters;
  $ChapterRevisionsTable get chapterRevisions =>
      attachedDatabase.chapterRevisions;
  $TruthFilesTable get truthFiles => attachedDatabase.truthFiles;
  $ScriptsTable get scripts => attachedDatabase.scripts;
  $ScriptRevisionsTable get scriptRevisions => attachedDatabase.scriptRevisions;
  $ScenesTable get scenes => attachedDatabase.scenes;
  $BeatsTable get beats => attachedDatabase.beats;
  $AssetsTable get assets => attachedDatabase.assets;
  $ShotsTable get shots => attachedDatabase.shots;
  $ShotFramesTable get shotFrames => attachedDatabase.shotFrames;
  $AssetRefsTable get assetRefs => attachedDatabase.assetRefs;
  $VideoTasksTable get videoTasks => attachedDatabase.videoTasks;
  $ShotRevisionsTable get shotRevisions => attachedDatabase.shotRevisions;
  $AssetRevisionsTable get assetRevisions => attachedDatabase.assetRevisions;
  $GenerationAttemptsTable get generationAttempts =>
      attachedDatabase.generationAttempts;
  CascadeDaoManager get managers => CascadeDaoManager(this);
}

class CascadeDaoManager {
  final _$CascadeDaoMixin _db;
  CascadeDaoManager(this._db);
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
  $$TruthFilesTableTableManager get truthFiles =>
      $$TruthFilesTableTableManager(_db.attachedDatabase, _db.truthFiles);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db.attachedDatabase, _db.scripts);
  $$ScriptRevisionsTableTableManager get scriptRevisions =>
      $$ScriptRevisionsTableTableManager(
        _db.attachedDatabase,
        _db.scriptRevisions,
      );
  $$ScenesTableTableManager get scenes =>
      $$ScenesTableTableManager(_db.attachedDatabase, _db.scenes);
  $$BeatsTableTableManager get beats =>
      $$BeatsTableTableManager(_db.attachedDatabase, _db.beats);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$ShotsTableTableManager get shots =>
      $$ShotsTableTableManager(_db.attachedDatabase, _db.shots);
  $$ShotFramesTableTableManager get shotFrames =>
      $$ShotFramesTableTableManager(_db.attachedDatabase, _db.shotFrames);
  $$AssetRefsTableTableManager get assetRefs =>
      $$AssetRefsTableTableManager(_db.attachedDatabase, _db.assetRefs);
  $$VideoTasksTableTableManager get videoTasks =>
      $$VideoTasksTableTableManager(_db.attachedDatabase, _db.videoTasks);
  $$ShotRevisionsTableTableManager get shotRevisions =>
      $$ShotRevisionsTableTableManager(_db.attachedDatabase, _db.shotRevisions);
  $$AssetRevisionsTableTableManager get assetRevisions =>
      $$AssetRevisionsTableTableManager(
        _db.attachedDatabase,
        _db.assetRevisions,
      );
  $$GenerationAttemptsTableTableManager get generationAttempts =>
      $$GenerationAttemptsTableTableManager(
        _db.attachedDatabase,
        _db.generationAttempts,
      );
}
