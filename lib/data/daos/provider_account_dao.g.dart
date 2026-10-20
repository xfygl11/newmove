// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_account_dao.dart';

// ignore_for_file: type=lint
mixin _$ProviderAccountDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProviderConfigsTable get providerConfigs => attachedDatabase.providerConfigs;
  $ProviderAccountsTable get providerAccounts =>
      attachedDatabase.providerAccounts;
  ProviderAccountDaoManager get managers => ProviderAccountDaoManager(this);
}

class ProviderAccountDaoManager {
  final _$ProviderAccountDaoMixin _db;
  ProviderAccountDaoManager(this._db);
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
