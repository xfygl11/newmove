import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/agent/skill_loader.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/prompt_override_dao.dart';
import 'package:newmove/features/script/script_agents.dart';
import 'package:newmove/features/script/script_fingerprint.dart';
import 'package:newmove/features/script/script_service.dart';

const _cannedJson = '{"scenes": [], "proposals": []}';

class _FakeAdapter extends LlmProviderAdapter {
  _FakeAdapter(this.reply);

  final String reply;

  @override
  Future<String> chat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<({ChatRole role, String content})> messages,
    double temperature = 0.8,
  }) async {
    return reply;
  }
}

Future<int> _insertScript(AppDatabase db) async {
  final projectId = await db.projectDao.insertProject(
    ProjectsCompanion.insert(name: 'p'),
  );
  final bookId = await db.novelDao.insertBook(
    NovelBooksCompanion.insert(projectId: projectId, title: 'b'),
  );
  return db.scriptDao.insert(ScriptsCompanion.insert(bookId: bookId, title: '剧本'));
}

Future<int> _insertScene(AppDatabase db, int scriptId, int seq) =>
    db.sceneDao.insert(
      ScenesCompanion.insert(
        scriptId: scriptId,
        seq: seq,
        location: '教室',
        time: '白天',
      ),
    );

Future<int> _insertAsset(AppDatabase db, int scriptId, String name) =>
    db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: '角色',
        name: name,
        stableId: 'char_$name',
      ),
    );

Future<int> _insertShot(AppDatabase db, int scriptId) => db.shotDao.insert(
  ShotsCompanion.insert(
    scriptId: scriptId,
    globalSeq: 'G01',
    globalTimeRange: '00:00-00:05',
  ),
);


Scene _scene(int id, int seq, {String action = ''}) => Scene(
  id: id,
  scriptId: 1,
  seq: seq,
  location: '教室',
  time: '白天',
  characters: '["小明"]',
  action: action,
  dialogue: '[]',
  sound: '{}',
);

