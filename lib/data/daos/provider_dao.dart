import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'provider_dao.g.dart';

/// 模型供应商配置数据访问对象（API Key 不在此表，见安全存储层）。
@DriftAccessor(tables: [ProviderConfigs])
class ProviderDao extends DatabaseAccessor<AppDatabase>
    with _$ProviderDaoMixin {
  ProviderDao(super.db);

  /// 按分组、标签排序列出全部供应商。
  Future<List<ProviderConfig>> listAll() {
    return (select(providerConfigs)..orderBy([
          (t) => OrderingTerm.asc(t.group),
          (t) => OrderingTerm.asc(t.label),
        ]))
        .get();
  }

  Stream<List<ProviderConfig>> watchAll() {
    return (select(providerConfigs)..orderBy([
          (t) => OrderingTerm.asc(t.group),
          (t) => OrderingTerm.asc(t.label),
        ]))
        .watch();
  }

  Future<List<ProviderConfig>> listByGroup(String group) {
    return (select(providerConfigs)..where((t) => t.group.equals(group))).get();
  }

  Future<ProviderConfig?> findById(String id) {
    return (select(
      providerConfigs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 存在则更新，不存在则插入（主键 id）。
  Future<void> upsert(ProviderConfigsCompanion entry) {
    return into(providerConfigs).insertOnConflictUpdate(entry);
  }

  Future<int> deleteById(String id) {
    return (delete(providerConfigs)..where((t) => t.id.equals(id))).go();
  }
}
