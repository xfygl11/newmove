import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';

void main() {
  late AppDatabase db;
  late int assetId1;
  late int assetId2;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // 创建项目、书籍、剧本、资产用于测试。
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书籍',
      ),
    );
    final scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(
        bookId: bookId,
        title: '测试剧本',
      ),
    );
    assetId1 = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: 'character',
        name: '角色 A',
        stableId: 'char_a',
      ),
    );
    assetId2 = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: 'character',
        name: '角色 B',
        stableId: 'char_b',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('PromptAbTestDao（M40）', () {
    test('insert 插入 A/B 测试', () async {
      final id = await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: '提示词 A',
          promptB: '提示词 B',
        ),
      );
      expect(id, isPositive);

      final test = await db.promptAbTestDao.find(id);
      expect(test?.promptA, '提示词 A');
      expect(test?.promptB, '提示词 B');
      expect(test?.preferred, isNull);
    });

    test('insert 带结果路径', () async {
      final id = await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: '提示词 A',
          promptB: '提示词 B',
          resultAPath: const Value('/path/a.png'),
          resultBPath: const Value('/path/b.png'),
        ),
      );

      final test = await db.promptAbTestDao.find(id);
      expect(test?.resultAPath, '/path/a.png');
      expect(test?.resultBPath, '/path/b.png');
    });

    test('listByAsset 按资产查询', () async {
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: 'A1',
          promptB: 'B1',
        ),
      );
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: 'A2',
          promptB: 'B2',
        ),
      );
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId2,
          promptA: 'A3',
          promptB: 'B3',
        ),
      );

      final list1 = await db.promptAbTestDao.listByAsset(assetId1);
      expect(list1, hasLength(2));
      expect(list1.every((t) => t.assetId == 1), isTrue);

      final list2 = await db.promptAbTestDao.listByAsset(assetId2);
      expect(list2, hasLength(1));
    });

    test('updateRow 更新偏好', () async {
      final id = await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: '提示词 A',
          promptB: '提示词 B',
        ),
      );
      final original = (await db.promptAbTestDao.find(id))!;
      final updated = original.copyWith(preferred: const Value('a'));
      await db.promptAbTestDao.updateRow(updated);

      final updatedTest = await db.promptAbTestDao.find(id);
      expect(updatedTest?.preferred, 'a');
    });

    test('listPreferred 按偏好查询', () async {
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: 'A1',
          promptB: 'B1',
          preferred: const Value('a'),
        ),
      );
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId2,
          promptA: 'A2',
          promptB: 'B2',
          preferred: const Value('b'),
        ),
      );
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: 'A3',
          promptB: 'B3',
          preferred: const Value('a'),
        ),
      );
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId2,
          promptA: 'A4',
          promptB: 'B4',
          // 未选择
        ),
      );

      final preferredA = await db.promptAbTestDao.listPreferred('a');
      expect(preferredA, hasLength(2));
      expect(preferredA.every((t) => t.preferred == 'a'), isTrue);

      final preferredB = await db.promptAbTestDao.listPreferred('b');
      expect(preferredB, hasLength(1));
      expect(preferredB.single.preferred, 'b');
    });

    test('deleteById 删除', () async {
      final id = await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: '提示词 A',
          promptB: '提示词 B',
        ),
      );
      await db.promptAbTestDao.deleteById(id);

      final test = await db.promptAbTestDao.find(id);
      expect(test, isNull);
    });

    test('deleteByAsset 按资产删除', () async {
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: 'A1',
          promptB: 'B1',
        ),
      );
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId1,
          promptA: 'A2',
          promptB: 'B2',
        ),
      );
      await db.promptAbTestDao.insert(
        PromptAbTestsCompanion.insert(
          assetId: assetId2,
          promptA: 'A3',
          promptB: 'B3',
        ),
      );

      await db.promptAbTestDao.deleteByAsset(assetId1);

      final list1 = await db.promptAbTestDao.listByAsset(assetId1);
      expect(list1, isEmpty);

      final list2 = await db.promptAbTestDao.listByAsset(assetId2);
      expect(list2, hasLength(1));
    });
  });
}
