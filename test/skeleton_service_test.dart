import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/active_llm.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/provider_config/provider_models.dart';
import 'package:newmove/features/skeleton/skeleton_agents.dart';
import 'package:newmove/features/skeleton/skeleton_service.dart';

/// 固定返回一段结构化骨架 JSON，避免测试依赖真实 LLM。
const _cannedJson = '''
{
  "globalDurationMs": 12000,
  "beats": [
    {
      "id": "E01",
      "sceneSeq": 1,
      "type": "动作",
      "who": "阿青",
      "content": "扶起倒地的老者",
      "object": "",
      "estDurationMs": 6000,
      "tags": ["开场"]
    },
    {
      "id": "E02",
      "sceneSeq": 1,
      "type": "对白",
      "who": "老者",
      "content": "快走",
      "object": "",
      "estDurationMs": 3000,
      "tags": []
    }
  ],
  "segments": [
    {
      "id": "G01",
      "batch": 1,
      "durationMs": 9000,
      "globalTimeRange": "00:00-00:09",
      "beatRefs": ["E01", "E02"],
      "assets": {
        "characters": [
          {
            "name": "阿青",
            "timeline": [{"range": "00:00-00:09", "state": "出镜"}]
          }
        ],
        "scenes": [],
        "props": []
      }
    }
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
  late int scriptId;
  late int sceneId;
  late SkeletonService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = SkeletonService(
      db: db,
      scriptDao: db.scriptDao,
      sceneDao: db.sceneDao,
      beatDao: db.beatDao,
      shotDao: db.shotDao,
      cascadeDao: db.cascadeDao,
      agents: SkeletonAgents(
        adapter: _FakeAdapter(_cannedJson),
        resolver: PromptResolver(db.promptOverrideDao),
      ),
      attemptDao: db.generationAttemptDao,
    );

    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书',
        premise: const Value('少年在末世觉醒'),
        world: const Value('废土'),
        styleGuide: const Value('冷峻'),
      ),
    );
    scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(bookId: bookId, title: '剧本A', status: const Value('定稿')),
    );
    sceneId = await db.sceneDao.insert(
      ScenesCompanion.insert(
        scriptId: scriptId,
        seq: 1,
        location: '荒原',
        time: '黄昏',
        characters: Value(jsonEncode(['阿青', '老者'])),
        summary: const Value('阿青遇到老者'),
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

  group('SkeletonService', () {
    test('buildExtractionPrompt 注入分场 JSON 与时长上限', () async {
      final script = (await db.scriptDao.find(scriptId))!;
      final scenes = await db.sceneDao.listByScript(scriptId);

      final prompt = service.buildExtractionPrompt(script: script, scenes: scenes);

      expect(prompt, contains('剧本A'));
      expect(prompt, contains('15000ms'));
      expect(prompt, contains('荒原'));
      expect(prompt, contains('阿青'));
      expect(prompt, contains('请按规则提取骨架 JSON'));
    });

    test('extract 落节拍与分段，且引用完整无告警', () async {
      final script = (await db.scriptDao.find(scriptId))!;
      final scenes = await db.sceneDao.listByScript(scriptId);
      final llm = await fakeLlm();

      final summary = await service.extract(
        script: script,
        scenes: scenes,
        llm: llm,
      );

      expect(summary.beatCount, 2);
      expect(summary.segmentCount, 1);
      expect(summary.globalDurationMs, 12000);

      final beats = await db.beatDao.listByScript(scriptId);
      expect(beats.map((b) => b.sourceRef).toList(), ['E01', 'E02']);
      expect(beats.first.sceneId, sceneId);

      final shots = await db.shotDao.listByScript(scriptId);
      expect(shots, hasLength(1));
      expect(shots.first.globalSeq, 'G01');
      expect(shots.first.beatRefs, contains('E01'));

      expect(await service.listCoverageIssues(scriptId), isEmpty);
    });

    test('listCoverageIssues 识别未知引用、重复认领与顺序倒流', () async {
      await db.beatDao.insert(
        BeatsCompanion.insert(
          sceneId: sceneId,
          seq: 1,
          type: '动作',
          who: const Value('阿青'),
          content: '起身',
          object: const Value(null),
          sourceRef: 'E01',
          estDurationMs: const Value(5000),
          tags: const Value('[]'),
        ),
      );
      await db.beatDao.insert(
        BeatsCompanion.insert(
          sceneId: sceneId,
          seq: 2,
          type: '对白',
          who: const Value('老者'),
          content: '快走',
          object: const Value(null),
          sourceRef: 'E02',
          estDurationMs: const Value(3000),
          tags: const Value('[]'),
        ),
      );
      await db.shotDao.insert(
        ShotsCompanion.insert(
          scriptId: scriptId,
          globalSeq: 'G01',
          batch: const Value(1),
          durationMs: const Value(8000),
          globalTimeRange: '00:00-00:08',
          beatRefs: Value(jsonEncode(['E01', 'E03'])),
          assetStates: const Value('{}'),
        ),
      );
      // 重复认领 E01，且段内引用顺序倒流（E02 在 E01 之前）。
      await db.shotDao.insert(
        ShotsCompanion.insert(
          scriptId: scriptId,
          globalSeq: 'G02',
          batch: const Value(1),
          durationMs: const Value(6000),
          globalTimeRange: '00:08-00:14',
          beatRefs: Value(jsonEncode(['E02', 'E01'])),
          assetStates: const Value('{}'),
        ),
      );

      final issues = await service.listCoverageIssues(scriptId);
      final locators = {for (final i in issues) i.locator};

      expect(issues.length, 3);
      expect(issues.every((i) => i.code == 'coverage'), isTrue);
      expect(issues.where((i) => i.isError).length, 1);
      expect(locators, {'G01', 'E01', 'G02'});
    });
  });
}
