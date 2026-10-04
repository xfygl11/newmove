import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/active_llm.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/truth_file_kinds.dart';
import 'package:newmove/features/novel/truth_file_store.dart';
import 'package:newmove/features/provider_config/provider_models.dart';
import 'package:newmove/features/script/script_agents.dart';
import 'package:newmove/features/script/script_service.dart';

/// 固定返回一段结构化改编 JSON，避免测试依赖真实 LLM。
const _cannedJson = '''
{
  "scenes": [
    {
      "seq": 1,
      "location": "荒原",
      "time": "黄昏",
      "characters": ["阿青", "老者"],
      "summary": "阿青遇到老者",
      "action": "阿青扶起倒地的老者",
      "dialogue": [
        {"speaker": "阿青", "type": "对白", "text": "你还好吗"},
        {"speaker": "老者", "type": "OS", "text": "快走"}
      ],
      "sound": {"music": ["低沉弦乐"], "sfx": ["风声"]},
      "startState": "疲惫",
      "endState": "警觉",
      "transition": "切"
    }
  ],
  "proposals": [
    {"id": "P1", "type": "新增对白", "text": "补一句警告", "source": "E01"}
  ]
}
''';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int bookId;
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
      agents: ScriptAgents(adapter: _FakeAdapter(_cannedJson)),
    );
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书',
        premise: Value('少年在末世觉醒'),
        world: Value('废土'),
        styleGuide: Value('冷峻'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ActiveLlm> fakeLlm() async {
    await db.providerDao.upsert(
      ProviderConfigsCompanion.insert(
        id: 'fake',
        group: 'llm',
        label: 'Fake',
        baseUrl: 'https://fake.local',
        protocol: 'openai-completions',
      ),
    );
    final provider = (await db.providerDao.findById('fake'))!;
    return ActiveLlm(
      provider: provider,
      apiKey: 'k',
      model: const ProviderModel(id: 'm', label: 'M'),
    );
  }

  group('ScriptDao / SceneDao / ScriptRevisionDao', () {
    test('ScriptDao 默认字段与更新', () async {
      final id = await db.scriptDao.insert(
        ScriptsCompanion.insert(bookId: bookId, title: '剧本A'),
      );

      var script = (await db.scriptDao.find(id))!;
      expect(script.version, 1);
      expect(script.status, '草案');
      expect(script.fidelityMode, '严格保留');

      await db.scriptDao.updateRow(script.copyWith(status: '定稿'));
      script = (await db.scriptDao.find(id))!;
      expect(script.status, '定稿');
    });

    test('SceneDao 按序号列出并可局部更新', () async {
      final scriptId = await db.scriptDao.insert(
        ScriptsCompanion.insert(bookId: bookId, title: '剧本A'),
      );
      await db.sceneDao.insert(
        ScenesCompanion.insert(
          scriptId: scriptId,
          seq: 2,
          location: 'B',
          time: '夜',
        ),
      );
      await db.sceneDao.insert(
        ScenesCompanion.insert(
          scriptId: scriptId,
          seq: 1,
          location: 'A',
          time: '晨',
        ),
      );

      final list = await db.sceneDao.listByScript(scriptId);
      expect(list.map((s) => s.seq).toList(), [1, 2]);

      await db.sceneDao.updateById(
        list.first.id,
        ScenesCompanion(location: Value('A2')),
      );
      final updated = (await db.sceneDao.find(list.first.id))!;
      expect(updated.location, 'A2');
    });

    test('ScriptRevisionDao 版本降序', () async {
      final scriptId = await db.scriptDao.insert(
        ScriptsCompanion.insert(bookId: bookId, title: '剧本A'),
      );
      await db.scriptRevisionDao.insert(
        ScriptRevisionsCompanion.insert(
          scriptId: scriptId,
          version: 1,
          content: Value('v1'),
        ),
      );
      await db.scriptRevisionDao.insert(
        ScriptRevisionsCompanion.insert(
          scriptId: scriptId,
          version: 2,
          content: Value('v2'),
        ),
      );

      final list = await db.scriptRevisionDao.listByScript(scriptId);
      expect(list.map((r) => r.version).toList(), [2, 1]);
    });
  });

  group('ScriptService', () {
    test('buildAdaptationPrompt 注入设定与 TruthFile 文本', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.characterMatrix, {
        'characters': [
          {'name': '主角'},
        ],
      });

      final prompt = await service.buildAdaptationPrompt(
        bookId: bookId,
        sourceTexts: const ['第一章正文'],
        fidelityMode: '严格保留',
      );

      expect(prompt, contains('少年在末世觉醒'));
      expect(prompt, contains('废土'));
      expect(prompt, contains('冷峻'));
      expect(prompt, contains('主角'));
      expect(prompt, contains('严格保留'));
      expect(prompt, contains('第一章正文'));
    });

    test('adaptChapters 新建剧本并落场次', () async {
      final llm = await fakeLlm();

      final script = await service.adaptChapters(
        bookId: bookId,
        sourceTexts: const ['第一章正文'],
        fidelityMode: '严格保留',
        llm: llm,
      );

      expect(script.version, 1);
      expect(script.status, '草案');
      expect(script.fidelityMode, '严格保留');
      expect(script.title, contains('剧本'));

      final scenes = await db.sceneDao.listByScript(script.id);
      expect(scenes, hasLength(1));
      expect(scenes.first.location, '荒原');
      expect(scenes.first.characters, contains('阿青'));
      expect(scenes.first.dialogue, contains('你还好吗'));
    });

    test('重新改编保存旧版本并递增版本号', () async {
      final llm = await fakeLlm();
      final first = await service.adaptChapters(
        bookId: bookId,
        sourceTexts: const ['第一章正文'],
        fidelityMode: '严格保留',
        llm: llm,
      );
      await service.finalizeScript(first.id);

      final second = await service.adaptChapters(
        bookId: bookId,
        existing: first,
        sourceTexts: const ['第二章正文'],
        fidelityMode: '允许合理压缩',
        llm: llm,
      );

      expect(second.version, 2);
      expect(second.status, '草案');
      expect(second.fidelityMode, '允许合理压缩');

      final versions = await db.scriptRevisionDao.listByScript(first.id);
      expect(versions, hasLength(1));
      expect(versions.first.version, 1);
    });

    test('提案确认写回 content', () async {
      final llm = await fakeLlm();
      final script = await service.adaptChapters(
        bookId: bookId,
        sourceTexts: const ['第一章正文'],
        fidelityMode: '严格保留',
        llm: llm,
      );

      final before = service.listProposals(script);
      expect(before, hasLength(1));
      expect(before.first.accepted, isFalse);

      await service.setProposalAccepted(
        script,
        proposalId: 'P1',
        accepted: true,
      );

      final updated = (await db.scriptDao.find(script.id))!;
      final after = service.listProposals(updated);
      expect(after.first.accepted, isTrue);
    });

    test('finalizeScript 置为定稿', () async {
      final id = await db.scriptDao.insert(
        ScriptsCompanion.insert(bookId: bookId, title: '剧本A'),
      );

      await service.finalizeScript(id);

      final script = (await db.scriptDao.find(id))!;
      expect(script.status, '定稿');
    });
  });
}
