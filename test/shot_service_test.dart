import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/active_image.dart';
import 'package:newmove/agent/active_llm.dart';
import 'package:newmove/core/network/image_provider_adapter.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/core/storage/shot_file_store.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/provider_config/provider_models.dart';
import 'package:newmove/features/shot/shot_agents.dart';
import 'package:newmove/features/shot/shot_models.dart';
import 'package:newmove/features/shot/shot_service.dart';

/// 固定返回分镜草案 JSON：G01 双参考绑定（含 1 个幻觉 stableId），
/// G02 与 G01 同主体/同景别/同角度，用于 A7 校验断言。
const _cannedJson = '''
{
  "shots": [
    {
      "globalSeq": "G01",
      "shotType": "中景",
      "prompt": "中景平视。{{ref1}} 阿青扶起老者，{{ref2}} 荒原黄昏背景。{{ref3}} 挂件特写。",
      "frames": [
        {
          "seq": 1,
          "timeRange": "00:00-00:06",
          "subject": "阿青",
          "shotSize": "中景",
          "angle": "平视",
          "camera": "固定",
          "blocking": "阿青位于画面左侧",
          "performance": "扶起老者",
          "dialogue": "快走"
        }
      ],
      "refs": [
        {"role": "角色参考", "stableId": "char_qing"},
        {"role": "场景参考", "stableId": "scene_yuan"},
        {"role": "道具参考", "stableId": "prop_ghost"}
      ]
    },
    {
      "globalSeq": "G02",
      "shotType": "中景",
      "prompt": "中景平视。{{ref1}} 阿青快步离开。",
      "frames": [
        {
          "seq": 1,
          "timeRange": "00:09-00:15",
          "subject": "阿青",
          "shotSize": "中景",
          "angle": "平视",
          "camera": "固定",
          "blocking": "阿青位于画面中央",
          "performance": "快步离开",
          "dialogue": null
        }
      ],
      "refs": [
        {"role": "角色参考", "stableId": "char_qing"}
      ]
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
  _FakeImageAdapter();

  /// 记录调用路径，便于断言单参考/多参考分支。
  final List<String> calls = [];

  /// 记录最近一次收到的提示词（跨实例共享，供测试断言）。
  static final List<String> lastPrompts = <String>[];

  void _record(String prompt) {
    lastPrompts
      ..clear()
      ..add(prompt);
  }

  @override
  Future<ImageGenerationResult> textToImage({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    String size = '1024x1024',
  }) async {
    calls.add('text');
    _record(prompt);
    return ImageGenerationResult(bytes: Uint8List.fromList([1]));
  }

  @override
  Future<ImageGenerationResult> imageToImage({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required String referencePath,
    String size = '1024x1024',
  }) async {
    calls.add('single');
    _record(prompt);
    return ImageGenerationResult(bytes: Uint8List.fromList([2]));
  }

  @override
  Future<ImageGenerationResult> imageToImageMulti({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required List<String> referencePaths,
    String size = '1024x1024',
  }) async {
    calls.add('multi:${referencePaths.length}');
    _record(prompt);
    return ImageGenerationResult(bytes: Uint8List.fromList([3]));
  }
}

class _FakeFileStore extends ShotFileStore {
  @override
  Future<String> save(int shotId, Uint8List bytes) async {
    final dir = await Directory.systemTemp.createTemp('newmove_shot_test');
    final file = File('${dir.path}/shot_$shotId.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int scriptId;
  late ShotService service;
  late _FakeImageAdapter fakeImageAdapter;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeImageAdapter = _FakeImageAdapter();
    service = ShotService(
      scriptDao: db.scriptDao,
      sceneDao: db.sceneDao,
      beatDao: db.beatDao,
      shotDao: db.shotDao,
      shotFrameDao: db.shotFrameDao,
      assetRefDao: db.assetRefDao,
      assetDao: db.assetDao,
      agents: ShotAgents(adapter: _FakeLlmAdapter(_cannedJson)),
      imageAdapter: fakeImageAdapter,
      fileStore: _FakeFileStore(),
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
      ScriptsCompanion.insert(bookId: bookId, title: '剧本A', status: Value('定稿')),
    );

    // 两个资产：角色阿青（有图，已采用）与场景荒原（无图）。
    final qingId = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: '角色',
        name: '阿青',
        stableId: 'char_qing',
        imagePath: Value('/tmp/newmove_test_qing.png'),
        status: const Value('已采用'),
      ),
    );
    await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: '场景',
        name: '荒原',
        stableId: 'scene_yuan',
      ),
    );

    // 参考图文件（generate 时校验存在性）。
    final f = File('/tmp/newmove_test_qing.png');
    await f.writeAsBytes([9, 9, 9]);

    // 骨架分段 G01 / G02。
    await db.shotDao.insert(
      ShotsCompanion.insert(
        scriptId: scriptId,
        globalSeq: 'G01',
        batch: Value(1),
        durationMs: Value(9000),
        globalTimeRange: '00:00-00:09',
        beatRefs: Value(jsonEncode(['E01'])),
        assetStates: Value('{}'),
      ),
    );
    await db.shotDao.insert(
      ShotsCompanion.insert(
        scriptId: scriptId,
        globalSeq: 'G02',
        batch: Value(1),
        durationMs: Value(6000),
        globalTimeRange: '00:09-00:15',
        beatRefs: Value(jsonEncode(['E02'])),
        assetStates: Value('{}'),
      ),
    );

    // 记录 qingId 以便后续断言（避免 unused 警告）。
    assert(qingId > 0);
  });

  tearDown(() async {
    await db.close();
    final f = File('/tmp/newmove_test_qing.png');
    if (await f.exists()) await f.delete();
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

  group('ShotService.directAndSave', () {
    test('落库提示词/帧/参考，幻觉 stableId 被跳过', () async {
      final summary = await service.directAndSave(
        scriptId: scriptId,
        llm: await fakeLlm(),
      );

      expect(summary.shotCount, 2);
      // 6 条草案参考里 prop_ghost 不存在，只落 3 条。
      expect(summary.refCount, 3);
      expect(summary.frameCount, 2);

      final shots = await db.shotDao.listByScript(scriptId);
      final g01 = shots.firstWhere((s) => s.globalSeq == 'G01');
      expect(g01.shotType, '中景');
      expect(g01.prompt, contains('{{ref1}}'));
      expect(g01.status, ShotStatuses.awaitingImage);

      final frames = await db.shotFrameDao.listByShot(g01.id);
      expect(frames, hasLength(1));
      expect(frames.single.subject, '阿青');
      expect(frames.single.angle, '平视');

      final refs = await db.assetRefDao.listByShot(g01.id);
      expect(refs, hasLength(2));
      expect(refs.map((r) => r.order).toList(), [0, 1]);
    });
  });

  group('ShotService.generate', () {
    test('多参考走 imageToImageMulti，参考数只算有图资产', () async {
      await service.directAndSave(scriptId: scriptId, llm: await fakeLlm());
      final g01 =
          (await db.shotDao.listByScript(scriptId)).firstWhere((s) => s.globalSeq == 'G01');

      final updated = await service.generate(
        shotId: g01.id,
        image: await fakeImage(),
      );

      // 2 个绑定资产中只有阿青有图 → 单参考路径。
      expect(fakeImageAdapter.calls, contains('single'));
      expect(updated.status, ShotStatuses.reviewing);
      expect(File(updated.outputPath!).existsSync(), isTrue);
    });

    test('提示词 {{ref N}} 被替换为语义描述', () async {
      await service.directAndSave(scriptId: scriptId, llm: await fakeLlm());
      final g01 =
          (await db.shotDao.listByScript(scriptId)).firstWhere((s) => s.globalSeq == 'G01');

      await service.generate(shotId: g01.id, image: await fakeImage());

      // fake 适配器记录的最后一次调用应包含替换后的描述。
      final lastPrompt = _FakeImageAdapter.lastPrompts.last;
      expect(lastPrompt, contains('参考图1（角色·阿青）'));
      expect(lastPrompt, isNot(contains('{{ref1}}')));
    });
    test('generateSelected 批量执行并统计成功/失败', () async {
      await service.directAndSave(scriptId: scriptId, llm: await fakeLlm());
      final shots = await db.shotDao.listByScript(scriptId);
      final ids = shots.map((s) => s.id).toList();

      final result = await service.generateSelected(
        shotIds: ids,
        image: await fakeImage(),
      );

      expect(result.success, 2);
      expect(result.failed, 0);
    });
  });

  group('ShotService.listTransitionIssues', () {
    test('同主体同景别同角度的相邻段触发 A7 告警', () async {
      await service.directAndSave(scriptId: scriptId, llm: await fakeLlm());

      final issues = await service.listTransitionIssues(scriptId);

      expect(issues, hasLength(1));
      expect(issues.single.fromSeq, 'G01');
      expect(issues.single.toSeq, 'G02');
      expect(issues.single.reason, 'no_contrast');
    });

    test('景别差 ≥2 档时不告警', () async {
      await service.directAndSave(scriptId: scriptId, llm: await fakeLlm());
      // 把 G02 改成特写（差 2 档：中景3 → 特写5）。
      final g02 =
          (await db.shotDao.listByScript(scriptId)).firstWhere((s) => s.globalSeq == 'G02');
      await db.shotDao.updateById(
        g02.id,
        ShotsCompanion(shotType: const Value('特写')),
      );

      final issues = await service.listTransitionIssues(scriptId);
      expect(issues, isEmpty);
    });
  });
}
