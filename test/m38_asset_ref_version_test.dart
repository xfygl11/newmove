import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/asset_ref_dao.dart';

void main() {
  late AppDatabase db;
  late AssetRefDao dao;
  late int shotId;
  late int assetId1;
  late int assetId2;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.assetRefDao;

    // 创建项目、书籍、剧本、镜头、资产。
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
      ),
    );

    // 创建两个资产。
    assetId1 = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: 'character',
        name: '角色 A',
        stableId: 'char_a',
      ),
    );
    assetId2 = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: 'character',
        name: '角色 B',
        stableId: 'char_b',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AssetRefDao version/isActive（M38）', () {
    test('insert 带 version 和 isActive', () async {
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
          version: const Value(1),
          isActive: const Value(1),
        ),
      );

      final refs = await dao.listByShot(shotId);
      expect(refs, hasLength(1));
      expect(refs.single.version, 1);
      expect(refs.single.isActive, 1);
    });

    test('insert 不带 version 和 isActive 时落 null', () async {
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
        ),
      );

      final refs = await dao.listByShot(shotId);
      expect(refs, hasLength(1));
      expect(refs.single.version, isNull);
      expect(refs.single.isActive, isNull);
    });

    test('listByShotAndRole 按镜头 + 角色查询', () async {
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
          version: const Value(1),
        ),
      );
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId2,
          role: 'character',
          version: const Value(2),
        ),
      );
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'scene',
          version: const Value(1),
        ),
      );

      final charRefs = await dao.listByShotAndRole(shotId, 'character');
      expect(charRefs, hasLength(2));
      expect(charRefs.every((r) => r.role == 'character'), isTrue);

      final sceneRefs = await dao.listByShotAndRole(shotId, 'scene');
      expect(sceneRefs, hasLength(1));
    });

    test('listActiveByShot 只返回生效版本', () async {
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
          version: const Value(1),
          isActive: const Value(1),
        ),
      );
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId2,
          role: 'character',
          version: const Value(2),
          isActive: const Value(0),
        ),
      );
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'scene',
          version: const Value(1),
          isActive: const Value(1),
        ),
      );

      final activeRefs = await dao.listActiveByShot(shotId);
      expect(activeRefs, hasLength(2));
      expect(activeRefs.every((r) => r.isActive == 1 || r.isActive == null), isTrue);
    });

    test('listActiveByShot 空 isActive 视为生效', () async {
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
          version: const Value(1),
          // isActive 不传，落 null
        ),
      );
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId2,
          role: 'character',
          version: const Value(2),
          isActive: const Value(0),
        ),
      );

      final activeRefs = await dao.listActiveByShot(shotId);
      expect(activeRefs, hasLength(1));
      expect(activeRefs.single.isActive, isNull);
    });

    test('setActive 切换生效版本', () async {
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
          version: const Value(1),
          isActive: const Value(1),
        ),
      );
      final ref2 = await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId2,
          role: 'character',
          version: const Value(2),
          isActive: const Value(0),
        ),
      );

      // 切换到 ref2 生效。
      await dao.setActive(ref2);

      final refs = await dao.listByShotAndRole(shotId, 'character');
      expect(refs, hasLength(2));
      expect(refs.first.isActive, 0);
      expect(refs[1].isActive, 1);
    });

    test('setActive 同槽位只有一条生效', () async {
      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
          version: const Value(1),
          isActive: const Value(1),
        ),
      );
      final ref2 = await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId2,
          role: 'character',
          version: const Value(2),
          isActive: const Value(1), // 先设为生效
        ),
      );

      // 切换到 ref2（已经是生效，但确保只有一条）。
      await dao.setActive(ref2);

      final refs = await dao.listByShotAndRole(shotId, 'character');
      expect(refs.where((r) => r.isActive == 1), hasLength(1));
    });

    test('nextVersion 递增', () async {
      var v = await dao.nextVersion(shotId, 'character');
      expect(v, 1);

      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
          version: const Value(1),
        ),
      );

      v = await dao.nextVersion(shotId, 'character');
      expect(v, 2);

      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId2,
          role: 'character',
          version: const Value(2),
        ),
      );

      v = await dao.nextVersion(shotId, 'character');
      expect(v, 3);
    });

    test('nextVersion 不同 role 独立计数', () async {
      var vChar = await dao.nextVersion(shotId, 'character');
      expect(vChar, 1);

      var vScene = await dao.nextVersion(shotId, 'scene');
      expect(vScene, 1);

      await dao.insert(
        AssetRefsCompanion.insert(
          shotId: shotId,
          assetId: assetId1,
          role: 'character',
          version: const Value(1),
        ),
      );

      vChar = await dao.nextVersion(shotId, 'character');
      expect(vChar, 2);

      // scene 不受影响。
      vScene = await dao.nextVersion(shotId, 'scene');
      expect(vScene, 1);
    });
  });
}
