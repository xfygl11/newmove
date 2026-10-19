// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_arc_dao.dart';

// ignore_for_file: type=lint
mixin _$StoryArcDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  $StoryArcsTable get storyArcs => attachedDatabase.storyArcs;
  $ArcNodesTable get arcNodes => attachedDatabase.arcNodes;
  StoryArcDaoManager get managers => StoryArcDaoManager(this);
}

class StoryArcDaoManager {
  final _$StoryArcDaoMixin _db;
  StoryArcDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
  $$StoryArcsTableTableManager get storyArcs =>
      $$StoryArcsTableTableManager(_db.attachedDatabase, _db.storyArcs);
  $$ArcNodesTableTableManager get arcNodes =>
      $$ArcNodesTableTableManager(_db.attachedDatabase, _db.arcNodes);
}
