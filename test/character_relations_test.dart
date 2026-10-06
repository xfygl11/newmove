import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/gate_codes.dart';
import 'package:newmove/core/gate_issue.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/character_gate.dart';
import 'package:newmove/features/novel/novel_models.dart';

CharacterSpec _c({String name = '林昭', String tier = CharacterTiers.lead}) =>
    CharacterSpec(
      name: name,
      role: '主角',
      goal: '活着',
      state: '初登场',
      relations: '',
      tier: tier,
    );

void main() {
  late AppDatabase db;
  late int projectId;
  late int bookId;
  late int otherBookId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '测试书'),
    );
    otherBookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '另一本书'),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CharacterRelationDao', () {
    test('appendRelation 只追加新行，旧行正文永不被改', () async {
      final firstId = await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林川',
        target: '苏婉',
        description: '青梅竹马',
      );
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林川',
        target: '苏婉',
        description: '宿敌',
        chapterSeq: 3,
      );

      final all = await db.characterRelationDao.listByBook(bookId);
      expect(all, hasLength(2));

      // 最新在前。
      expect(all.first.id, isNot(firstId));
      expect(all.first.description, '宿敌');
      expect(all.first.chapterSeq, 3);
      expect(all.last.id, firstId);
      expect(all.last.description, '青梅竹马');
      expect(all.last.chapterSeq, isNull);
    });

    test('同一 (bookId, source, target) 至多一行 isCurrent = 1', () async {
      for (var i = 0; i < 3; i++) {
        await db.characterRelationDao.appendRelation(
          bookId: bookId,
          source: '林川',
          target: '苏婉',
          description: '第 ${i + 1} 版',
        );
      }

      final all = await db.characterRelationDao.listByBook(bookId);
      expect(all, hasLength(3));
      expect(all.where((r) => r.isCurrent == 1), hasLength(1));
      expect(all.first.isCurrent, 1);
      expect(all.first.description, '第 3 版');
    });

    test('成组以 (bookId, source, target) 为单位，不同组互不影响', () async {
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林川',
        target: '苏婉',
        description: '旧',
      );
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '苏婉',
        target: '林川',
        description: '反向关系也算另一组',
      );
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林川',
        target: '苏婉',
        description: '新',
      );
      await db.characterRelationDao.appendRelation(
        bookId: otherBookId,
        source: '林川',
        target: '苏婉',
        description: '另一本书的同名边',
      );

      final all = await db.characterRelationDao.listByBook(bookId);
      expect(all.where((r) => r.isCurrent == 1), hasLength(2));
      expect(
        all.where(
          (r) =>
              r.isCurrent == 1 && r.source == '林川' && r.target == '苏婉',
        ).single.description,
        '新',
      );
      expect(
        all.where(
          (r) =>
              r.isCurrent == 1 && r.source == '苏婉' && r.target == '林川',
        ).single.description,
        '反向关系也算另一组',
      );
    });

    test('currentEdges 只返回当前有效的边', () async {
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '甲',
        target: '乙',
        description: '旧版',
      );
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '甲',
        target: '乙',
        description: '新版',
      );
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '乙',
        target: '丙',
        description: '唯一一版',
      );
      await db.characterRelationDao.appendRelation(
        bookId: otherBookId,
        source: '甲',
        target: '乙',
        description: '别的书',
      );

      final edges = await db.characterRelationDao.currentEdges(bookId);
      expect(edges, hasLength(2));
      expect(edges.map((e) => e.description).toSet(), {
        '新版',
        '唯一一版',
      });
    });

    test('currentOf 只返回某个起点的当前出边，按 target 排序', () async {
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林川',
        target: '丙',
      );
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林川',
        target: '乙',
      );
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '丁',
        target: '林川',
      );

      final out = await db.characterRelationDao.currentOf(bookId, '林川');
      expect(out, hasLength(2));
      // SQLite BINARY 排序按字节比较，中文不走码点序，只断言集合。
      expect(
        out.map((r) => r.target),
        unorderedEquals(['乙', '丙']),
      );
    });

    test('countByBook 统计的是全量历史而不是当前边数', () async {
      await db.characterRelationDao.appendRelation(bookId: bookId, source: '甲', target: '乙');
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '甲',
        target: '乙',
      );
      expect(await db.characterRelationDao.countByBook(bookId), 2);
      expect(await db.characterRelationDao.countByBook(otherBookId), 0);
    });

    test('deleteByBook 只清本作品的历史', () async {
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '甲',
        target: '乙',
      );
      await db.characterRelationDao.appendRelation(
        bookId: otherBookId,
        source: '甲',
        target: '乙',
      );

      await db.characterRelationDao.deleteByBook(bookId);

      expect(await db.characterRelationDao.listByBook(bookId), isEmpty);
      expect(await db.characterRelationDao.listByBook(otherBookId), hasLength(1));
    });

    test('projectOfBook 返回作品所属项目，不存在的作品返回 null', () async {
      expect(await db.characterRelationDao.projectOfBook(bookId), projectId);
      expect(await db.characterRelationDao.projectOfBook(999999), isNull);
    });
  });

  group('关系门（T25.7）', () {
    Future<List<CharacterRelation>> seed(List<List<String>> pairs) async {
      for (final pair in pairs) {
        await db.characterRelationDao.appendRelation(
          bookId: bookId,
          source: pair[0],
          target: pair[1],
        );
      }
      return db.characterRelationDao.currentEdges(bookId);
    }

    test('relation_self：两端指向同一角色报 error', () async {
      final edges = await seed([
        ['林昭', '林昭'],
        ['林昭', '苏婉'],
      ]);
      final issues = CharacterGate.relationSelf(edges);
      expect(issues, hasLength(1));
      expect(issues.single.code, GateCodes.relationSelf);
      expect(issues.single.severity, GateSeverity.error);
      expect(issues.single.locator, '林昭');
      expect(issues.single.isError, isTrue);
    });

    test('relation_self：去空白后相同也算自指', () async {
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林昭',
        target: '林昭 ',
      );
      expect(
        (CharacterGate.relationSelf(
          await db.characterRelationDao.currentEdges(bookId),
        )).length,
        1,
      );
    });

    test('relation_self：没有关系数据时整门跳过', () {
      expect(CharacterGate.relationSelf(const []), isEmpty);
    });

    test('relation_orphan：一端不在角色画像里报 warn，列出缺失名字', () async {
      final edges = await seed([
        ['林昭', '苏婉'],
        ['林昭', '未登场的第三人'],
      ]);
      final issues = CharacterGate.relationOrphan(
        [_c(name: '林昭'), _c(name: '苏婉', tier: CharacterTiers.support)],
        edges,
      );
      expect(issues, hasLength(1));
      expect(issues.single.code, GateCodes.relationOrphan);
      expect(issues.single.severity, GateSeverity.warn);
      expect(issues.single.locator, '林昭');
      expect(issues.single.message, contains('未登场的第三人'));
    });

    test('relation_orphan：两端都缺失时一次性报全', () async {
      final edges = await seed([['甲', '乙']]);
      final issue = CharacterGate.relationOrphan([_c()], edges).single;
      expect(issue.message, contains('甲'));
      expect(issue.message, contains('乙'));
      expect(issue.message, '关系引用了画像里没有的角色：甲、乙');
    });

    test('relation_orphan：自指行不重复报孤儿', () async {
      final edges = await seed([['不存在', '不存在']]);
      expect(CharacterGate.relationOrphan([_c()], edges), isEmpty);
    });

    test('relation_orphan：没有关系数据时整门跳过', () {
      expect(CharacterGate.relationOrphan([_c()], const []), isEmpty);
    });

    test('validate 合并五条门', () async {
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林昭',
        target: '陌生角色',
      );
      final edges = await db.characterRelationDao.currentEdges(bookId);
      final issues = CharacterGate.validate(
        characters: [
          _c(name: '林昭', tier: CharacterTiers.lead),
          _c(name: '副角', tier: CharacterTiers.lead),
        ],
        content: '随便一段正文。',
        relations: edges,
      );
      expect(
        issues.map((i) => i.code).toSet(),
        containsAll([GateCodes.tierCap, GateCodes.relationOrphan]),
      );
    });

    test('撤销过的关系版本不进当前边，关系门看不到它', () async {
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林昭',
        target: '临时角色',
        description: '旧版',
      );
      await db.characterRelationDao.appendRelation(
        bookId: bookId,
        source: '林昭',
        target: '临时角色',
        description: '新版',
      );

      final edges = await db.characterRelationDao.currentEdges(bookId);
      expect(edges, hasLength(1));
      expect(edges.single.description, '新版');
      expect(CharacterGate.relationOrphan([_c(name: '林昭')], edges), isNotEmpty);
    });
  });
}
