import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/generation_attempt_dao.dart';
import 'package:newmove/features/novel/truth_file_kinds.dart';
import 'package:newmove/features/novel/truth_file_store.dart';

void main() {
  late AppDatabase db;
  late int projectId;
  late int scriptId;
  late int shotId;
  late int assetId;
  late int bookId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '测试书'),
    );
    scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(bookId: bookId, title: '测试剧本'),
    );
    shotId = await db.shotDao.insert(
      ShotsCompanion.insert(
        scriptId: scriptId,
        globalSeq: 'G01',
        globalTimeRange: '00:00-00:05',
      ),
    );
    assetId = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: '角色',
        name: '主角',
        stableId: 'hero',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('RevisionDao', () {
    test('saveShot 递增 revision', () async {
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );

      final rows = await db.revisionDao.listShots(shotId);
      expect(rows, hasLength(3));
      expect(rows.first.revision, 3);
      expect(rows.last.revision, 1);
    });

    test('同一 kind 至多一条 current', () async {
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );

      final rows = await db.revisionDao.listShots(shotId);
      expect(rows.where((r) => r.state == 'current').length, 1);
      expect(rows.where((r) => r.state == 'superseded').length, 1);
    });

    test('不同 kind 各自维护 current', () async {
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'image',
        snapshot: '{}',
      );
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );

      final rows = await db.revisionDao.listShots(shotId);
      final currentKinds = rows
          .where((r) => r.state == 'current')
          .map((r) => r.kind)
          .toList();
      expect(currentKinds.toSet(), {'direction', 'image'});
    });

    test('saveAsset 递增 revision 并降级旧 current', () async {
      await db.revisionDao.saveAsset(
        assetId: assetId,
        kind: 'image',
        snapshot: '{}',
      );
      await db.revisionDao.saveAsset(
        assetId: assetId,
        kind: 'image',
        snapshot: '{}',
      );

      final rows = await db.revisionDao.listAssets(assetId);
      expect(rows.first.revision, 2);
      expect(rows.first.state, 'current');
      expect(rows.last.state, 'superseded');
    });

    test('deleteShots / deleteAssets 清理快照', () async {
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );
      await db.revisionDao.saveAsset(
        assetId: assetId,
        kind: 'image',
        snapshot: '{}',
      );

      await db.revisionDao.deleteShots(shotId);
      await db.revisionDao.deleteAssets(assetId);

      expect(await db.revisionDao.listShots(shotId), isEmpty);
      expect(await db.revisionDao.listAssets(assetId), isEmpty);
    });
  });

  group('GenerationAttemptDao', () {
    test('nextAttemptNo 递增', () async {
      expect(
        await db.generationAttemptDao.nextAttemptNo('shot_image', shotId),
        1,
      );
      await db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          subjectType: 'shot_image',
          subjectId: Value(shotId),
          prompt: 'a',
        ),
      );
      await db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          subjectType: 'shot_image',
          subjectId: Value(shotId),
          prompt: 'b',
        ),
      );
      expect(
        await db.generationAttemptDao.nextAttemptNo('shot_image', shotId),
        3,
      );
    });

    test('finishAttempt 只回写状态三列', () async {
      final before = '原始提示词';
      final id = await db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          subjectType: 'shot_image',
          subjectId: Value(shotId),
          subjectLabel: Value('G01'),
          prompt: before,
          params: const Value('{"model":"m1"}'),
          status: const Value(AttemptStatuses.running),
        ),
      );
      await db.generationAttemptDao.finishAttempt(
        id: id,
        status: AttemptStatuses.succeeded,
        resultPath: '/tmp/out.png',
      );

      final rows = await db.generationAttemptDao.listBySubject(
        'shot_image',
        shotId,
      );
      expect(rows.single.status, AttemptStatuses.succeeded);
      expect(rows.single.resultPath, '/tmp/out.png');
      // 提示词与参数不被回写覆盖。
      expect(rows.single.prompt, before);
      expect(rows.single.params, '{"model":"m1"}');
    });

    test('finishAttempt 可补齐生成后确定的 subjectId', () async {
      final id = await db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          subjectType: 'script_adapt',
          subjectLabel: Value('待创建剧本'),
          prompt: '改编',
        ),
      );
      await db.generationAttemptDao.finishAttempt(
        id: id,
        status: AttemptStatuses.succeeded,
        subjectId: scriptId,
        subjectLabel: '新剧本',
      );

      final rows = await db.generationAttemptDao.listBySubject(
        'script_adapt',
        scriptId,
      );
      expect(rows.single.subjectId, scriptId);
      expect(rows.single.subjectLabel, '新剧本');
      expect(rows.single.prompt, '改编');
    });

    test('deleteByProject 清理台账', () async {
      await db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          projectId: Value(projectId),
          subjectType: 'shot_image',
          subjectId: Value(shotId),
          prompt: 'a',
        ),
      );
      await db.generationAttemptDao.deleteByProject(projectId);
      expect(
        await db.generationAttemptDao.listBySubject('shot_image', shotId),
        isEmpty,
      );
    });

    test('subjectId 为空时 attemptNo 恒为 1', () async {
      expect(
        await db.generationAttemptDao.nextAttemptNo('novel_plan', null),
        1,
      );
    });
  });

  group('TruthFileStore 乐观锁', () {
    test('expectedRevision 不匹配时抛冲突', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.currentFocus, {'text': 'a'});

      // 先读到 revision = 1，再被另一处改成 2，然后按旧 revision 写。
      await store.write(TruthFileKind.currentFocus, {'text': 'b'});
      await expectLater(
        store.write(TruthFileKind.currentFocus, {
          'text': 'c',
        }, expectedRevision: 1),
        throwsA(isA<ConcurrentWriteConflict>()),
      );

      final row = await db.truthFileDao.findByKind(
        bookId,
        TruthFileKind.currentFocus,
      );
      expect(row!.revision, 2);
    });

    test('expectedRevision 匹配时正常写入', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.currentFocus, {'text': 'a'});
      final row = await store.readRow(TruthFileKind.currentFocus);

      await store.write(TruthFileKind.currentFocus, {
        'text': 'b',
      }, expectedRevision: row!.revision);

      final after = await db.truthFileDao.findByKind(
        bookId,
        TruthFileKind.currentFocus,
      );
      expect(after!.revision, row.revision + 1);
    });
  });

  group('HookStates 状态机', () {
    test('合法前进', () {
      expect(HookStates.allows(null, HookStates.open), isTrue);
      expect(
        HookStates.allows(HookStates.open, HookStates.progressing),
        isTrue,
      );
      expect(HookStates.allows(HookStates.open, HookStates.resolved), isTrue);
      expect(
        HookStates.allows(HookStates.progressing, HookStates.resolved),
        isTrue,
      );
      expect(
        HookStates.allows(HookStates.deferred, HookStates.resolved),
        isTrue,
      );
    });

    test('禁止倒退', () {
      expect(
        HookStates.allows(HookStates.progressing, HookStates.open),
        isFalse,
      );
      expect(HookStates.allows(HookStates.deferred, HookStates.open), isFalse);
      expect(
        HookStates.allows(HookStates.deferred, HookStates.progressing),
        isFalse,
      );
    });

    test('终态不可变更', () {
      expect(HookStates.allows(HookStates.resolved, HookStates.open), isFalse);
      expect(
        HookStates.allows(HookStates.superseded, HookStates.progressing),
        isFalse,
      );
    });

    test('未知状态一律拒绝', () {
      expect(HookStates.allows(HookStates.open, 'archived'), isFalse);
      expect(HookStates.isValid(''), isFalse);
    });

    test('label 对未知状态原样返回', () {
      expect(HookStates.label(HookStates.open), '未闭合');
      expect(HookStates.label('archived'), 'archived');
    });
  });

  group('AssetDao variantOf 校验', () {
    test('父资产不存在时拒绝', () async {
      await expectLater(
        db.assetDao.insert(
          AssetsCompanion.insert(
            scriptId: scriptId,
            type: '角色',
            name: '变体',
            stableId: 'hero_v1',
            variantOf: Value(9999),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('跨剧本父资产拒绝', () async {
      final otherProject = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '另一项目'),
      );
      final otherBook = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(projectId: otherProject, title: '另一本书'),
      );
      final otherScript = await db.scriptDao.insert(
        ScriptsCompanion.insert(bookId: otherBook, title: '另一剧本'),
      );
      final otherAsset = await db.assetDao.insert(
        AssetsCompanion.insert(
          scriptId: otherScript,
          type: '角色',
          name: '他人主角',
          stableId: 'other_hero',
        ),
      );

      await expectLater(
        db.assetDao.insert(
          AssetsCompanion.insert(
            scriptId: scriptId,
            type: '角色',
            name: '跨剧本变体',
            stableId: 'hero_v2',
            variantOf: Value(otherAsset),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('同剧本父资产通过', () async {
      final variant = await db.assetDao.insert(
        AssetsCompanion.insert(
          scriptId: scriptId,
          type: '角色',
          name: '主角·变体',
          stableId: 'hero_v1',
          variantOf: Value(assetId),
        ),
      );
      expect(await db.assetDao.find(variant), isNotNull);
      expect((await db.assetDao.listVariants(assetId)).length, 1);
    });

    test('删除父资产时子变体解绑而非成为孤儿', () async {
      final variant = await db.assetDao.insert(
        AssetsCompanion.insert(
          scriptId: scriptId,
          type: '角色',
          name: '主角·变体',
          stableId: 'hero_v3',
          variantOf: Value(assetId),
        ),
      );
      await db.assetDao.deleteById(assetId);

      final orphan = await db.assetDao.find(variant);
      expect(orphan, isNotNull);
      expect(orphan!.variantOf, isNull);
    });
  });

  group('删除级联清理新表', () {
    test('deleteProjectCascade 清快照与台账', () async {
      await db.revisionDao.saveShot(
        shotId: shotId,
        kind: 'direction',
        snapshot: '{}',
      );
      await db.revisionDao.saveAsset(
        assetId: assetId,
        kind: 'image',
        snapshot: '{}',
      );
      await db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          projectId: Value(projectId),
          subjectType: 'shot_image',
          subjectId: Value(shotId),
          prompt: 'a',
        ),
      );

      await db.cascadeDao.deleteProjectCascade(projectId);

      expect(await db.revisionDao.listShots(shotId), isEmpty);
      expect(await db.revisionDao.listAssets(assetId), isEmpty);
      expect(
        await db.generationAttemptDao.listBySubject('shot_image', shotId),
        isEmpty,
      );
    });
  });
}
