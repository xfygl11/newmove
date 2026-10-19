import 'dart:convert';

import '../../data/app_database.dart';
import '../../data/daos/prompt_override_dao.dart';
import '../../data/daos/prompt_preset_dao.dart';

/// 提示词预设包服务（M33）。
class PromptPresetService {
  final PromptPresetDao _presetDao;
  final PromptOverrideDao _overrideDao;

  PromptPresetService({
    required this._presetDao,
    required this._overrideDao,
  });

  /// 全部预设包。
  Future<List<PromptPreset>> listPresets() => _presetDao.list();

  /// 按 id 取预设包。
  Future<PromptPreset?> getPreset(int id) async {
    final presets = await _presetDao.list();
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// 新建预设包。
  Future<int> createPreset({
    required String name,
    required String slotsJson,
  }) async {
    final existing = await _presetDao.findByName(name);
    if (existing != null) {
      throw ArgumentError('预设包名称已存在：$name');
    }
    return _presetDao.insertPreset(name: name, slotsJson: slotsJson);
  }

  /// 更新预设包名称或槽位。
  Future<void> updatePreset(
    int id, {
    String? name,
    String? slotsJson,
  }) async {
    if (name != null) {
      final existing = await _presetDao.findByName(name);
      if (existing != null && existing.id != id) {
        throw ArgumentError('预设包名称已存在：$name');
      }
    }
    await _presetDao.updatePreset(id, name: name, slotsJson: slotsJson);
  }

  /// 删除预设包。
  Future<void> deletePreset(int id) => _presetDao.deletePreset(id);

  /// 将预设包应用到项目：把预设的 slots 写为项目级覆盖。
  ///
  /// 返回实际写入的槽位数量。
  Future<int> applyPreset(int presetId, int projectId) async {
    final preset = await getPreset(presetId);
    if (preset == null) {
      throw ArgumentError('预设包不存在：$presetId');
    }

    final slots = _decodeSlots(preset.slots);
    if (slots.isEmpty) return 0;

    for (final entry in slots.entries) {
      final body = entry.value.trim();
      if (body.isEmpty) continue;
      await _overrideDao.upsert(
        scope: PromptOverrideScopes.project,
        key: entry.key,
        text: body,
        projectId: projectId,
      );
    }
    return slots.length;
  }

  /// 将项目当前覆盖保存为预设包。
  ///
  /// 返回新预设包的 id。
  Future<int> saveAsPreset({
    required String name,
    required int projectId,
  }) async {
    final overrides = await _overrideDao.listForProject(projectId);
    if (overrides.isEmpty) {
      throw ArgumentError('项目没有可保存的覆盖');
    }

    final slots = <String, String>{};
    for (final o in overrides) {
      if (o.body.trim().isNotEmpty) {
        slots[o.slotKey] = o.body;
      }
    }
    if (slots.isEmpty) {
      throw ArgumentError('项目没有非空覆盖可保存');
    }

    return _presetDao.insertPreset(name: name, slotsJson: jsonEncode(slots));
  }

  /// 解码 slots JSON。
  static Map<String, String> _decodeSlots(String slotsJson) {
    try {
      final decoded = jsonDecode(slotsJson);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}
    return const {};
  }
}
