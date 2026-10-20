import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'provider_account_dao.g.dart';

/// 供应商账号实例数据访问对象（M41）。
@DriftAccessor(tables: [ProviderAccounts])
class ProviderAccountDao extends DatabaseAccessor<AppDatabase>
    with _$ProviderAccountDaoMixin {
  ProviderAccountDao(super.db);

  Future<List<ProviderAccount>> listByConfig(String configId) {
    return (select(providerAccounts)
          ..where((t) => t.configId.equals(configId))
          ..orderBy([(t) => OrderingTerm.asc(t.label)]))
        .get();
  }

  Stream<List<ProviderAccount>> watchByConfig(String configId) {
    return (select(providerAccounts)
          ..where((t) => t.configId.equals(configId))
          ..orderBy([(t) => OrderingTerm.asc(t.label)]))
        .watch();
  }

  Future<ProviderAccount?> find(int id) {
    return (select(providerAccounts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<ProviderAccount?> findByConfigAndLabel(
    String configId,
    String label,
  ) {
    return (select(providerAccounts)
          ..where(
            (t) => t.configId.equals(configId) & t.label.equals(label),
          ))
        .getSingleOrNull();
  }

  Future<List<ProviderAccount>> listActiveByConfig(String configId) {
    return (select(providerAccounts)
          ..where((t) => t.configId.equals(configId) & t.isActive.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.label)]))
        .get();
  }

  Future<int> insert(ProviderAccountsCompanion entry) {
    return into(providerAccounts).insert(entry);
  }

  Future<bool> updateRow(ProviderAccount row) {
    return update(providerAccounts).replace(row);
  }

  Future<int> deleteById(int id) {
    return (delete(providerAccounts)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByConfig(String configId) {
    return (delete(providerAccounts)..where((t) => t.configId.equals(configId)))
        .go();
  }

  /// 设置账号为启用状态。
  Future<void> setActive(int id) async {
    final account = await find(id);
    if (account == null) return;

    await db.transaction(() async {
      await (update(providerAccounts)
            ..where(
              (t) =>
                  t.configId.equals(account.configId) & t.isActive.equals(1),
            ))
          .write(const ProviderAccountsCompanion(isActive: Value(0)));
      await (update(providerAccounts)..where((t) => t.id.equals(id)))
          .write(const ProviderAccountsCompanion(isActive: Value(1)));
    });
  }
}
