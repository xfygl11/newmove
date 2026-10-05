import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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
    root = await Directory.systemTemp.createTemp('newmove_backup_test');
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
      AssetRefsCompanion.insert(shotId: shotId, assetId: assetId, role: '角色参考'),
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
    expect(asset.imagePath, '${root.path}/doc/assets/asset_1.png');
    expect(File(asset.imagePath!).existsSync(), isTrue, reason: '媒体文件已从包内恢复');

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

  test('导入越界路径包：拒绝 zip slip 写出文档目录', () async {
    final evil = File('${root.path}/tmp/evil.zip');
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonEncode({'scope': 'project'}));
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
    final evilBytes = utf8.encode('evil');
    archive.addFile(
      ArchiveFile('../../pwned.png', evilBytes.length, evilBytes),
    );
    await evil.writeAsBytes(ZipEncoder().encode(archive));

    await expectLater(
      service.importProject(evil.path),
      throwsA(isA<FormatException>()),
    );
    expect(
      File('${root.path}/pwned.png').existsSync(),
      isFalse,
      reason: '越界路径不得写出文档目录',
    );
  });

  test('导入绝对路径包：拒绝写出应用目录之外', () async {
    final abs = File('${root.path}/tmp/abs.zip');
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonEncode({'scope': 'project'}));
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
    final evilBytes = utf8.encode('evil');
    archive.addFile(
      ArchiveFile('/tmp/newmove_escape.png', evilBytes.length, evilBytes),
    );
    await abs.writeAsBytes(ZipEncoder().encode(archive));

    await expectLater(
      service.importProject(abs.path),
      throwsA(isA<FormatException>()),
    );
    expect(File('/tmp/newmove_escape.png').existsSync(), isFalse);
  });

  test('导入解压后超限包：中央目录声明的解压总量超 2GB 直接拒绝', () async {
    // 中央目录声明的解压大小远超实际内容：不写出任何文件就应中止。
    final bomb = File('${root.path}/tmp/bomb.zip');
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonEncode({'scope': 'project'}));
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
    archive.addFile(
      ArchiveFile('videos/large.mp4', 3 * 1024 * 1024 * 1024, Uint8List(0)),
    );
    await bomb.writeAsBytes(ZipEncoder().encode(archive));

    await expectLater(
      service.importProject(bomb.path),
      throwsA(isA<StateError>()),
    );
    expect(
      File('${root.path}/doc/videos/large.mp4').existsSync(),
      isFalse,
      reason: '校验应在写出文件前完成',
    );
  });


  /// 把 manifest 写成 zip；entries 为「zip 内相对路径 → 字节」。
  ///
  /// [manifest] 为空时用 entries 里自带的 backup.json（用于伪造超体积 manifest）。
  Future<File> writeZip(
    String name,
    Map<String, dynamic>? manifest, {
    Map<String, List<int>> entries = const {},
  }) async {
    final archive = Archive();
    if (manifest != null) {
      final jsonBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
    }
    for (final e in entries.entries) {
      archive.addFile(ArchiveFile(e.key, e.value.length, e.value));
    }
    final f = File('${root.path}/tmp/$name');
    await f.writeAsBytes(ZipEncoder().encode(archive));
    return f;
  }

  test('导入损坏 backup.json：抛 FormatException 而非未捕获异常', () async {
    final bad = File('${root.path}/tmp/bad.json.zip');
    final archive = Archive();
    final raw = utf8.encode('this is not json');
    archive.addFile(ArchiveFile('backup.json', raw.length, raw));
    await bad.writeAsBytes(ZipEncoder().encode(archive));

    await expectLater(
      service.importProject(bad.path),
      throwsA(isA<FormatException>()),
    );
  });

  test('新版本表（版本快照 / 台账 / 提示词覆盖）round-trip 且媒体随包走', () async {
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '快照项目'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '书'),
    );
    final scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(bookId: bookId, title: '剧'),
    );
    final shotId = await db.shotDao.insert(
      ShotsCompanion.insert(
        scriptId: scriptId,
        globalSeq: 'G01',
        globalTimeRange: '00:00-00:06',
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
    final docMediaPath = '${root.path}/doc/videos/shot_1.mp4';
    await writeDocMedia('videos/shot_1.mp4', [4, 5, 6, 7]);
    await db.revisionDao.saveShot(
      shotId: shotId,
      kind: 'video',
      summary: '旧版视频',
      snapshot: '{"outputPath":"$docMediaPath","status":"视频完成"}',
    );
    await db.generationAttemptDao.insert(
      GenerationAttemptsCompanion.insert(
        projectId: Value(projectId),
        subjectType: 'shot_video',
        subjectId: Value(shotId),
        subjectLabel: const Value('G01'),
        prompt: '生成一段视频',
        status: const Value('succeeded'),
      ),
    );
    await db.promptOverrideDao.upsert(
      scope: 'project',
      key: 'shot/storyboard.md',
      text: '项目级覆盖提示词',
      projectId: projectId,
    );

    final zipPath = await service.exportProject(projectId);
    final archive = ZipDecoder().decodeBytes(
      await File(zipPath).readAsBytes());
    final jsonFile = archive.findFile('backup.json');
    expect(jsonFile, isNotNull, reason: '导出包应包含 backup.json');
    final manifest = jsonDecode(utf8.decode(jsonFile!.content as List<int>));
    expect(manifest['shotRevisions'], hasLength(1), reason: '镜头版本快照必须随包导出');
    expect(manifest['generationAttempts'], hasLength(1), reason: '生成台账必须随包导出');
    expect(manifest['promptOverrides'], hasLength(1), reason: '提示词覆盖必须随包导出');
    final mediaNames = manifest['mediaFiles'] as List<dynamic>;
    expect(
      mediaNames,
      contains('videos/shot_1.mp4'),
      reason: '快照引用的媒体必须随包打包，不能只打包当前产物',
    );

    // ---- 模拟另一台机器：文档目录换成新根，导出机的绝对路径不存在 ----
    final root2 = await Directory.systemTemp.createTemp('newmove_backup_restore');
    final service2 = BackupService(db: db);
    addTearDown(() async => await root2.delete(recursive: true));
    await Directory('${root2.path}/doc').create(recursive: true);
    await Directory('${root2.path}/tmp').create(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(root2.path);

    final importedId = await service2.importProject(zipPath);
    expect(importedId, isNot(projectId), reason: '导入应为新增项目');
    final restoredBook = (await db.novelDao.findBookByProject(importedId))!;
    final script = (await db.scriptDao.listByBook(restoredBook.id)).single;
    final shot = (await db.shotDao.listByScript(script.id)).single;
    final revision = (await db.revisionDao.listShots(shot.id)).single;
    final snapshot = jsonDecode(revision.snapshot) as Map<String, dynamic>;
    final restored = snapshot['outputPath'] as String;
    expect(
      restored,
      startsWith('${root2.path}/'),
      reason: '快照路径必须指向恢复后的新目录',
    );
    expect(restored, isNot(equals(docMediaPath)));
    expect(File(restored).existsSync(), isTrue, reason: '快照指向的历史产物必须已解压');
    expect(File('${root2.path}/doc/videos/shot_1.mp4').existsSync(), isTrue);

    final attempt = (await db.generationAttemptDao.list(projectId: importedId)).single;
    expect(attempt.projectId, importedId, reason: '台账项目归属应重映射到新项目');
    expect(attempt.prompt, '生成一段视频');

    final override = (await db.promptOverrideDao.listForProject(importedId)).single;
    expect(override.body, '项目级覆盖提示词');
    expect(override.slotKey, 'shot/storyboard.md');
  });

  test('旧版本包（缺少新版本表键）仍可导入', () async {
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '旧包'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '书'),
    );
    final scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(bookId: bookId, title: '剧'),
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
        content: 'x',
        sourceRef: 'E01',
      ),
    );
    final zipPath = await service.exportProject(projectId);

    final archive = ZipDecoder().decodeBytes(
      await File(zipPath).readAsBytes());
    final jsonFile = archive.findFile('backup.json')!;
    final manifest = jsonDecode(utf8.decode(jsonFile.content as List<int>));
    for (final key in const [
      'shotRevisions',
      'assetRevisions',
      'generationAttempts',
      'promptOverrides',
    ]) {
      manifest.remove(key);
    }
    final oldZip = await writeZip(
      'old_format.zip',
      manifest,
      entries: {
        for (final f in archive.files)
          if (f.name != 'backup.json')
            f.name: List<int>.from(f.content),
      },
    );

    final importedId = await service.importProject(oldZip.path);
    final script = (await db.scriptDao.listByBook(bookId)).single;
    final scene = (await db.sceneDao.listByScript(script.id)).single;
    final beat = (await db.beatDao.listByScene(scene.id)).single;
    expect(beat.content, 'x');
    expect(importedId, greaterThan(0));
  });

  test('包内引用了未导出的父行：抛 FormatException 并定位行号', () async {
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '坏外键'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '书'),
    );
    await db.scriptDao.insert(ScriptsCompanion.insert(bookId: bookId, title: '剧'));
    await db.sceneDao.insert(
      ScenesCompanion.insert(
        scriptId: 1,
        seq: 1,
        location: '荒原',
        time: '黄昏',
      ),
    );
    final zipPath = await service.exportProject(projectId);

    final archive = ZipDecoder().decodeBytes(
      await File(zipPath).readAsBytes());
    final jsonFile = archive.findFile('backup.json')!;
    final manifest = jsonDecode(utf8.decode(jsonFile.content as List<int>));
    final scenes = manifest['scenes'] as List<dynamic>;
    (scenes.single as Map<String, dynamic>)['scriptId'] = 999;
    final bad = await writeZip('dangling_fk.zip', manifest);

    await expectLater(
      service.importProject(bad.path),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('不在包内'))),
    );
  });

  test('单个条目超过 500MB 上限：即使解压总量未超限也拒绝', () async {
    // 中央目录声明的单条大小即上限：真实 zip bomb 的常规手法是「小头大声明」。
    final archive = Archive();
    archive.addFile(ArchiveFile('backup.json', 19, utf8.encode('{"scope":"project"}')));
    // 声明的解压大小 600MB，实际内容 0 字节：真实 zip bomb 的常规手法。
    archive.addFile(
      ArchiveFile('videos/one.mp4', 600 * 1024 * 1024, Uint8List(0)),
    );
    final bomb = File('${root.path}/tmp/one_entry_big.zip');
    await bomb.writeAsBytes(ZipEncoder().encode(archive));
    await expectLater(
      service.importProject(bomb.path),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('500MB'))),
    );
    expect(
      File('${root.path}/doc/videos/one.mp4').existsSync(),
      isFalse,
      reason: '校验必须在写出任何文件之前完成',
    );
  });

  test('manifest 自身也计入解压上限，不能作为 zip bomb 后门', () async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile('backup.json', 3 * 1024 * 1024 * 1024, Uint8List(0)),
    );
    final bomb = File('${root.path}/tmp/manifest_bomb.zip');
    await bomb.writeAsBytes(ZipEncoder().encode(archive));
    await expectLater(
      service.importProject(bomb.path),
      throwsA(isA<StateError>()),
    );
    expect(
      File('${root.path}/doc/backup.json').existsSync(),
      isFalse,
      reason: 'manifest 超额必须在写出任何文件之前被拦下',
    );
  });
}
