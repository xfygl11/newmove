import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'prompt_preset_dao.g.dart';

/// 提示词预设包 DAO（M33）。
///
/// 预设包是命名的一组槽位覆盖，可一键应用到项目。
/// `slots` 存 JSON 对象 `{ slotKey: body, ... }`，与 `PromptOverrides` 对齐。
@DriftAccessor(tables: [PromptPresets])
class PromptPresetDao extends DatabaseAccessor<AppDatabase>
    with _$PromptPresetDaoMixin {
  PromptPresetDao(super.db);

  /// 全部预设包，按名称升序。
  Future<List<PromptPreset>> list() {
    final query = select(promptPresets);
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  /// 按名称查找；不存在返回 null。
  Future<PromptPreset?> findByName(String name) {
    return (select(promptPresets)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
  }

  /// 新建预设包。
  Future<int> insertPreset({
    required String name,
    required String slotsJson,
  }) {
    return into(promptPresets).insert(
      PromptPresetsCompanion.insert(
        name: name,
        slots: Value(slotsJson),
      ),
    );
  }

  /// 更新预设包名称或槽位内容。
  Future<void> updatePreset(
    int id, {
    String? name,
    String? slotsJson,
  }) {
    return (update(promptPresets)..where((t) => t.id.equals(id))).write(
      PromptPresetsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        slots: slotsJson != null ? Value(slotsJson) : const Value.absent(),
      ),
    );
  }

  /// 删除预设包。
  Future<void> deletePreset(int id) {
    return (delete(promptPresets)..where((t) => t.id.equals(id))).go();
  }
}
