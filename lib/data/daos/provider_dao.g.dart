// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_dao.dart';

// ignore_for_file: type=lint
mixin _$ProviderDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProviderConfigsTable get providerConfigs => attachedDatabase.providerConfigs;
  $ProviderAccountsTable get providerAccounts =>
      attachedDatabase.providerAccounts;
  ProviderDaoManager get managers => ProviderDaoManager(this);
}

class ProviderDaoManager {
  final _$ProviderDaoMixin _db;
  ProviderDaoManager(this._db);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(
        _db.attachedDatabase,
        _db.providerConfigs,
      );
  $$ProviderAccountsTableTableManager get providerAccounts =>
      $$ProviderAccountsTableTableManager(
        _db.attachedDatabase,
        _db.providerAccounts,
      );
}
