// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_log_dao.dart';

// ignore_for_file: type=lint
mixin _$ImportLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $ImportLogsTable get importLogs => attachedDatabase.importLogs;
  ImportLogDaoManager get managers => ImportLogDaoManager(this);
}

class ImportLogDaoManager {
  final _$ImportLogDaoMixin _db;
  ImportLogDaoManager(this._db);
  $$ImportLogsTableTableManager get importLogs =>
      $$ImportLogsTableTableManager(_db.attachedDatabase, _db.importLogs);
}
