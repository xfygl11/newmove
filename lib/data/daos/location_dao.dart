import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'location_dao.g.dart';

/// 地点系统（M29，1.2 世界观侧）数据访问对象。
///
/// 地点按 `bookId` 归属作品，`parentId` 表达层级树（顶层为 null）。
/// 空间连通用父子层级表达，不做无向边表（见 tables.dart Locations 的 ACT 简化）。
/// `Scenes.locationId` 软引用本表，删除地点不级联删场景。
@DriftAccessor(tables: [Locations])
class LocationDao extends DatabaseAccessor<AppDatabase> with _$LocationDaoMixin {
  LocationDao(super.db);

  Future<List<Location>> listByBook(int bookId) {
    final query = select(locations)..where((t) => t.bookId.equals(bookId));
    query.orderBy([(t) => OrderingTerm.asc(t.parentId)]);
    return query.get();
  }

  Future<Location?> findById(int id) {
    return (select(locations)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(LocationsCompanion entry) => into(locations).insert(entry);

  Future<void> updateById(int id, LocationsCompanion entry) async {
    await (update(locations)..where((t) => t.id.equals(id))).write(entry);
  }

  /// 删除地点。子地点悬空（parentId 指向已删行）由 UI 展示时按找不到父节点
  /// 提升为顶层处理；关联场景的 locationId 是软引用，删除不触发外键约束。
  Future<void> deleteById(int id) async {
    await (delete(locations)..where((t) => t.id.equals(id))).go();
  }
}
