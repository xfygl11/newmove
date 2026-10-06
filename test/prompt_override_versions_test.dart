import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/agent/skill_loader.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/prompt_override_dao.dart';

void main() {
  late AppDatabase db;
  late PromptOverrideDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.promptOverrideDao;
  });

  tearDown(() async {
    await db.close();
  });

  const g = PromptOverrideScopes.global;
  const p = PromptOverrideScopes.project;
  const key = 'novel/writing.md';

  group('版本存档', () {
    test('新建覆盖不存版本（没有旧值可存）', () async {
      await dao.upsert(scope: g, key: key, text: '第一版');

      expect(await dao.listVersions(g, key), isEmpty);
      expect((await dao.find(g, key))!.body, '第一版');
    });

    test('正文变了一次存一条，旧值在前', () async {
      await dao.upsert(scope: g, key: key, text: '第一版');
      await dao.upsert(scope: g, key: key, text: '第二版');

      final versions = await dao.listVersions(g, key);
      expect(versions, hasLength(1));
      expect(versions.single.body, '第一版');
      expect(versions.single.scope, g);
      expect(versions.single.slotKey, key);
      expect(versions.single.projectId, isNull);
    });

    test('正文相同时不制造版本', () async {
      await dao.upsert(scope: g, key: key, text: '同一段');
      await dao.upsert(scope: g, key: key, text: '同一段');

      expect(await dao.listVersions(g, key), isEmpty);
      expect(await dao.listGlobal(), hasLength(1));
    });

    test('连续改动逐条存档，最新在前', () async {
      await dao.upsert(scope: g, key: key, text: 'v1');
      await dao.upsert(scope: g, key: key, text: 'v2');
      await dao.upsert(scope: g, key: key, text: 'v3');

      final versions = await dao.listVersions(g, key);
      expect(versions.map((v) => v.body).toList(), ['v2', 'v1']);
      expect(versions.first.id, greaterThan(versions.last.id));
    });

    test('项目级存档带 projectId，全局级不带', () async {
      await db.projectDao.insertProject(ProjectsCompanion.insert(name: 'A'));
      await db.projectDao.insertProject(ProjectsCompanion.insert(name: 'B'));

      await dao.upsert(scope: p, key: key, text: '旧A', projectId: 1);
      await dao.upsert(scope: p, key: key, text: '新A', projectId: 1);
      await dao.upsert(scope: p, key: key, text: '旧B', projectId: 2);
      await dao.upsert(scope: p, key: key, text: '新B', projectId: 2);

      expect((await dao.listVersions(p, key, projectId: 1)).map((v) => v.body),
        ['旧A'],
      );
      expect((await dao.listVersions(p, key, projectId: 2)).map((v) => v.body),
        ['旧B'],
      );
      // 项目级开关关闭时也要能列出历史：历史是审计数据，不该被开关挡住。
      await dao.setProjectPromptsEnabled(1, false);
      expect((await dao.listVersions(p, key, projectId: 1)).map((v) => v.body),
        ['旧A'],
      );
    });

    test('同 key 的全局级与项目级版本互不串档', () async {
      await db.projectDao.insertProject(ProjectsCompanion.insert(name: 'A'));
      await dao.upsert(scope: g, key: key, text: 'g1');
      await dao.upsert(scope: g, key: key, text: 'g2');
      await dao.upsert(scope: p, key: key, text: 'p1', projectId: 1);
      await dao.upsert(scope: p, key: key, text: 'p2', projectId: 1);

      expect((await dao.listVersions(g, key)).single.body, 'g1');
      expect((await dao.listVersions(p, key, projectId: 1)).single.body, 'p1');
    });
  });

  group('回退', () {
    test('回退把历史正文写回当前值', () async {
      await dao.upsert(scope: g, key: key, text: 'v1');
      await dao.upsert(scope: g, key: key, text: 'v2');
      await dao.upsert(scope: g, key: key, text: 'v3');

      final v1 = (await dao.listVersions(g, key)).singleWhere((v) => v.body == 'v1');
      await dao.restoreVersion(v1.id);

      expect((await dao.find(g, key))!.body, 'v1');
    });

    test('回退本身又产生一条新版本，历史链不回溯删除', () async {
      await dao.upsert(scope: g, key: key, text: 'v1');
      await dao.upsert(scope: g, key: key, text: 'v2');

      final v1 = (await dao.listVersions(g, key)).singleWhere((v) => v.body == 'v1');
      await dao.restoreVersion(v1.id);

      // v3（当前值）被存档，加原来的 v1、v2 共两条。
      final versions = await dao.listVersions(g, key);
      expect(versions.map((v) => v.body).toList(), ['v2', 'v1']);
    });

    test('回退到最近历史后再回退，能取回更早的版本', () async {
      await dao.upsert(scope: g, key: key, text: 'v1');
      await dao.upsert(scope: g, key: key, text: 'v2');
      await dao.upsert(scope: g, key: key, text: 'v3');

      final v1 = (await dao.listVersions(g, key))
          .singleWhere((v) => v.body == 'v1');
      final v2 = (await dao.listVersions(g, key))
          .singleWhere((v) => v.body == 'v2');
      await dao.restoreVersion(v1.id);
      await dao.restoreVersion(v2.id);

      expect((await dao.find(g, key))!.body, 'v2');
    });

    test('回退项目级版本带 projectId', () async {
      await db.projectDao.insertProject(ProjectsCompanion.insert(name: 'A'));
      await db.projectDao.insertProject(ProjectsCompanion.insert(name: 'B'));
      await dao.upsert(scope: p, key: key, text: '旧A', projectId: 1);
      await dao.upsert(scope: p, key: key, text: '新A', projectId: 1);
      await dao.upsert(scope: p, key: key, text: '旧B', projectId: 2);

      final oldA = (await dao.listVersions(p, key, projectId: 1)).single;
      await dao.restoreVersion(oldA.id);

      expect((await dao.find(p, key, projectId: 1))!.body, '旧A');
      expect((await dao.find(p, key, projectId: 2))!.body, '旧B');
    });

    test('回退不存在的版本抛 ArgumentError', () async {
      expect(() => dao.restoreVersion(99999), throwsArgumentError);
    });
  });

  group('项目级提示词开关', () {
    test('存量项目（列未设置）默认视为启用', () async {
      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '存量'),
      );
      expect(await dao.projectPromptsEnabled(id), isTrue);
    });

    test('关闭写 0、开启写 1', () async {
      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      await dao.setProjectPromptsEnabled(id, false);
      expect(await dao.projectPromptsEnabled(id), isFalse);
      expect((await db.projectDao.findById(id))!.useProjectPrompts, 0);

      await dao.setProjectPromptsEnabled(id, true);
      expect(await dao.projectPromptsEnabled(id), isTrue);
      expect((await db.projectDao.findById(id))!.useProjectPrompts, 1);
    });

    test('不存在的 id 视为启用（不会静默关掉覆盖）', () async {
      expect(await dao.projectPromptsEnabled(424242), isTrue);
    });

    test('关闭不影响已写入的覆盖行', () async {
      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      await dao.upsert(scope: p, key: key, text: '项目版', projectId: id);
      await dao.setProjectPromptsEnabled(id, false);
      expect((await dao.find(p, key, projectId: id))!.body, '项目版');
    });
  });

  group('解析器遵循开关', () {
    late PromptResolver resolver;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      resolver = PromptResolver(dao);
    });

    test('开启时取项目级覆盖', () async {
      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      await dao.upsert(scope: g, key: key, text: '全局版');
      await dao.upsert(scope: p, key: key, text: '项目版', projectId: id);

      expect(await resolver.resolve(key, projectId: id), '项目版');
      expect((await resolver.findOverride(key, projectId: id))!.body, '项目版');
    });

    test('关闭时跳过项目级，走全局', () async {
      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      await dao.upsert(scope: g, key: key, text: '全局版');
      await dao.upsert(scope: p, key: key, text: '项目版', projectId: id);
      await dao.setProjectPromptsEnabled(id, false);

      expect(await resolver.resolve(key, projectId: id), '全局版');
      expect((await resolver.findOverride(key, projectId: id))!.body, '全局版');
    });

    test('关闭且无全局覆盖时回落内置 skill 原文', () async {
      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      await dao.upsert(scope: p, key: key, text: '项目版', projectId: id);
      await dao.setProjectPromptsEnabled(id, false);

      final builtin = await SkillLoader.load(key);
      expect(await resolver.resolve(key, projectId: id), builtin);
    });

    test('resolveByBook 解析出的项目遵循开关', () async {
      final pid = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      final bookId = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(projectId: pid, title: 't'),
      );
      await dao.upsert(scope: g, key: key, text: '全局版');
      await dao.upsert(scope: p, key: key, text: '项目版', projectId: pid);
      await dao.setProjectPromptsEnabled(pid, false);

      expect(await resolver.resolveByBook(key, bookId: bookId), '全局版');
    });

    test('开关只影响指定项目，不影响其他项目', () async {
      final a = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 'A'),
      );
      final b = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 'B'),
      );
      await dao.upsert(scope: p, key: key, text: '项目A', projectId: a);
      await dao.upsert(scope: p, key: key, text: '项目B', projectId: b);
      await dao.setProjectPromptsEnabled(a, false);

      final builtin = await SkillLoader.load(key);
      expect(await resolver.resolve(key, projectId: a), builtin);
      expect(await resolver.resolve(key, projectId: b), '项目B');
    });
  });

  group('清理', () {
    test('deleteVersionsByProject 只清自己的项目级历史', () async {
      await db.projectDao.insertProject(ProjectsCompanion.insert(name: 'A'));
      await db.projectDao.insertProject(ProjectsCompanion.insert(name: 'B'));
      await dao.upsert(scope: p, key: key, text: '旧A', projectId: 1);
      await dao.upsert(scope: p, key: key, text: '新A', projectId: 1);
      await dao.upsert(scope: p, key: key, text: '旧B', projectId: 2);
      await dao.upsert(scope: p, key: key, text: '新B', projectId: 2);
      await dao.upsert(scope: g, key: key, text: '旧G');
      await dao.upsert(scope: g, key: key, text: '新G');

      await dao.deleteVersionsByProject(1);

      expect(await dao.listVersions(p, key, projectId: 1), isEmpty);
      expect(
        (await dao.listVersions(p, key, projectId: 2)).single.body,
        '旧B',
      );
      expect(
        (await dao.listVersions(g, key)).single.body,
        '旧G',
      );
    });
  });
}
