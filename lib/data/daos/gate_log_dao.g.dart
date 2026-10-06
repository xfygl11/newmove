// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gate_log_dao.dart';

// ignore_for_file: type=lint
mixin _$GateLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $GateLogsTable get gateLogs => attachedDatabase.gateLogs;
  GateLogDaoManager get managers => GateLogDaoManager(this);
}

class GateLogDaoManager {
  final _$GateLogDaoMixin _db;
  GateLogDaoManager(this._db);
  $$GateLogsTableTableManager get gateLogs =>
      $$GateLogsTableTableManager(_db.attachedDatabase, _db.gateLogs);
}
