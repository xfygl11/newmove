import 'dart:async';
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
import 'package:newmove/agent/active_video.dart';
import 'package:newmove/core/network/image_provider_adapter.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/core/network/protocols.dart';
import 'package:newmove/core/network/video_provider_adapter.dart';
import 'package:newmove/core/storage/shot_file_store.dart';
import 'package:newmove/core/storage/video_file_store.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/provider_config/provider_models.dart';
import 'package:newmove/features/shot/shot_agents.dart';
import 'package:newmove/features/shot/shot_models.dart';
import 'package:newmove/features/shot/shot_service.dart';
import 'package:newmove/features/shot/video_prompt.dart';

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
    String protocol = Protocols.openaiImages,
    CancelToken? cancelToken,
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
    String protocol = Protocols.openaiImages,
    CancelToken? cancelToken,
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
    String protocol = Protocols.openaiImages,
    CancelToken? cancelToken,
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

/// 视频适配器 fake：submit 返回固定 taskId，poll 按 nextStatus 剧本推进。
class _FakeVideoAdapter extends VideoProviderAdapter {
  _FakeVideoAdapter();

  /// 下一次 poll 返回的状态：running / success / failed。
  String nextStatus = 'running';

  /// 非 null 时 submit 直接抛错（模拟提交失败回滚）。
  Object? submitError;

  int submitCount = 0;
  List<String> lastSubmitPrompts = [];
  String? lastFirstFramePath;
  List<String> lastRefPaths = [];
  int? lastMaxRefs;
  CancelToken? lastSubmitCancelToken;
  CancelToken? lastPollCancelToken;

  /// 非空时轮询阻塞在此，用于测试「在途请求可被取消」。
  Completer<void>? pollGate;

  @override
  Future<String> submit({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required int durationSec,
    required String ratio,
    required String resolution,
    List<String> referencePaths = const [],
    String? firstFramePath,
    int maxImageRefs = 9,
    bool generateAudio = false,
    String protocol = 'async-task',
    CancelToken? cancelToken,
  }) async {
    lastSubmitCancelToken = cancelToken;
    if (submitError != null) throw submitError!;
    submitCount++;
    lastSubmitPrompts.add(prompt);
    lastFirstFramePath = firstFramePath;
    lastRefPaths = referencePaths;
    lastMaxRefs = maxImageRefs;
    return 'task_$submitCount';
  }

  @override
  Future<VideoTaskSnapshot> poll({
    required String baseUrl,
    required String apiKey,
    required String taskId,
    String model = '',
    String protocol = 'async-task',
    CancelToken? cancelToken,
  }) async {
    lastPollCancelToken = cancelToken;
    if (pollGate != null) await pollGate!.future;
    switch (nextStatus) {
      case 'success':
        // 返回最小 mp4 字节编 base64 data URI。
        final b64 = base64Encode(Uint8List.fromList([0, 1, 2, 3]));
        return VideoTaskSnapshot(
          taskId: taskId,
          status: 'success',
          base64: b64,
        );
      case 'failed':
        return VideoTaskSnapshot(
          taskId: taskId,
          status: 'failed',
          error: '模拟失败',
        );
      default:
        return VideoTaskSnapshot(taskId: taskId, status: 'running');
    }
  }
}

class _FakeVideoFileStore extends VideoFileStore {
  /// 测试环境没有 path_provider 插件，用临时目录替代应用私有目录。
  Future<Directory> _dir() =>
      Directory.systemTemp.createTemp('newmove_video_test');

