import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/active_llm.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/provider_config/provider_models.dart';
import 'package:newmove/features/script/script_agents.dart';
import 'package:newmove/features/script/script_models.dart';
import 'package:newmove/features/script/script_service.dart';

const _cannedJson = '''
{
  "hook": "阿青在荒原发现神秘老者",
  "cliff": "老者暗示前方有伏兵",
  "description": "阿青在荒原遇到受伤老者并获知危险",
  "keywords": ["荒原", "阿青", "老者", "危机"],
  "scenes": [
    {
      "seq": 1,
      "location": "荒原",
      "time": "黄昏",
      "characters": ["阿青", "老者"],
      "summary": "阿青遇到老者",
      "action": "阿青扶起倒地的老者",
      "dialogue": [
        {"speaker": "阿青", "type": "对白", "text": "你还好吗"}
      ],
      "sound": {"music": ["低沉弦乐"], "sfx": ["风声"]},
      "startState": "疲惫",
      "endState": "警觉",
      "transition": "切"
    }
  ],
  "proposals": []
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

  group('AdaptationResult 集级元数据解析（M32）', () {
    test('fromJson 解析 hook/cliff/description/keywords', () {
      final result = AdaptationResult.fromJson(jsonDecode(_cannedJson));
      expect(result.hook, '阿青在荒原发现神秘老者');
      expect(result.cliff, '老者暗示前方有伏兵');
      expect(result.description, '阿青在荒原遇到受伤老者并获知危险');
      expect(result.keywords, ['荒原', '阿青', '老者', '危机']);
    });

    test('toJson 包含四字段', () {
      final result = AdaptationResult.fromJson(jsonDecode(_cannedJson));
      final json = result.toJson();
      expect(json['hook'], '阿青在荒原发现神秘老者');
      expect(json['cliff'], '老者暗示前方有伏兵');
      expect(json['description'], '阿青在荒原遇到受伤老者并获知危险');
      expect(json['keywords'], ['荒原', '阿青', '老者', '危机']);
    });

    test('缺字段时回落 null', () {
      final result = AdaptationResult.fromJson({
        'scenes': jsonDecode(_cannedJson)['scenes'],
        'proposals': [],
      });
      expect(result.hook, isNull);
      expect(result.cliff, isNull);
      expect(result.description, isNull);
      expect(result.keywords, isNull);
    });
  });

  group('ScriptService.adaptChapters 保存集级元数据（M32）', () {
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
        assetDao: db.assetDao,
        shotDao: db.shotDao,
        attemptDao: db.generationAttemptDao,
        agents: ScriptAgents(
          adapter: _FakeAdapter(_cannedJson),
          resolver: PromptResolver(db.promptOverrideDao),
        ),
      );
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试项目'),
      );
      bookId = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(
          projectId: projectId,
          title: '测试书',
          premise: const Value('少年在末世觉醒'),
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
        model: const ProviderModel(id: 'm', label: 'M', contextWindow: 8192, maxOutputTokens: 4096),
      );
    }

    test('新建剧本保存 hook/cliff/description/keywords', () async {
      final llm = await fakeLlm();

      final script = await service.adaptChapters(
        bookId: bookId,
        sourceTexts: const ['第一章正文'],
        fidelityMode: '严格保留',
        llm: llm,
      );

      expect(script.hook, '阿青在荒原发现神秘老者');
      expect(script.cliff, '老者暗示前方有伏兵');
      expect(script.description, '阿青在荒原遇到受伤老者并获知危险');
      expect(script.keywords, isNotNull);
      final keywords = jsonDecode(script.keywords!) as List;
      expect(keywords, ['荒原', '阿青', '老者', '危机']);
    });

    test('重新改编更新 hook/cliff/description/keywords', () async {
      final llm = await fakeLlm();

      final first = await service.adaptChapters(
        bookId: bookId,
        sourceTexts: const ['第一章正文'],
        fidelityMode: '严格保留',
        llm: llm,
      );

      final second = await service.adaptChapters(
        bookId: bookId,
        existing: first,
        sourceTexts: const ['第二章正文'],
        fidelityMode: '允许合理压缩',
        llm: llm,
      );

      expect(second.version, 2);
      expect(second.hook, '阿青在荒原发现神秘老者');
      expect(second.cliff, '老者暗示前方有伏兵');
    });
  });
}
