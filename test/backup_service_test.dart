import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/storage/backup_service.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/shot/video_prompt.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// path_provider mock：文档目录/临时目录指向测试临时区。
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => '$root/doc';

  @override
  Future<String?> getTemporaryPath() async => '$root/tmp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BackupService service;
  late Directory root;

  setUp(() async {
    root =
        await Directory.systemTemp.createTemp('newmove_backup_test');
    PathProviderPlatform.instance = _FakePathProvider(root.path);
    await Directory('${root.path}/doc').create(recursive: true);
    await Directory('${root.path}/tmp').create(recursive: true);
    db = AppDatabase(NativeDatabase.memory());
    service = BackupService(db: db);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  Future<void> writeDocMedia(String rel, List<int> bytes) async {
    final f = File('${root.path}/doc/$rel');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes);
  }

  test('导出→导入 round-trip：数据行、外键映射与媒体路径均恢复', () async {
    // ---- 构造源项目：书 + 章节 + 真相 + 剧本链 + 视频任务 + 供应商 ----
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '源项目', genre: const Value('奇幻')),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书',
        premise: const Value('少年在末世觉醒'),
      ),
    );
    final chapterIdUnused = await db.novelDao.insertChapter(
      ChaptersCompanion.insert(
        bookId: bookId,
        seq: 1,
        title: '第一章',
        content: const Value('正文内容'),
      ),
    );
    assert(chapterIdUnused > 0);
    await db.truthFileDao.upsert(
      TruthFilesCompanion.insert(
        bookId: bookId,
        kind: '章节摘要',
        content: const Value('{"chapters":[]}'),
      ),
    );
    final scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(bookId: bookId, title: '剧本A'),
    );
    final sceneId = await db.sceneDao.insert(
      ScenesCompanion.insert(
        scriptId: scriptId,
        seq: 1,
        location: '荒原',
        time: '黄昏',
      ),
    );
    await db.beatDao.insert(
      BeatsCompanion.insert(
        sceneId: sceneId,
        seq: 1,
        type: '动作',
        content: '阿青快走',
        sourceRef: 'E01',
      ),
    );
    await writeDocMedia('assets/asset_1.png', [1, 2, 3]);
    final assetId = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: '角色',
        name: '阿青',
        stableId: 'char_aqing',
        imagePath: Value('${root.path}/doc/assets/asset_1.png'),
      ),
    );
    await writeDocMedia('videos/shot_1.mp4', [4, 5, 6, 7]);
    final shotId = await db.shotDao.insert(
      ShotsCompanion.insert(
        scriptId: scriptId,
        globalSeq: 'G01',
        globalTimeRange: '00:00-00:06',
        prompt: const Value('测试提示词'),
        outputPath: Value('${root.path}/doc/videos/shot_1.mp4'),
        outputType: const Value('video'),
      ),
    );
    await db.shotFrameDao.insert(
      ShotFramesCompanion.insert(
        shotId: shotId,
        seq: 1,
        timeRange: '00:00-00:06',
        subject: '阿青',
        shotSize: '中景',
        angle: '平视',
      ),
    );
    await db.assetRefDao.insert(
      AssetRefsCompanion.insert(
        shotId: shotId,
        assetId: assetId,
        role: '角色参考',
      ),
    );
    await db.videoTaskDao.insert(
      VideoTasksCompanion.insert(
        shotId: shotId,
        taskId: 'task_x',
        providerId: 'fake-video',
        status: const Value('成功'),
        paramsJson: Value(
          const VideoGenParams(
            modelId: 'vid',
            durationSec: 5,
            ratio: '16:9',
            resolution: '480p',
            generateAudio: false,
            referenceCount: 1,
          ).encode(),
        ),
      ),
    );
    await db.providerDao.upsert(
      ProviderConfigsCompanion.insert(
        id: 'fake-video',
        group: 'video',
        label: 'Fake Video',
        baseUrl: 'https://fake.local',
        protocol: 'async-task',
        models: const Value('[{"id":"vid","label":"VID"}]'),
      ),
    );

    // ---- 导出 ----
    final zipPath = await service.exportProject(projectId);
    final zip = File(zipPath);
    expect(await zip.exists(), isTrue);
    expect(await zip.length(), greaterThan(0));

    // ---- 清空后导入（模拟新设备恢复） ----
    final importedId = await service.importProject(zipPath);
    expect(importedId, greaterThan(0));
    expect(importedId, isNot(projectId));

    // ---- 校验数据行（导入为新增行，从新项目向下遍历） ----
    final importedProject = (await db.projectDao.findById(importedId))!;
    expect(importedProject.name, '源项目');
    expect(importedProject.genre, '奇幻');

    final book = (await db.novelDao.findBookByProject(importedId))!;
    expect(book.title, '测试书');
    expect(book.premise, '少年在末世觉醒');

    final chapter = (await db.novelDao.listChapters(book.id)).single;
    expect(chapter.seq, 1);
    expect(chapter.title, '第一章');
    expect(chapter.content, '正文内容');

    final truth = (await db.truthFileDao.listByBook(book.id)).single;
    expect(truth.kind, '章节摘要');

    final script = (await db.scriptDao.listByBook(book.id)).single;
    expect(script.title, '剧本A');
    final scene = (await db.sceneDao.listByScript(script.id)).single;
    expect(scene.location, '荒原');
    final beat = (await db.beatDao.listByScene(scene.id)).single;
    expect(beat.content, '阿青快走');
    expect(beat.sceneId, scene.id);

    final asset = (await db.assetDao.listByScript(script.id)).single;
    expect(asset.name, '阿青');
    // 相对路径 assets/asset_1.png 解压回文档目录，绝对路径与源一致且文件存在。
    expect(
      asset.imagePath,
      '${root.path}/doc/assets/asset_1.png',
    );
    expect(File(asset.imagePath!).existsSync(), isTrue,
        reason: '媒体文件已从包内恢复');

    final shot = (await db.shotDao.listByScript(script.id)).single;
    expect(shot.globalSeq, 'G01');
    expect(shot.outputType, 'video');
    expect(File(shot.outputPath!).existsSync(), isTrue);

    final frame = (await db.shotFrameDao.listByShot(shot.id)).single;
    expect(frame.subject, '阿青');
    expect(frame.shotId, shot.id);

    final ref = (await db.assetRefDao.listByShot(shot.id)).single;
    expect(ref.assetId, asset.id, reason: '引用外键重映射到新资产 id');
    expect(ref.shotId, shot.id);

    final videoTask = (await db.videoTaskDao.listByShot(shot.id)).single;
    expect(videoTask.taskId, 'task_x');
    expect(videoTask.status, '成功');
    final params = VideoGenParams.decode(videoTask.paramsJson);
    expect(params.durationSec, 5);
    expect(params.modelId, 'vid');

    final provider = (await db.providerDao.findById('fake-video'))!;
    expect(provider.baseUrl, 'https://fake.local');
    expect(provider.models, contains('vid'));
  });

  test('导入损坏包：缺 backup.json 抛 FormatException', () async {
    final bad = File('${root.path}/tmp/bad.zip');
    await bad.writeAsBytes(Uint8List.fromList([0, 1, 2]));

    await expectLater(
      service.importProject(bad.path),
      throwsA(isA<FormatException>()),
    );
  });
}