  @override
  Future<String> save(int shotId, Uint8List bytes) async {
    final dir = await _dir();
    final file = File('${dir.path}/shot_$shotId.mp4');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Future<String> saveFromPath(int shotId, String sourcePath) async {
    final dir = await _dir();
    final target = File('${dir.path}/shot_$shotId.mp4');
    await File(sourcePath).copy(target.path);
    return target.path;
  }
}

/// 排空事件循环：让在途异步调用推进到下一个 await。
Future<void> _flushEvents() async {
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int scriptId;
  late ShotService service;
  late _FakeImageAdapter fakeImageAdapter;
  late _FakeVideoAdapter fakeVideoAdapter;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeImageAdapter = _FakeImageAdapter();
    fakeVideoAdapter = _FakeVideoAdapter();
    service = ShotService(
      db: db,
      scriptDao: db.scriptDao,
      sceneDao: db.sceneDao,
      beatDao: db.beatDao,
      shotDao: db.shotDao,
      shotFrameDao: db.shotFrameDao,
      assetRefDao: db.assetRefDao,
      assetDao: db.assetDao,
      agents: ShotAgents(
        adapter: _FakeLlmAdapter(_cannedJson),
        resolver: PromptResolver(db.promptOverrideDao),
      ),
      imageAdapter: fakeImageAdapter,
      fileStore: _FakeFileStore(),
      videoAdapter: fakeVideoAdapter,
      videoFileStore: _FakeVideoFileStore(),
      videoTaskDao: db.videoTaskDao,
      providerDao: db.providerDao,
      revisionDao: db.revisionDao,
      attemptDao: db.generationAttemptDao,
    );
    // 测试不经过安全存储，直接注入固定 Key。
    service.readProviderKey = (_) async => 'k';

    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书',
        premise: const Value('少年在末世觉醒'),
        world: const Value('废土'),
        styleGuide: const Value('冷峻'),
      ),
    );
    scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(
        bookId: bookId,
        title: '剧本A',
        status: const Value('定稿'),
      ),
    );

    // 两个资产：角色阿青（有图，已采用）与场景荒原（无图）。
    final qingId = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: '角色',
        name: '阿青',
        stableId: 'char_qing',
        imagePath: const Value('/tmp/newmove_test_qing.png'),
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
        batch: const Value(1),
        durationMs: const Value(9000),
        globalTimeRange: '00:00-00:09',
        beatRefs: Value(jsonEncode(['E01'])),
        assetStates: const Value('{}'),
      ),
    );
    await db.shotDao.insert(
      ShotsCompanion.insert(
        scriptId: scriptId,
        globalSeq: 'G02',
        batch: const Value(1),
        durationMs: const Value(6000),
        globalTimeRange: '00:09-00:15',
        beatRefs: Value(jsonEncode(['E02'])),
        assetStates: const Value('{}'),
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

  Future<ActiveVideo> fakeVideo() async {
    await db.providerDao.upsert(
      ProviderConfigsCompanion.insert(
        id: 'fake-video',
        group: 'video',
        label: 'Fake Video',
        baseUrl: 'https://fake.local',
        protocol: 'async-task',
      ),
    );
    final provider = (await db.providerDao.findById('fake-video'))!;
    return ActiveVideo(
      provider: provider,
      apiKey: 'k',
      model: const ProviderModel(id: 'vid', label: 'VID'),
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
      final g01 = (await db.shotDao.listByScript(scriptId))
          .firstWhere((s) => s.globalSeq == 'G01');

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
      final g01 = (await db.shotDao.listByScript(scriptId))
          .firstWhere((s) => s.globalSeq == 'G01');

      await service.generate(shotId: g01.id, image: await fakeImage());

      // fake 适配器记录的最后一次调用应包含替换后的描述。
      final lastPrompt = _FakeImageAdapter.lastPrompts.last;
      expect(lastPrompt, contains('参考图1（角色·阿青）'));
      expect(lastPrompt, isNot(contains('{{ref1}}')));
      // 只有 1 张图可上传：{{ref2}}/{{ref3}} 必须被摘掉而不是留成空洞，
      // 否则模型会引用一个并不存在的参考图。
      expect(lastPrompt, isNot(contains('{{ref')));
      expect(lastPrompt, isNot(contains('参考图2')));
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

    test('参考图按图片模型 maxImageRefs 截断，不超供应商上限', () async {
      await service.directAndSave(scriptId: scriptId, llm: await fakeLlm());
      final g01 = (await db.shotDao.listByScript(scriptId))
          .firstWhere((s) => s.globalSeq == 'G01');

      // 清掉 directAndSave 绑定的引用，改绑 8 个有图资产。
      await db.assetRefDao.deleteByShot(g01.id);
      final assetIds = <int>[];
      for (var i = 0; i < 8; i++) {
        final path = '/tmp/newmove_test_extra_$i.png';
        final id = await db.assetDao.insert(
          AssetsCompanion.insert(
            scriptId: scriptId,
            type: '角色',
            name: '角色$i',
            stableId: 'char_extra_$i',
            imagePath: Value(path),
            status: const Value('已采用'),
          ),
        );
        await File(path).writeAsBytes([i]);
        await db.assetRefDao.insert(
          AssetRefsCompanion.insert(
            shotId: g01.id,
            assetId: id,
            role: '角色参考',
            order: Value(i),
          ),
        );
        assetIds.add(id);
      }

      // 图片模型声明 maxImageRefs=6，超出部分不得上传。
      final base = await fakeImage();
      final limitedImage = ActiveImage(
        provider: base.provider,
        apiKey: base.apiKey,
        model: const ProviderModel(
          id: 'img',
          label: 'IMG',
          maxImageRefs: 6,
        ),
      );

      await service.generate(shotId: g01.id, image: limitedImage);

      // 8 张有图资产被截断到 6 张，走多图分支且只传 6 张。
      expect(
        fakeImageAdapter.calls,
        contains('multi:6'),
        reason: '参考图应被截断到模型上限 6 张',
      );

      // 清理测试临时文件。
      for (var i = 0; i < 8; i++) {
        final f = File('/tmp/newmove_test_extra_$i.png');
        if (await f.exists()) await f.delete();
      }
      expect(assetIds, hasLength(8));
    });
  });

  group('ShotService.submitVideo / pollVideoTask（M6）', () {
    // 准备：生成分镜提示词 + 确认分镜图，使镜头可提交视频。
    Future<Shot> prepareConfirmedShot() async {
      await service.directAndSave(scriptId: scriptId, llm: await fakeLlm());
      final g01 = (await db.shotDao.listByScript(scriptId))
          .firstWhere((s) => s.globalSeq == 'G01');
      final confirmed = await service.generate(
        shotId: g01.id,
        image: await fakeImage(),
      );
      await service.confirmShot(confirmed.id);
      return (await db.shotDao.find(confirmed.id))!;
    }

    test('提交成功：A9 提示词含时间轴/时长，任务快照落库，镜头置视频生成中', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();

      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 8,
          ratio: '9:16',
          resolution: '720p',
          generateAudio: true,
          referenceCount: 0,
        ),
      );

      // 任务行：状态生成中、参数快照正确。
      expect(task.status, '生成中');
      expect(task.taskId, 'task_1');
      expect(task.providerId, 'fake-video');
      final params = VideoGenParams.decode(task.paramsJson);
      expect(params.durationSec, 8);
      expect(params.ratio, '9:16');
      expect(params.resolution, '720p');
      expect(params.generateAudio, isTrue);

      // A9.2 提示词：Target duration 用参数值 8s（镜头 durationMs 为 6s）。
      expect(
        fakeVideoAdapter.lastSubmitPrompts.single,
        contains('Target duration: 8s'),
      );
      expect(fakeVideoAdapter.lastSubmitPrompts.single, contains('Timeline:'));
      // G01 单帧：时间块头部（0:00-0:06）+ 连续自然语言描述；无 HARD CUT。
      expect(
        fakeVideoAdapter.lastSubmitPrompts.single,
        contains('【0:00-0:06】'),
      );
      expect(fakeVideoAdapter.lastSubmitPrompts.single, contains('同期对白「快走」'));
      expect(
        fakeVideoAdapter.lastSubmitPrompts.single,
        isNot(contains('HARD CUT')),
      );
      expect(
        fakeVideoAdapter.lastSubmitPrompts.single,
        contains('Immutable locks:'),
      );

      // 镜头状态：视频生成中 + outputType video + modelVersion 记录模型。
      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.status, ShotStatuses.videoGenerating);
      expect(updated.outputType, 'video');
      expect(updated.modelVersion, 'vid');
    });

    test('默认提交：分镜图作普通参考，不走首帧通道', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
        ),
      );
      expect(fakeVideoAdapter.lastFirstFramePath, isNull);
      expect(fakeVideoAdapter.lastRefPaths, contains(shot.outputPath));
    });

    test('首帧通道：分镜图作 first_frame，快照记录 useFirstFrame', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
          useFirstFrame: true,
        ),
      );
      expect(fakeVideoAdapter.lastFirstFramePath, shot.outputPath);
      expect(fakeVideoAdapter.lastRefPaths, isNot(contains(shot.outputPath)));
      final task = (await db.videoTaskDao.listByShot(shot.id)).single;
      expect(VideoGenParams.decode(task.paramsJson).useFirstFrame, isTrue);
    });

    test('轮询成功：视频落盘，任务置成功，镜头置视频完成', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
        ),
      );

      fakeVideoAdapter.nextStatus = 'success';
      final done = await service.pollVideoTask(task.id);

      expect(done.status, '成功');
      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.status, ShotStatuses.videoDone);
      expect(updated.outputType, 'video');
      expect(File(updated.outputPath!).existsSync(), isTrue);
    });

    test('轮询业务失败：任务置失败并回滚镜头到分镜图已确认', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
        ),
      );

      fakeVideoAdapter.nextStatus = 'failed';
      final failed = await service.pollVideoTask(task.id);

      expect(failed.status, '失败');
      expect(failed.error, '模拟失败');
      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.status, ShotStatuses.confirmed);
    });

    test('轮询仍在生成：任务保持生成中', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
        ),
      );

      final running = await service.pollVideoTask(task.id);
      expect(running.status, '生成中');
      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.status, ShotStatuses.videoGenerating);
    });

    test('提交失败：回滚镜头到分镜图已确认 + outputType image', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      fakeVideoAdapter.submitError = Exception('网络错误');

      await expectLater(
        service.submitVideo(
          shotId: shot.id,
          video: video,
          params: const VideoGenParams(
            modelId: 'vid',
            durationSec: 5,
            ratio: '16:9',
            resolution: '480p',
            generateAudio: false,
            referenceCount: 0,
          ),
        ),
        throwsException,
      );

      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.status, ShotStatuses.confirmed);
      expect(updated.outputType, 'image');
      // 未留下任务行。
      expect(await db.videoTaskDao.listByShot(shot.id), isEmpty);
    });

    test('重试失败任务：复用参数快照再次提交', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 10,
          ratio: '1:1',
          resolution: '1080p',
          generateAudio: true,
          referenceCount: 0,
        ),
      );
      fakeVideoAdapter.nextStatus = 'failed';
      await service.pollVideoTask(task.id);

      fakeVideoAdapter.nextStatus = 'running';
      final retried = await service.retryVideo(
        videoTaskId: task.id,
        video: await fakeVideo(),
      );

      expect(fakeVideoAdapter.submitCount, 2);
      expect(retried.status, '生成中');
      expect(retried.taskId, 'task_2');
      // 快照参数保持不变。
      final params = VideoGenParams.decode(retried.paramsJson);
      expect(params.durationSec, 10);
      expect(params.ratio, '1:1');
      expect(params.resolution, '1080p');
    });

    test('取消进行中任务：置已取消并回滚镜头到分镜图已确认', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
        ),
      );

      final cancelled = await service.cancelVideoTask(task.id);
      expect(cancelled.status, '已取消');
      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.status, ShotStatuses.confirmed);
      expect(updated.outputType, 'image');
    });

    test('取消任务会中断在途请求：提交与轮询均持有可用令牌', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();

      final token = GenerationCancelToken();
      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
        ),
        cancelToken: token,
      );
      // 提交时的令牌透传给 Dio，而非在适配器外被丢弃。
      expect(fakeVideoAdapter.lastSubmitCancelToken, token.dioToken);
      expect(fakeVideoAdapter.lastSubmitCancelToken!.isCancelled, isFalse);

      token.cancel();
      expect(fakeVideoAdapter.lastSubmitCancelToken!.isCancelled, isTrue);

      // 轮询自带令牌；取消任务后该令牌必须已置位（这才是「点取消有响应」）。
      final gate = Completer<void>();
      fakeVideoAdapter.pollGate = gate;
      final inFlight = service.pollVideoTask(task.id);
      await _flushEvents();
      expect(fakeVideoAdapter.lastPollCancelToken, isNotNull);
      expect(fakeVideoAdapter.lastPollCancelToken!.isCancelled, isFalse);

      await service.cancelVideoTask(task.id);
      expect(fakeVideoAdapter.lastPollCancelToken!.isCancelled, isTrue);

      gate.complete();
      await inFlight;
      fakeVideoAdapter.pollGate = null;
    });

    test('已取消任务不再轮询，镜头保持确认态', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
        ),
      );
      await service.cancelVideoTask(task.id);

      fakeVideoAdapter.nextStatus = 'success';
      final still = await service.pollVideoTask(task.id);
      expect(still.status, '已取消');
      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.status, ShotStatuses.confirmed);
    });

    test('切换视频版本：outputPath 指向历史成功任务产物', () async {
      final shot = await prepareConfirmedShot();
      final video = await fakeVideo();
      final task = await service.submitVideo(
        shotId: shot.id,
        video: video,
        params: const VideoGenParams(
          modelId: 'vid',
          durationSec: 5,
          ratio: '16:9',
          resolution: '480p',
          generateAudio: false,
          referenceCount: 0,
        ),
      );
      fakeVideoAdapter.nextStatus = 'success';
      final done = await service.pollVideoTask(task.id);
      final versionPath = done.outputPath!;

      await service.selectVideoVersion(
        shotId: shot.id,
        outputPath: versionPath,
      );
      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.outputPath, versionPath);
      expect(updated.status, ShotStatuses.videoDone);
    });

    test('替换视频：本地文件导入私有目录并更新镜头', () async {
      final shot = await prepareConfirmedShot();
      final src = File('${Directory.systemTemp.path}/newmove_replace_src.mp4');
      await src.writeAsBytes(Uint8List.fromList([9, 8, 7, 6]));

      await service.replaceVideo(shotId: shot.id, sourcePath: src.path);
      final updated = (await db.shotDao.find(shot.id))!;
      expect(updated.outputType, 'video');
      expect(updated.status, ShotStatuses.videoDone);
      expect(updated.outputPath, isNot(src.path));
      expect(File(updated.outputPath!).existsSync(), isTrue);
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
      final g02 = (await db.shotDao.listByScript(scriptId))
          .firstWhere((s) => s.globalSeq == 'G02');
      await db.shotDao.updateById(
        g02.id,
        const ShotsCompanion(shotType: Value('特写')),
      );

      final issues = await service.listTransitionIssues(scriptId);
      expect(issues, isEmpty);
    });

    test('平视 → 侧面是 90° 旋转，不报缺少区分度', () async {
      await service.directAndSave(scriptId: scriptId, llm: await fakeLlm());
      // 把 G02 首帧改成侧面。此前侧面被当成 0°（与平视同值），
      // 正面转侧面会被误报成「画面缺少区分度」。
      final g02 = (await db.shotDao.listByScript(scriptId))
          .firstWhere((s) => s.globalSeq == 'G02');
      final frame = (await db.shotFrameDao.listByShot(g02.id)).first;
      await db.shotFrameDao.updateById(
        frame.id,
        const ShotFramesCompanion(angle: Value('侧面')),
      );

      final issues = await service.listTransitionIssues(scriptId);
      expect(issues, isEmpty, reason: '正面转侧面已有足够区分度');
    });
  });

  group('ShotService 镜头级服装覆盖（M19 T21.13）', () {
    late int qingId;
    late int costumeShotId;

    setUp(() async {
      qingId = (await db.assetDao.listByScript(scriptId))
          .firstWhere((a) => a.stableId == 'char_qing')
          .id;
      await db.assetDao.updateById(
        qingId,
        const AssetsCompanion(
          costumeSets: Value(
            '[{"name":"校服","description":"蓝白运动外套配深蓝长裤"},'
            '{"name":"斗篷","description":"深灰长斗篷"}]',
          ),
        ),
      );
      costumeShotId = (await db.shotDao.listByScript(scriptId))
          .firstWhere((s) => s.globalSeq == 'G01')
          .id;
    });

    test('updateCostumeOverrides 落库可读回；空清单写 null', () async {
      await service.updateCostumeOverrides(
        shotId: costumeShotId,
        overrides: const [
          ShotCostumeOverride(stableId: 'char_qing', name: '校服'),
        ],
      );

      final saved = (await db.shotDao.find(costumeShotId))!;
      final decoded = ShotCostumeOverride.decode(saved.costumeOverrides);
      expect(decoded, hasLength(1));
      expect(decoded.single.stableId, 'char_qing');
      expect(decoded.single.name, '校服');

      await service.updateCostumeOverrides(
        shotId: costumeShotId,
        overrides: const [],
      );
      expect((await db.shotDao.find(costumeShotId))!.costumeOverrides, isNull);
    });

    test('buildDirectionContext 把服装套清单注入资产清单', () async {
      final context = await service.buildDirectionContext(scriptId);

      expect(context, contains('costumeSets'));
      expect(context, contains('校服'));
      expect(context, contains('斗篷'));
    });

    test('listCostumeIssues 识别清单外套名、未出镜角色与重复覆盖', () async {
      await db.assetRefDao.insert(
        AssetRefsCompanion.insert(
          shotId: costumeShotId,
          assetId: qingId,
          role: '角色参考',
          order: const Value(0),
        ),
      );
      await service.updateCostumeOverrides(
        shotId: costumeShotId,
        overrides: const [
          ShotCostumeOverride(stableId: 'char_qing', name: '囚服'),
          ShotCostumeOverride(stableId: 'char_missing', name: '校服'),
          ShotCostumeOverride(stableId: 'char_qing', name: '斗篷'),
        ],
      );

      final issues = await service.listCostumeIssues(scriptId);

      expect(
        issues.map((i) => i.code),
        containsAll(['costume_unknown', 'costume_orphan', 'costume_duplicate']),
      );
      expect(issues.every((i) => !i.isError), isTrue);
      expect(
        issues.singleWhere((i) => i.code == 'costume_unknown').message,
        contains('可用：校服 / 斗篷'),
      );
    });

    test('套名在清单内且角色已出镜时不报问题', () async {
      await db.assetRefDao.insert(
        AssetRefsCompanion.insert(
          shotId: costumeShotId,
          assetId: qingId,
          role: '角色参考',
          order: const Value(0),
        ),
      );
      await service.updateCostumeOverrides(
        shotId: costumeShotId,
        overrides: const [
          ShotCostumeOverride(stableId: 'char_qing', name: '斗篷'),
        ],
      );

      expect(await service.listCostumeIssues(scriptId), isEmpty);
    });

    test('无覆盖的镜头不产生任何问题', () async {
      expect(await service.listCostumeIssues(scriptId), isEmpty);
    });
  });
}
