// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_preset_dao.dart';

// ignore_for_file: type=lint
mixin _$PromptPresetDaoMixin on DatabaseAccessor<AppDatabase> {
  $PromptPresetsTable get promptPresets => attachedDatabase.promptPresets;
  PromptPresetDaoManager get managers => PromptPresetDaoManager(this);
}

class PromptPresetDaoManager {
  final _$PromptPresetDaoMixin _db;
  PromptPresetDaoManager(this._db);
  $$PromptPresetsTableTableManager get promptPresets =>
      $$PromptPresetsTableTableManager(_db.attachedDatabase, _db.promptPresets);
}
