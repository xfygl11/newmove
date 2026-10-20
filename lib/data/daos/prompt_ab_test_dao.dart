import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'prompt_ab_test_dao.g.dart';

/// 提示词 A/B 测试数据访问对象（M40）。
@DriftAccessor(tables: [PromptAbTests])
class PromptAbTestDao extends DatabaseAccessor<AppDatabase>
    with _$PromptAbTestDaoMixin {
  PromptAbTestDao(super.db);

  Future<List<PromptAbTest>> listByAsset(int assetId) {
    return (select(promptAbTests)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Stream<List<PromptAbTest>> watchByAsset(int assetId) {
    return (select(promptAbTests)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<PromptAbTest?> find(int id) {
    return (select(promptAbTests)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(PromptAbTestsCompanion entry) {
    return into(promptAbTests).insert(entry);
  }

  Future<bool> updateRow(PromptAbTest row) {
    return update(promptAbTests).replace(row);
  }

  Future<int> deleteById(int id) {
    return (delete(promptAbTests)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByAsset(int assetId) {
    return (delete(promptAbTests)..where((t) => t.assetId.equals(assetId))).go();
  }

  /// 按用户偏好查询（a / b）。
  Future<List<PromptAbTest>> listPreferred(String preferred) {
    return (select(promptAbTests)
          ..where((t) => t.preferred.equals(preferred)))
        .get();
  }
}
