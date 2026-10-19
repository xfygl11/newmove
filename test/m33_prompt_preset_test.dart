import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/prompt_override_dao.dart';
import 'package:newmove/data/daos/prompt_preset_dao.dart';
import 'package:newmove/features/provider_config/prompt_preset_service.dart';

void main() {
  late AppDatabase db;
  late PromptPresetDao presetDao;
  late PromptOverrideDao overrideDao;
  late PromptPresetService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    presetDao = db.promptPresetDao;
    overrideDao = db.promptOverrideDao;
    service = PromptPresetService(
      presetDao: presetDao,
      overrideDao: overrideDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('PromptPresetDao', () {
    test('insertPreset 创建预设包', () async {
      final id = await presetDao.insertPreset(
        name: '测试预设',
        slotsJson: '{"slot1":"value1"}',
      );
      expect(id, greaterThan(0));

      final presets = await presetDao.list();
      expect(presets, hasLength(1));
      expect(presets.single.name, '测试预设');
      expect(presets.single.slots, '{"slot1":"value1"}');
    });

    test('findByName 按名称查找', () async {
      await presetDao.insertPreset(name: 'A', slotsJson: '{}');
      await presetDao.insertPreset(name: 'B', slotsJson: '{}');

      final found = await presetDao.findByName('A');
      expect(found, isNotNull);
      expect(found!.name, 'A');

      final notFound = await presetDao.findByName('C');
      expect(notFound, isNull);
    });

    test('list 按名称升序', () async {
      await presetDao.insertPreset(name: 'C', slotsJson: '{}');
      await presetDao.insertPreset(name: 'A', slotsJson: '{}');
      await presetDao.insertPreset(name: 'B', slotsJson: '{}');

      final presets = await presetDao.list();
      expect(presets.map((p) => p.name).toList(), ['A', 'B', 'C']);
    });

    test('updatePreset 更新名称', () async {
      final id = await presetDao.insertPreset(name: '旧名称', slotsJson: '{}');
      await presetDao.updatePreset(id, name: '新名称');

      final presets = await presetDao.list();
      expect(presets.single.name, '新名称');
    });

    test('updatePreset 更新槽位', () async {
      final id = await presetDao.insertPreset(name: '测试', slotsJson: '{}');
      await presetDao.updatePreset(
        id,
        slotsJson: '{"slot1":"value1"}',
      );

      final presets = await presetDao.list();
      expect(presets.single.slots, '{"slot1":"value1"}');
    });

    test('deletePreset 删除预设包', () async {
      final id = await presetDao.insertPreset(name: '测试', slotsJson: '{}');
      await presetDao.deletePreset(id);

      final presets = await presetDao.list();
      expect(presets, isEmpty);
    });
  });

  group('PromptPresetService', () {
    test('createPreset 名称重复抛错', () async {
      await service.createPreset(name: 'A', slotsJson: '{}');
      expect(
        () => service.createPreset(name: 'A', slotsJson: '{}'),
        throwsArgumentError,
      );
    });

    test('updatePreset 名称与其他预设重复抛错', () async {
      final id1 = await service.createPreset(name: 'A', slotsJson: '{}');
      await service.createPreset(name: 'B', slotsJson: '{}');

      expect(
        () => service.updatePreset(id1, name: 'B'),
        throwsArgumentError,
      );
    });

    test('updatePreset 名称与自身相同时允许', () async {
      final id = await service.createPreset(name: 'A', slotsJson: '{}');
      await service.updatePreset(id, name: 'A'); // 不应抛错

      final presets = await presetDao.list();
      expect(presets.single.name, 'A');
    });

    test('deletePreset 删除预设包', () async {
      final id = await service.createPreset(name: '测试', slotsJson: '{}');
      await service.deletePreset(id);

      final presets = await presetDao.list();
      expect(presets, isEmpty);
    });

    test('applyPreset 应用空预设返回 0', () async {
      final id = await service.createPreset(name: '空预设', slotsJson: '{}');
      final projectId = 1;

      final count = await service.applyPreset(id, projectId);
      expect(count, 0);
    });

    test('applyPreset 写入项目级覆盖', () async {
      final slots = {
        'novel/outline': '大纲提示词',
        'novel/voice': '声音提示词',
      };
      final id = await service.createPreset(
        name: '测试预设',
        slotsJson: jsonEncode(slots),
      );
      final projectId = 1;

      final count = await service.applyPreset(id, projectId);
      expect(count, 2);

      final overrides = await overrideDao.listForProject(projectId);
      expect(overrides, hasLength(2));
      expect(overrides.map((o) => o.slotKey).toSet(), slots.keys.toSet());
    });

    test('saveAsPreset 从项目保存为预设', () async {
      final projectId = 1;
      await overrideDao.upsert(
        scope: PromptOverrideScopes.project,
        key: 'novel/outline',
        text: '大纲提示词',
        projectId: projectId,
      );
      await overrideDao.upsert(
        scope: PromptOverrideScopes.project,
        key: 'novel/voice',
        text: '声音提示词',
        projectId: projectId,
      );

      final id = await service.saveAsPreset(
        name: '项目预设',
        projectId: projectId,
      );
      expect(id, greaterThan(0));

      final presets = await presetDao.list();
      expect(presets.single.name, '项目预设');

      final slots = jsonDecode(presets.single.slots) as Map<String, dynamic>;
      expect(slots, hasLength(2));
      expect(slots['novel/outline'], '大纲提示词');
      expect(slots['novel/voice'], '声音提示词');
    });

    test('saveAsPreset 项目无覆盖时抛错', () async {
      expect(
        () => service.saveAsPreset(name: '测试', projectId: 999),
        throwsArgumentError,
      );
    });

    test('saveAsPreset 覆盖全为空时抛错', () async {
      final projectId = 1;
      await overrideDao.upsert(
        scope: PromptOverrideScopes.project,
        key: 'novel/outline',
        text: '',
        projectId: projectId,
      );

      expect(
        () => service.saveAsPreset(name: '测试', projectId: projectId),
        throwsArgumentError,
      );
    });

    test('getPreset 按 id 查找', () async {
      final id = await service.createPreset(name: '测试', slotsJson: '{}');

      final preset = await service.getPreset(id);
      expect(preset, isNotNull);
      expect(preset!.name, '测试');

      final notFound = await service.getPreset(999);
      expect(notFound, isNull);
    });

    test('listPresets 返回全部预设', () async {
      await service.createPreset(name: 'A', slotsJson: '{}');
      await service.createPreset(name: 'B', slotsJson: '{}');

      final presets = await service.listPresets();
      expect(presets, hasLength(2));
    });

    test('_decodeSlots 容错解码坏 JSON', () async {
      final id = await presetDao.insertPreset(
        name: '坏 JSON',
        slotsJson: 'not valid json',
      );
      final preset = await presetDao.findByName('坏 JSON');
      expect(preset, isNotNull);
      // _decodeSlots 是 private，通过 applyPreset 间接测试
      final count = await service.applyPreset(id, 1);
      expect(count, 0);
    });
  });
}
