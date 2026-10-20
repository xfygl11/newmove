import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';

void main() {
  late AppDatabase db;
  late String configId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // 创建供应商配置模板。
    configId = 'test-provider';
    await db.providerDao.upsert(
      ProviderConfigsCompanion.insert(
        id: configId,
        group: 'llm',
        label: '测试供应商',
        baseUrl: 'https://api.example.com',
        protocol: 'openai-completions',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ProviderAccountDao（M41）', () {
    test('insert 插入账号', () async {
      final id = await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '账号 1',
          keyRef: 'test-provider:account1',
        ),
      );
      expect(id, isPositive);

      final account = await db.providerAccountDao.find(id);
      expect(account?.label, '账号 1');
      expect(account?.keyRef, 'test-provider:account1');
      expect(account?.isActive, 1);
    });

    test('listByConfig 按配置查询', () async {
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '账号 1',
          keyRef: 'test-provider:account1',
        ),
      );
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '账号 2',
          keyRef: 'test-provider:account2',
        ),
      );

      final list = await db.providerAccountDao.listByConfig(configId);
      expect(list, hasLength(2));
      expect(list.every((a) => a.configId == configId), isTrue);
    });

    test('listByConfig 按标签升序', () async {
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: 'B 账号',
          keyRef: 'test-provider:b',
        ),
      );
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: 'A 账号',
          keyRef: 'test-provider:a',
        ),
      );

      final list = await db.providerAccountDao.listByConfig(configId);
      expect(list, hasLength(2));
      expect(list.first.label, 'A 账号');
      expect(list.last.label, 'B 账号');
    });

    test('listActiveByConfig 只返回启用的账号', () async {
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '启用账号',
          keyRef: 'test-provider:active',
          isActive: const Value(1),
        ),
      );
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '禁用账号',
          keyRef: 'test-provider:inactive',
          isActive: const Value(0),
        ),
      );

      final activeList = await db.providerAccountDao.listActiveByConfig(configId);
      expect(activeList, hasLength(1));
      expect(activeList.single.label, '启用账号');
    });

    test('findByConfigAndLabel 按配置和标签查询', () async {
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '特定账号',
          keyRef: 'test-provider:specific',
        ),
      );

      final account = await db.providerAccountDao.findByConfigAndLabel(
        configId,
        '特定账号',
      );
      expect(account?.keyRef, 'test-provider:specific');
    });

    test('updateRow 更新账号', () async {
      final id = await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '原标签',
          keyRef: 'test-provider:old',
        ),
      );
      final original = (await db.providerAccountDao.find(id))!;
      final updated = original.copyWith(
        label: '新标签',
        keyRef: 'test-provider:new',
      );
      await db.providerAccountDao.updateRow(updated);

      final updatedAccount = await db.providerAccountDao.find(id);
      expect(updatedAccount?.label, '新标签');
      expect(updatedAccount?.keyRef, 'test-provider:new');
    });

    test('setActive 切换启用状态', () async {
      final id1 = await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '账号 1',
          keyRef: 'test-provider:1',
          isActive: const Value(1),
        ),
      );
      final id2 = await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '账号 2',
          keyRef: 'test-provider:2',
          isActive: const Value(1),
        ),
      );

      // 切换到账号 2 启用。
      await db.providerAccountDao.setActive(id2);

      final active1 = await db.providerAccountDao.find(id1);
      final active2 = await db.providerAccountDao.find(id2);
      expect(active1?.isActive, 0);
      expect(active2?.isActive, 1);
    });

    test('deleteById 删除账号', () async {
      final id = await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '待删除账号',
          keyRef: 'test-provider:delete',
        ),
      );
      await db.providerAccountDao.deleteById(id);

      final account = await db.providerAccountDao.find(id);
      expect(account, isNull);
    });

    test('deleteByConfig 按配置删除', () async {
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '账号 1',
          keyRef: 'test-provider:1',
        ),
      );
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '账号 2',
          keyRef: 'test-provider:2',
        ),
      );

      await db.providerAccountDao.deleteByConfig(configId);

      final list = await db.providerAccountDao.listByConfig(configId);
      expect(list, isEmpty);
    });

    test('同一配置不同标签唯一', () async {
      await db.providerAccountDao.insert(
        ProviderAccountsCompanion.insert(
          configId: configId,
          label: '重复标签',
          keyRef: 'test-provider:first',
        ),
      );

      // 再次插入相同标签应抛出唯一约束错误。
      expect(
        () async => await db.providerAccountDao.insert(
          ProviderAccountsCompanion.insert(
            configId: configId,
            label: '重复标签',
            keyRef: 'test-provider:second',
          ),
        ),
        throwsA(anything),
      );
    });
  });
}
