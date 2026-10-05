import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/active_image.dart';
import 'package:newmove/agent/active_llm.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/core/network/image_provider_adapter.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/core/network/protocols.dart';
import 'package:newmove/core/storage/asset_file_store.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/asset/asset_agents.dart';
import 'package:newmove/features/asset/asset_models.dart';
import 'package:newmove/features/asset/asset_service.dart';
import 'package:newmove/features/provider_config/provider_models.dart';

const _cannedAssets = '''
{
  "assets": [
    {
      "type": "角色",
      "name": "阿青",
      "stableId": "qing",
      "boardLayout": "四视图",
      "prompt": "少女剑客，青衫，黑发",
      "appearanceAnchor": {"发色": "黑", "服装": "青衫"}
    },
    {
      "type": "角色",
      "name": "阿青·愤怒",
      "stableId": "qing_angry",
      "variantOf": "qing",
      "boardLayout": "四视图",
      "prompt": "阿青愤怒特写",
      "appearanceAnchor": {}
    },
    {
      "type": "场景",
      "name": "荒原",
      "stableId": "wasteland",
      "boardLayout": "主视图",
      "prompt": "废土荒原，黄昏",
      "appearanceAnchor": {}
    },
    {
      "type": "道具",
      "name": "古剑",
      "stableId": "sword",
      "boardLayout": "2x2",
      "prompt": "青铜古剑",
      "appearanceAnchor": {}
    }
  ]
}
''';

class _FakeLlmAdapter extends LlmProviderAdapter {
  _FakeLlmAdapter(this.reply);

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

class _FakeImageAdapter extends ImageProviderAdapter {
  @override
  Future<ImageGenerationResult> textToImage({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    String size = '1024x1024',
    String protocol = Protocols.openaiImages,
    CancelToken? cancelToken,
  }) async {
    return ImageGenerationResult(bytes: Uint8List.fromList([1, 2, 3]));
  }

  @override
  Future<ImageGenerationResult> imageToImage({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required String referencePath,
    String size = '1024x1024',
    String protocol = Protocols.openaiImages,
    CancelToken? cancelToken,
  }) async {
    return ImageGenerationResult(bytes: Uint8List.fromList([4, 5, 6]));
  }