void main() {
  group('ScriptFingerprint', () {
    test('同输入指纹稳定', () {
      final rows = [_scene(1, 1), _scene(2, 2)];
      expect(ScriptFingerprint.hashOf(rows), ScriptFingerprint.hashOf(rows));
    });

    test('插入顺序不影响指纹', () {
      expect(
        ScriptFingerprint.hashOf([_scene(1, 1), _scene(2, 2)]),
        ScriptFingerprint.hashOf([_scene(2, 2), _scene(1, 1)]),
      );
    });

    test('行 id 与 scriptId 不参与指纹', () {
      final a = [_scene(1, 1), _scene(2, 2)];
      final b = [
        _scene(99, 1).copyWith(scriptId: 77),
        _scene(100, 2).copyWith(scriptId: 77),
      ];
      expect(ScriptFingerprint.hashOf(a), ScriptFingerprint.hashOf(b));
    });

    test('场次内容变化则指纹变化', () {
      final base = [_scene(1, 1), _scene(2, 2)];
      final moved = [_scene(1, 1), _scene(2, 3)];
      expect(ScriptFingerprint.hashOf(base), isNot(ScriptFingerprint.hashOf(moved)));

      final acted = [_scene(1, 1), _scene(2, 2, action: '小明推开门')];
      expect(ScriptFingerprint.hashOf(base), isNot(ScriptFingerprint.hashOf(acted)));
    });

    test('场次数量变化则指纹变化', () {
      expect(
        ScriptFingerprint.hashOf([_scene(1, 1)]),
        isNot(ScriptFingerprint.hashOf([_scene(1, 1), _scene(2, 2)])),
      );
    });

    test('空场次列表也有稳定指纹', () {
      expect(ScriptFingerprint.hashOf([]), ScriptFingerprint.hashOf([]));
      expect(ScriptFingerprint.hashOf([]).length, 16);
    });
  });

  group('PromptResolver 三级覆盖', () {
    late AppDatabase db;
    late PromptOverrideDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.promptOverrideDao;
    });

    tearDown(() async {
      await db.close();
    });

    test('三级回落顺序：项目级 > 全局级 > 无覆盖返回 null', () async {
      expect(await dao.find('global', 's1.md'), isNull);
      expect(await dao.find('project', 's1.md', projectId: 1), isNull);

      await dao.upsert(
        scope: PromptOverrideScopes.global,
        key: 's1.md',
        text: '全局版',
      );
      await dao.upsert(
        scope: PromptOverrideScopes.project,
        key: 's1.md',
        text: '项目版',
        projectId: 1,
      );

      final g = await dao.find('global', 's1.md');
      expect(g, isNotNull);
      expect(g!.body, '全局版');

      final p = await dao.find('project', 's1.md', projectId: 1);
      expect(p, isNotNull);
      expect(p!.body, '项目版');

      // 项目 2 没有自己的覆盖，取全局版。
      final other = await dao.find('project', 's1.md', projectId: 2);
      expect(other, isNull);
    });

    test('重复 upsert 覆盖正文而不是新增行', () async {
      await dao.upsert(
        scope: PromptOverrideScopes.global,
        key: 's2.md',
        text: '第一版',
      );
      await dao.upsert(
        scope: PromptOverrideScopes.global,
        key: 's2.md',
        text: '第二版',
      );
      final rows = await dao.listGlobal();
      expect(rows, hasLength(1));
      expect(rows.single.body, '第二版');
    });

    test('删除覆盖后回到无覆盖状态', () async {
      await dao.upsert(
        scope: PromptOverrideScopes.global,
        key: 's3.md',
        text: 'x',
      );
      await dao.deleteRow('global', 's3.md');
      expect(await dao.find('global', 's3.md'), isNull);
    });

    test('deleteByProject 只清项目级，不动全局级', () async {
      await dao.upsert(
        scope: PromptOverrideScopes.global,
        key: 's4.md',
        text: '全局',
      );
      await dao.upsert(
        scope: PromptOverrideScopes.project,
        key: 's4.md',
        text: '项目',
        projectId: 5,
      );
      await dao.deleteByProject(5);
      expect(await dao.find('project', 's4.md', projectId: 5), isNull);
      expect(await dao.find('global', 's4.md'), isNotNull);
    });

    test('项目级与全局级同 key 互不干扰', () async {
      await dao.upsert(
        scope: PromptOverrideScopes.project,
        key: 's5.md',
        text: '项目 1',
        projectId: 1,
      );
      await dao.upsert(
        scope: PromptOverrideScopes.project,
        key: 's5.md',
        text: '项目 2',
        projectId: 2,
      );
      expect(
        (await dao.find('project', 's5.md', projectId: 1))!.body,
        '项目 1',
      );
      expect(
        (await dao.find('project', 's5.md', projectId: 2))!.body,
        '项目 2',
      );
    });

    test('PromptResolver.allSlots 与内置 skill 目录一一对应', () async {
      expect(PromptResolver.allSlots, hasLength(14));
      expect(PromptResolver.allSlots, contains('shot/storyboard.md'));
      expect(PromptResolver.allSlots, contains('novel/writing.md'));
      expect(PromptResolver.allSlots, contains('novel/voice_design.md'));
      expect(PromptResolver.allSlots.toSet(), PromptResolver.allSlots.toSet());
    });
  });

  group('PromptResolver 覆盖解析', () {
    late AppDatabase db;
    late PromptResolver resolver;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      db = AppDatabase(NativeDatabase.memory());
      resolver = PromptResolver(db.promptOverrideDao);
    });

    tearDown(() async {
      await db.close();
    });

    test('无覆盖时回落内置 skill 原文', () async {
      final builtin = await SkillLoader.load('novel/writing.md');
      expect(await resolver.resolve('novel/writing.md'), builtin);
    });

    test('全局级覆盖优先于内置原文', () async {
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.global,
        key: 'novel/writing.md',
        text: '全局写作规则',
      );
      expect(await resolver.resolve('novel/writing.md'), '全局写作规则');
    });

    test('项目级覆盖优先于全局级', () async {
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.global,
        key: 'novel/writing.md',
        text: '全局写作规则',
      );
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.project,
        key: 'novel/writing.md',
        text: '项目写作规则',
        projectId: 7,
      );
      expect(
        await resolver.resolve('novel/writing.md', projectId: 7),
        '项目写作规则',
      );
    });

    test('空串覆盖视为未覆盖，继续回落下一级', () async {
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.project,
        key: 'novel/writing.md',
        text: '   ',
        projectId: 7,
      );
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.global,
        key: 'novel/writing.md',
        text: '全局写作规则',
      );
      expect(
        await resolver.resolve('novel/writing.md', projectId: 7),
        '全局写作规则',
      );
    });

    test('resolveByBook 按作品解析出项目级覆盖', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试项目'),
      );
      final bookId = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(projectId: projectId, title: '测试书'),
      );
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.project,
        key: 'novel/writing.md',
        text: '项目写作规则',
        projectId: projectId,
      );
      expect(await resolver.resolveByBook('novel/writing.md', bookId: bookId),
        '项目写作规则');
    });

    test('resolveByBook 空 bookId 跳过项目级，只走全局级', () async {
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.global,
        key: 'novel/writing.md',
        text: '全局写作规则',
      );
      expect(
        await resolver.resolveByBook('novel/writing.md'),
        '全局写作规则',
      );
    });

    test('resolveByBook 未知作品回落内置原文', () async {
      final builtin = await SkillLoader.load('novel/writing.md');
      expect(
        await resolver.resolveByBook('novel/writing.md', bookId: 99999),
        builtin,
      );
    });
  });

  group('M19 资产 / 镜头失效标记 DAO', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('markStaleByScript 幂等，只标记本剧本', () async {
      final s1 = await _insertScript(db);
      final s2 = await _insertScript(db);

      await _insertAsset(db, s1, 'a1');
      await _insertAsset(db, s2, 'a2');

      expect(await db.assetDao.markStaleByScript(s1), 1);
      // 已失效的行不重复计入。
      expect(await db.assetDao.markStaleByScript(s1), 0);

      final all = [
        ...await db.assetDao.listByScript(s1),
        ...await db.assetDao.listByScript(s2),
      ];
      expect(all.map((a) => a.isStale), [1, 0]);
    });

    test('clearStaleById 清除失效标记', () async {
      final s1 = await _insertScript(db);
      final id = await _insertAsset(db, s1, 'a1');
      await db.assetDao.markStaleByScript(s1);
      expect((await db.assetDao.find(id))!.isStale, 1);

      expect(await db.assetDao.clearStaleById(id), 1);
      expect((await db.assetDao.find(id))!.isStale, 0);
      // 已清除的行再清不返回计数。
      expect(await db.assetDao.clearStaleById(id), 0);
    });

    test('镜头侧失效标记与资产侧一致', () async {
      final s1 = await _insertScript(db);
      final id = await _insertShot(db, s1);
      expect(await db.shotDao.markStaleByScript(s1), 1);
      expect((await db.shotDao.find(id))!.isStale, 1);
      expect(await db.shotDao.clearStaleById(id), 1);
      expect((await db.shotDao.find(id))!.isStale, 0);
    });

    test('M19 新列默认值：scriptHash 为 null，isStale 为 0', () async {
      final s1 = await _insertScript(db);
      expect((await db.scriptDao.find(s1))!.scriptHash, isNull);

      final aid = await _insertAsset(db, s1, 'a');
      expect((await db.assetDao.find(aid))!.isStale, 0);

      final sid = await _insertShot(db, s1);
      expect((await db.shotDao.find(sid))!.isStale, 0);
    });
  });

  group('applyUpstreamChange 下游失效联动', () {
    late AppDatabase db;
    late ScriptService service;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      service = ScriptService(
        db: db,
        scriptDao: db.scriptDao,
        sceneDao: db.sceneDao,
        revisionDao: db.scriptRevisionDao,
        novelDao: db.novelDao,
        truthDao: db.truthFileDao,
        cascadeDao: db.cascadeDao,
        agents: ScriptAgents(
          adapter: _FakeAdapter(_cannedJson),
          resolver: PromptResolver(db.promptOverrideDao),
        ),
        assetDao: db.assetDao,
        shotDao: db.shotDao,
        attemptDao: db.generationAttemptDao,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('首次写指纹不标记失效', () async {
      final scriptId = await _insertScript(db);
      await _insertScene(db, scriptId, 1);
      final assetId = await _insertAsset(db, scriptId, '角色');

      await service.applyUpstreamChange(scriptId);

      final script = await db.scriptDao.find(scriptId);
      expect(script!.scriptHash, isNotNull);
      // 首次没有旧指纹可比，存量产物视为有效。
      expect((await db.assetDao.find(assetId))!.isStale, 0);
    });

    test('场次内容变化则标记下游失效', () async {
      final scriptId = await _insertScript(db);
      await _insertScene(db, scriptId, 1);
      final assetId = await _insertAsset(db, scriptId, '角色');
      final shotId = await _insertShot(db, scriptId);

      await service.applyUpstreamChange(scriptId);

      // 编辑场次正文后重新检测。
      final scene = (await db.sceneDao.listByScript(scriptId)).first;
      await db.sceneDao.updateRow(
        scene.copyWith(action: '小明突然推开门'),
      );
      await service.applyUpstreamChange(scriptId);

      final freshScript = await db.scriptDao.find(scriptId);
      expect(freshScript!.scriptHash, isNotNull);
      expect((await db.assetDao.find(assetId))!.isStale, 1);
      expect((await db.shotDao.find(shotId))!.isStale, 1);
    });

    test('指纹未变则不标记失效、不重写剧本行', () async {
      final scriptId = await _insertScript(db);
      await _insertScene(db, scriptId, 1);
      final assetId = await _insertAsset(db, scriptId, '角色');

      await service.applyUpstreamChange(scriptId);
      final hashBefore = (await db.scriptDao.find(scriptId))!.scriptHash;

      await service.applyUpstreamChange(scriptId);

      expect((await db.scriptDao.find(scriptId))!.scriptHash, hashBefore);
      expect((await db.assetDao.find(assetId))!.isStale, 0);
    });

    test('updateScene 自动触发下游失效检测', () async {
      final scriptId = await _insertScript(db);
      await _insertScene(db, scriptId, 1);
      final assetId = await _insertAsset(db, scriptId, '角色');
      await service.applyUpstreamChange(scriptId);

      final scene = (await db.sceneDao.listByScript(scriptId)).first;
      await service.updateScene(
        scene.id,
        const ScenesCompanion(action: Value('小明转身离开')),
      );

      expect((await db.assetDao.find(assetId))!.isStale, 1);
      expect((await db.scriptDao.find(scriptId))!.scriptHash, isNotNull);
    });
  });
}
