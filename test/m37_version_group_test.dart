import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/revision_dao.dart';

void main() {
  late AppDatabase db;
  late RevisionDao dao;
  late int shotId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.revisionDao;

    // 创建一个项目、书籍、剧本、镜头用于测试。
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书籍',
      ),
    );
    final scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(
        bookId: bookId,
        title: '测试剧本',
      ),
    );
    shotId = await db.shotDao.insert(
      ShotsCompanion.insert(
        scriptId: scriptId,
        globalSeq: 'S0001',
        globalTimeRange: '0-5s',
        shotType: const Value('中景'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('RevisionDao versionGroup（M37）', () {
    test('saveShot 带 versionGroup 参数', () async {
      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{"test": true}',
        summary: '测试快照',
        versionGroup: 1,
      );

      final revisions = await dao.listShots(shotId);
      expect(revisions, hasLength(1));
      expect(revisions.single.versionGroup, 1);
    });

    test('saveShot 不带 versionGroup 时落 null', () async {
      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{"test": true}',
      );

      final revisions = await dao.listShots(shotId);
      expect(revisions, hasLength(1));
      expect(revisions.single.versionGroup, isNull);
    });

    test('listByVersionGroup 查询同组快照', () async {
      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{"v": 1}',
        versionGroup: 1,
      );
      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{"v": 2}',
        versionGroup: 1,
      );
      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{"v": 3}',
        versionGroup: 2,
      );

      final group1 = await dao.listByVersionGroup(1);
      expect(group1, hasLength(2));
      expect(group1.every((r) => r.versionGroup == 1), isTrue);

      final group2 = await dao.listByVersionGroup(2);
      expect(group2, hasLength(1));
      expect(group2.single.versionGroup, 2);
    });

    test('nextVersionGroup 递增', () async {
      final v1 = await dao.nextVersionGroup();
      expect(v1, 1);

      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
        versionGroup: 1,
      );

      final v2 = await dao.nextVersionGroup();
      expect(v2, 2);

      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
        versionGroup: 2,
      );

      final v3 = await dao.nextVersionGroup();
      expect(v3, 3);
    });

    test('nextVersionGroup 无记录时返回 1', () async {
      final v = await dao.nextVersionGroup();
      expect(v, 1);
    });

    test('saveShot 带 versionGroup 仍降级旧 current', () async {
      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{"v": 1}',
        versionGroup: 1,
      );
      await dao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{"v": 2}',
        versionGroup: 1,
      );

      final revisions = await dao.listShots(shotId);
      expect(revisions, hasLength(2));
      // 只有最新一条是 current。
      expect(revisions.where((r) => r.state == 'current'), hasLength(1));
      expect(revisions.where((r) => r.state == 'superseded'), hasLength(1));
    });
  });
}