  @override
  Future<Uint8List> downloadUrl(String url, {CancelToken? cancelToken}) async {
    return Uint8List.fromList([7, 8, 9]);
  }
}

class _FakeFileStore extends AssetFileStore {
  @override
  Future<String> save(int assetId, Uint8List bytes) async {
    final dir = await Directory.systemTemp.createTemp('newmove_asset_test');
    final file = File('${dir.path}/asset_$assetId.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int scriptId;
  late AssetService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = AssetService(
      assetDao: db.assetDao,
      beatDao: db.beatDao,
      shotDao: db.shotDao,
      scriptDao: db.scriptDao,
      agents: AssetAgents(
        adapter: _FakeLlmAdapter(_cannedAssets),
        resolver: PromptResolver(db.promptOverrideDao),
      ),
      imageAdapter: _FakeImageAdapter(),
      fileStore: _FakeFileStore(),
      revisionDao: db.revisionDao,
      attemptDao: db.generationAttemptDao,
    );

    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书',
        premise: Value('少年在末世觉醒'),
        world: Value('废土'),
        styleGuide: Value('冷峻'),
      ),
    );
    scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(
        bookId: bookId,
        title: '剧本A',
        status: Value('定稿'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ActiveLlm> fakeLlm() async {
    await db.providerDao.upsert(
      ProviderConfigsCompanion.insert(
        id: 'fake-llm',
        group: 'llm',
        label: 'Fake LLM',
        baseUrl: 'https://fake.local',
        protocol: 'openai-completions',
      ),
    );
    final provider = (await db.providerDao.findById('fake-llm'))!;
    return ActiveLlm(
      provider: provider,
      apiKey: 'k',
      model: const ProviderModel(id: 'm', label: 'M'),
    );
  }

  Future<ActiveImage> fakeImage() async {
    await db.providerDao.upsert(
      ProviderConfigsCompanion.insert(
        id: 'fake-image',
        group: 'image',
        label: 'Fake Image',
        baseUrl: 'https://fake.local',
        protocol: 'openai-images',
      ),
    );
    final provider = (await db.providerDao.findById('fake-image'))!;
    return ActiveImage(
      provider: provider,
      apiKey: 'k',
      model: const ProviderModel(id: 'img', label: 'IMG'),
    );
  }

  group('AssetService.extractAndSave', () {
    test('首轮建非变体与变体，父资产 id 正确解析', () async {
      final summary = await service.extractAndSave(
        scriptId: scriptId,
        llm: await fakeLlm(),
      );

      expect(summary.created, 3);
      expect(summary.reused, 0);
      expect(summary.variants, 1);

      final base = await db.assetDao.listByStableId(scriptId, 'qing');
      final variant = await db.assetDao.listByStableId(scriptId, 'qing_angry');
      expect(base, hasLength(1));
      expect(variant, hasLength(1));
      expect(variant.single.variantOf, base.single.id);
    });

    test('重复提取按 stableId 复用，不新增记录', () async {
      await service.extractAndSave(scriptId: scriptId, llm: await fakeLlm());
      final before = await db.assetDao.listByScript(scriptId);

      final summary = await service.extractAndSave(
        scriptId: scriptId,
        llm: await fakeLlm(),
      );
      final after = await db.assetDao.listByScript(scriptId);

      expect(summary.created, 0);
      expect(summary.reused, 4);
      expect(summary.variants, 0);
      expect(after.length, before.length);
    });
  });

  group('AssetService.buildSkeletonContext', () {
    test('注入节拍与分段 JSON', () async {
      final sceneId = await db.sceneDao.insert(
        ScenesCompanion.insert(
          scriptId: scriptId,
          seq: 1,
          location: '荒原',
          time: '黄昏',
          characters: Value(jsonEncode(['阿青'])),
          summary: Value('阿青出场'),
        ),
      );
      await db.beatDao.insert(
        BeatsCompanion.insert(
          sceneId: sceneId,
          seq: 1,
          type: '动作',
          who: Value('阿青'),
          content: '拔剑',
          object: Value(null),
          sourceRef: 'E01',
          estDurationMs: Value(3000),
          tags: Value('[]'),
        ),
      );
      await db.shotDao.insert(
        ShotsCompanion.insert(
          scriptId: scriptId,
          globalSeq: 'G01',
          batch: Value(1),
          durationMs: Value(3000),
          globalTimeRange: '00:00-00:03',
          beatRefs: Value(jsonEncode(['E01'])),
          assetStates: Value('{}'),
        ),
      );

      final context = await service.buildSkeletonContext(scriptId);

      expect(context, contains('【原子节拍】'));
      expect(context, contains('【分段与出镜状态】'));
      expect(context, contains('拔剑'));
      expect(context, contains('G01'));
    });
  });

  group('AssetService 生成与状态流转', () {
    test('generate 写入图片并置为待验收', () async {
      await service.extractAndSave(scriptId: scriptId, llm: await fakeLlm());
      final base = (await db.assetDao.listByStableId(scriptId, 'qing')).single;

      final updated = await service.generate(
        assetId: base.id,
        image: await fakeImage(),
      );

      expect(updated.status, AssetStatuses.reviewing);
      expect(updated.imagePath, isNotNull);
      expect(File(updated.imagePath!).existsSync(), isTrue);
    });

    test('createVariant 图生图并生成待验收变体', () async {
      await service.extractAndSave(scriptId: scriptId, llm: await fakeLlm());
      final base = (await db.assetDao.listByStableId(scriptId, 'qing')).single;
      await service.generate(assetId: base.id, image: await fakeImage());

      final variant = await service.createVariant(
        assetId: base.id,
        image: await fakeImage(),
      );

      expect(variant.variantOf, base.id);
      expect(variant.status, AssetStatuses.reviewing);
      expect(variant.imagePath, isNotNull);
    });

    test('adopt / discard 切换状态', () async {
      await service.extractAndSave(scriptId: scriptId, llm: await fakeLlm());
      final base = (await db.assetDao.listByStableId(scriptId, 'qing')).single;

      await service.adopt(base.id);
      expect((await db.assetDao.find(base.id))!.status, AssetStatuses.accepted);

      await service.discard(base.id);
      expect(
        (await db.assetDao.find(base.id))!.status,
        AssetStatuses.discarded,
      );
    });
  });
}
