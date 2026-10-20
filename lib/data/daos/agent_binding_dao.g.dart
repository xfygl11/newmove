// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_binding_dao.dart';

// ignore_for_file: type=lint
mixin _$AgentBindingDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $AgentBindingsTable get agentBindings => attachedDatabase.agentBindings;
  AgentBindingDaoManager get managers => AgentBindingDaoManager(this);
}

class AgentBindingDaoManager {
  final _$AgentBindingDaoMixin _db;
  AgentBindingDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$AgentBindingsTableTableManager get agentBindings =>
      $$AgentBindingsTableTableManager(_db.attachedDatabase, _db.agentBindings);
}
