import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/storage/asset_file_store.dart';
import 'package:newmove/core/storage/shot_file_store.dart';
import 'package:newmove/core/storage/storage_rules.dart';
import 'package:newmove/core/storage/video_file_store.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/generation_attempt_dao.dart';
import 'package:newmove/features/novel/chapter_word_gate.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// path_provider mock：文档目录指向测试临时区。
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => '$root/doc';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('newmove_m17_test');
    PathProviderPlatform.instance = _FakePathProvider(root.path);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('VersionedFileNames', () {
    test('生成带时间戳的唯一文件名', () {
      final dir = Directory('${root.path}/x');
      final a = VersionedFileNames.build(
        dir,
        prefix: 'asset',
        id: 7,
        ext: 'png',
      );
      expect(a.startsWith('${root.path}/x/asset_7_'), isTrue);
      expect(a.endsWith('.png'), isTrue);
      final match = RegExp(r'^asset_7_(\d+)\.png$')
          .firstMatch(a.substring('${dir.path}/'.length));
      expect(match, isNotNull);
      expect(int.parse(match!.group(1)!), greaterThan(0));
    });

    test('两次调用不重名（防覆盖历史字节）', () {
      final dir = Directory('${root.path}/x');
      final paths = List.generate(
        50,
        (_) => VersionedFileNames.build(dir, prefix: 'shot', id: 3, ext: 'mp4'),
      );
      expect(paths.toSet().length, paths.length);
    });
  });

  group('StorageLimits', () {
    test('替换上限为 100MB 单一来源', () {
      expect(StorageLimits.maxReplaceableFileBytes, 100 * 1024 * 1024);
    });
  });

  group('file store 落盘不覆盖', () {
    test('AssetFileStore 两次保存写入不同文件', () async {
      final store = AssetFileStore();
      final a = await store.save(1, Uint8List.fromList([1]));
      final b = await store.save(1, Uint8List.fromList([2, 2]));
      expect(a, isNot(equals(b)));
      expect(await File(a).length(), 1);
      expect(await File(b).length(), 2);
    });

    test('ShotFileStore 两次保存写入不同文件', () async {
      final store = ShotFileStore();
      final a = await store.save(2, Uint8List.fromList([3]));
      final b = await store.save(2, Uint8List.fromList([4, 4]));
      expect(a, isNot(equals(b)));
      expect(a, contains('shot_2_'));
      expect(await File(b).length(), 2);
    });

    test('VideoFileStore 两次保存写入不同文件', () async {
      final store = VideoFileStore();
      final a = await store.save(5, Uint8List.fromList([9]));
      final b = await store.save(5, Uint8List.fromList([8, 8]));
      expect(a, isNot(equals(b)));
      expect(await File(a).length(), 1);
    });

    test('saveFromPath 复制内容与命名独立', () async {
      final source = File('${root.path}/src.png');
      await source.writeAsBytes([10, 20, 30]);
      final store = AssetFileStore();
      final saved = await store.saveFromPath(4, source.path);
      expect(File(saved).existsSync(), isTrue);
      expect(await File(saved).length(), 3);
      final copied = await store.saveFromPath(4, source.path);
      expect(File(copied).existsSync(), isTrue);
      expect(await File(copied).length(), 3);
      expect(copied, isNot(equals(saved)));
    });

    test('delete 空路径不报错', () async {
      await AssetFileStore().delete(null);
      await AssetFileStore().delete('');
    });
  });

  group('ChapterWordGate', () {
    test('目标字数为 0 时跳过校验', () {
      expect(ChapterWordGate.issue(0, 0), isNull);
      expect(ChapterWordGate.issue(99999, 0), isNull);
    });

    test('达标区间内不提示', () {
      expect(ChapterWordGate.issue(2000, 2000), isNull);
      expect(ChapterWordGate.issue(1600, 2000), isNull);
      expect(ChapterWordGate.issue(2600, 2000), isNull);
    });

    test('低于下限标记为偏低', () {
      final gate = ChapterWordGate.issue(1000, 2000);
      expect(gate, isNotNull);
      expect(gate!.low, isTrue);
      expect(gate.high, isFalse);
      expect(gate.ratioPercent, 50);
      expect(gate.message, contains('低于'));
      expect(gate.message, contains('50%'));
    });

    test('高于上限标记为偏高', () {
      final gate = ChapterWordGate.issue(3000, 2000);
      expect(gate, isNotNull);
      expect(gate!.high, isTrue);
      expect(gate.low, isFalse);
      expect(gate.ratioPercent, 150);
      expect(gate.message, contains('高于'));
      expect(gate.message, contains('150%'));
    });

    test('比例恰好等于边界值时通过', () {
      expect(ChapterWordGate.issue(1600, 2000), isNull);
      expect(ChapterWordGate.issue(2600, 2000), isNull);
    });
  });

  group('GenerationAttemptDao.list', () {
    late AppDatabase db;
    late int projectId;
    late int otherProjectId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '甲'),
      );
      otherProjectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '乙'),
      );
    });

    Future<int> insertAttempt({
      String status = AttemptStatuses.succeeded,
      int? projectId,
    }) async {
      return db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          subjectType: 'shot_image',
          prompt: 'p',
          projectId: Value(projectId),
          status: Value(status),
        ),
      );
    }

    test('默认返回全部且新在前', () async {
      final a = await insertAttempt();
      final b = await insertAttempt();
      final rows = await db.generationAttemptDao.list();
      expect(rows, hasLength(2));
      expect(rows.first.id, b);
      expect(rows.last.id, a);
    });

    test('按状态过滤', () async {
      await insertAttempt(status: AttemptStatuses.succeeded);
      await insertAttempt(status: AttemptStatuses.failed);
      await insertAttempt(status: AttemptStatuses.failed);
      final rows = await db.generationAttemptDao.list(
        status: AttemptStatuses.failed,
      );
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.status == AttemptStatuses.failed), isTrue);
    });

    test('按项目过滤', () async {
      await insertAttempt(projectId: projectId);
      await insertAttempt(projectId: otherProjectId);
      final rows = await db.generationAttemptDao.list(projectId: projectId);
      expect(rows, hasLength(1));
      expect(rows.single.projectId, projectId);
    });

    test('limit 生效', () async {
      for (var i = 0; i < 5; i++) {
        await insertAttempt();
      }
      final rows = await db.generationAttemptDao.list(limit: 2);
      expect(rows, hasLength(2));
    });
  });
}
