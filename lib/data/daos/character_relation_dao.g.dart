// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_relation_dao.dart';

// ignore_for_file: type=lint
mixin _$CharacterRelationDaoMixin on DatabaseAccessor<AppDatabase> {
  $CharacterRelationsTable get characterRelations =>
      attachedDatabase.characterRelations;
  $ProjectsTable get projects => attachedDatabase.projects;
  $NovelBooksTable get novelBooks => attachedDatabase.novelBooks;
  CharacterRelationDaoManager get managers => CharacterRelationDaoManager(this);
}

class CharacterRelationDaoManager {
  final _$CharacterRelationDaoMixin _db;
  CharacterRelationDaoManager(this._db);
  $$CharacterRelationsTableTableManager get characterRelations =>
      $$CharacterRelationsTableTableManager(
        _db.attachedDatabase,
        _db.characterRelations,
      );
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db.attachedDatabase, _db.novelBooks);
}
