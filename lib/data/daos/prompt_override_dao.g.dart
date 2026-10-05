// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_override_dao.dart';

// ignore_for_file: type=lint
mixin _$PromptOverrideDaoMixin on DatabaseAccessor<AppDatabase> {
  $PromptOverridesTable get promptOverrides => attachedDatabase.promptOverrides;
  PromptOverrideDaoManager get managers => PromptOverrideDaoManager(this);
}

class PromptOverrideDaoManager {
  final _$PromptOverrideDaoMixin _db;
  PromptOverrideDaoManager(this._db);
  $$PromptOverridesTableTableManager get promptOverrides =>
      $$PromptOverridesTableTableManager(
        _db.attachedDatabase,
        _db.promptOverrides,
      );
}
