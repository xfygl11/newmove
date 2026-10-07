import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/prompt_override_dao.dart';

/// 级联删除回归测试。
///
/// 背景：全库此前仅导入路径一处事务，`deleteProject` 是裸 delete 且 15 处外键
/// 全无 `onDelete`，删除任何创建过书籍的项目必然抛 `FOREIGN KEY constraint failed`。
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// 一条完整链路：项目 → 书 → 章节(+版本) → 真相状态 → 剧本 → 场次 → 节拍
  ///   → 资产 → 参考 → 镜头 → 帧 → 视频任务。
  Future<({int project, int book, int chapter, int script, int scene, int asset, int shot})>
      seedFullChain() async {
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '测试书'),
    );
    final chapterId = await db.novelDao.insertChapter(
      ChaptersCompanion.insert(bookId: bookId, seq: 1, title: '第一章'),
    );
    await db.chapterRevisionDao.insert(
      ChapterRevisionsCompanion.insert(
        chapterId: chapterId,
        revision: 1,
        content: const Value('旧正文'),
      ),
    );
    await db.truthFileDao.upsert(
      TruthFilesCompanion.insert(bookId: bookId, kind: '世界事实'),
    );
    final scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(bookId: bookId, title: '剧本A'),
    );
    final sceneId = await db.sceneDao.insert(
      ScenesCompanion.insert(
        scriptId: scriptId,
        seq: 1,
        location: '废墟',
        time: '日',
      ),
    );
    await db.beatDao.insert(
      BeatsCompanion.insert(
        sceneId: sceneId,
        seq: 1,
        type: '动作',
        content: '少年冲入废墟',
        sourceRef: 'E1',
      ),
    );
    final assetId = await db.assetDao.insert(
      AssetsCompanion.insert(
        scriptId: scriptId,
        type: '角色',
        name: '少年',
        stableId: 'c1',
      ),
    );
    final shotId = await db.shotDao.insert(
      ShotsCompanion.insert(
        scriptId: scriptId,
        globalSeq: 'G01',
        globalTimeRange: '00:00-00:05',
      ),
    );
    await db.shotFrameDao.insert(
      ShotFramesCompanion.insert(
        shotId: shotId,
        seq: 1,
        timeRange: '00:00-00:05',
        subject: '少年',
        shotSize: '特写',
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
      VideoTasksCompanion.insert(shotId: shotId, taskId: 'tk-1', providerId: 'p1'),
    );
    return (
      project: projectId,
      book: bookId,
      chapter: chapterId,
      script: scriptId,
      scene: sceneId,
      asset: assetId,
      shot: shotId,
    );
  }

  Future<void> expectAllEmpty() async {
    expect((await db.select(db.projects).get()).length, 0);
    expect((await db.select(db.novelBooks).get()).length, 0);
    expect((await db.select(db.chapters).get()).length, 0);
    expect((await db.select(db.chapterRevisions).get()).length, 0);
    expect((await db.select(db.truthFiles).get()).length, 0);
    expect((await db.select(db.scripts).get()).length, 0);
    expect((await db.select(db.scriptRevisions).get()).length, 0);
    expect((await db.select(db.scenes).get()).length, 0);
    expect((await db.select(db.beats).get()).length, 0);
    expect((await db.select(db.assets).get()).length, 0);
    expect((await db.select(db.shots).get()).length, 0);
    expect((await db.select(db.shotFrames).get()).length, 0);
    expect((await db.select(db.assetRefs).get()).length, 0);
    expect((await db.select(db.videoTasks).get()).length, 0);
  }

  Future<int> chapterId() async {
    return (await db.select(db.chapters).get()).single.id;
  }

  group('CascadeDao', () {
    test('外键约束在测试库中生效（否则下列用例无意义）', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 'P'),
      );
      final bookId = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(projectId: projectId, title: 'B'),
      );
      final scriptId = await db.scriptDao.insert(
        ScriptsCompanion.insert(bookId: bookId, title: 'S'),
      );
      await db.sceneDao.insert(
        ScenesCompanion.insert(
          scriptId: scriptId,
          seq: 1,
          location: 'x',
          time: '日',
        ),
      );

      await expectLater(
        db.beatDao.insert(
          BeatsCompanion.insert(
            sceneId: 999999,
            seq: 1,
            type: '动作',
            content: '孤立节拍',
            sourceRef: 'E1',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('级联删除项目清理全部 14 张下游表', () async {
      final chain = await seedFullChain();

      await db.cascadeDao.deleteProjectCascade(chain.project);

      await expectAllEmpty();
    });

    test('级联删除项目清项目级提示词覆盖，保留全局级', () async {
      final chain = await seedFullChain();
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.project,
        key: 'novel/writing.md',
        text: '项目覆盖',
        projectId: chain.project,
      );
      await db.promptOverrideDao.upsert(
        scope: PromptOverrideScopes.global,
        key: 'novel/writing.md',
        text: '全局覆盖',
      );

      await db.cascadeDao.deleteProjectCascade(chain.project);

      final rows = await db.select(db.promptOverrides).get();
      expect(rows, hasLength(1));
      expect(rows.single.scope, PromptOverrideScopes.global);
    });

    test('级联删除章节同时清理版本快照', () async {
      await seedFullChain();

      await db.cascadeDao.deleteChapterCascade(await chapterId());

      expect((await db.select(db.chapters).get()).length, 0);
      expect((await db.select(db.chapterRevisions).get()).length, 0);
    });

    test('级联删除剧本清理场次/节拍/资产/镜头链路，保留上游', () async {
      final chain = await seedFullChain();

      await db.cascadeDao.deleteScriptCascade(chain.script);

      expect((await db.select(db.scenes).get()).length, 0);
      expect((await db.select(db.beats).get()).length, 0);
      expect((await db.select(db.assets).get()).length, 0);
      expect((await db.select(db.shots).get()).length, 0);
      expect((await db.select(db.shotFrames).get()).length, 0);
      expect((await db.select(db.assetRefs).get()).length, 0);
      expect((await db.select(db.videoTasks).get()).length, 0);
      expect((await db.select(db.scripts).get()).length, 0);
      expect((await db.select(db.projects).get()).length, 1);
      expect((await db.select(db.novelBooks).get()).length, 1);
      expect((await db.select(db.chapters).get()).length, 1);
    });

    test('级联删除剧本清理 script/shot/asset 三级台账，不误删他剧本', () async {
      final chain = await seedFullChain();
      Future<int> attempt(String type, int? subjectId) =>
          db.generationAttemptDao.insert(
            GenerationAttemptsCompanion.insert(
              subjectType: type,
              subjectId: Value(subjectId),
              prompt: 'p',
            ),
          );
      // 脚本级（subjectId=scriptId）：改编 / 骨架 / 导演 / 资产提取。
      await attempt('script_adapt', chain.script);
      await attempt('skeleton_extract', chain.script);
      await attempt('shot_direction', chain.script);
      await attempt('asset_extract', chain.script);
      // 镜头级（subjectId=shotId）。
      await attempt('shot_image', chain.shot);
      await attempt('shot_video', chain.shot);
      // 资产级（subjectId=assetId）。
      await attempt('asset_image', chain.asset);
      // 指向他剧本镜头的台账不应被误删。
      await attempt('shot_image', 999999);

      await db.cascadeDao.deleteScriptCascade(chain.script);

      final rows = await db.select(db.generationAttempts).get();
      expect(rows, hasLength(1));
      expect(rows.single.subjectType, 'shot_image');
      expect(rows.single.subjectId, 999999);
    });

    test('骨架重提取保留 skeleton_extract 台账历史', () async {
      final chain = await seedFullChain();
      await db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          subjectType: 'skeleton_extract',
          subjectId: Value(chain.script),
          prompt: 'p',
        ),
      );
      await db.generationAttemptDao.insert(
        GenerationAttemptsCompanion.insert(
          subjectType: 'shot_image',
          subjectId: Value(chain.shot),
          prompt: 'p',
        ),
      );

      await db.cascadeDao.deleteSkeletonCascade(chain.script);

      final rows = await db.select(db.generationAttempts).get();
      // 镜头级台账随旧镜头清理；脚本级提取历史保留供审计。
      expect(rows, hasLength(1));
      expect(rows.single.subjectType, 'skeleton_extract');
    });

    test('已有帧/参考/视频任务的镜头可被删除', () async {
      final chain = await seedFullChain();

      await db.cascadeDao.deleteShotCascade(chain.shot);

      expect((await db.select(db.shots).get()).length, 0);
      expect((await db.select(db.shotFrames).get()).length, 0);
      expect((await db.select(db.assetRefs).get()).length, 0);
      expect((await db.select(db.videoTasks).get()).length, 0);
      expect((await db.select(db.scripts).get()).length, 1);
    });

    test('删除剧本场次时连带清理节拍（重新改编前）', () async {
      final chain = await seedFullChain();

      await db.cascadeDao.deleteScenesCascade(chain.script);

      expect((await db.select(db.scenes).get()).length, 0);
      expect((await db.select(db.beats).get()).length, 0);
      expect((await db.select(db.scripts).get()).length, 1);
      expect((await db.select(db.shots).get()).length, 1);
    });

    test('删除骨架产物时连带清理镜头下游，保留场次（重新提取前）', () async {
      final chain = await seedFullChain();

      await db.cascadeDao.deleteSkeletonCascade(chain.script);

      expect((await db.select(db.shots).get()).length, 0);
      expect((await db.select(db.shotFrames).get()).length, 0);
      expect((await db.select(db.assetRefs).get()).length, 0);
      expect((await db.select(db.videoTasks).get()).length, 0);
      expect((await db.select(db.beats).get()).length, 0);
      expect((await db.select(db.scenes).get()).length, 1);
      expect((await db.select(db.assets).get()).length, 1);
    });

    test('删除资产时连带清理参考引用，保留镜头', () async {
      final chain = await seedFullChain();

      await db.cascadeDao.deleteAssetCascade(chain.asset);

      expect((await db.select(db.assets).get()).length, 0);
      expect((await db.select(db.assetRefs).get()).length, 0);
      expect((await db.select(db.shots).get()).length, 1);
      expect((await db.select(db.shotFrames).get()).length, 1);
    });

    test('删除整本书清理剧本链路', () async {
      final chain = await seedFullChain();

      await db.cascadeDao.deleteBookCascade(chain.book);

      expect((await db.select(db.novelBooks).get()).length, 0);
      expect((await db.select(db.chapters).get()).length, 0);
      expect((await db.select(db.chapterRevisions).get()).length, 0);
      expect((await db.select(db.truthFiles).get()).length, 0);
      expect((await db.select(db.scripts).get()).length, 0);
      expect((await db.select(db.scenes).get()).length, 0);
      expect((await db.select(db.beats).get()).length, 0);
      expect((await db.select(db.shots).get()).length, 0);
      expect((await db.select(db.assets).get()).length, 0);
      expect((await db.select(db.projects).get()).length, 1);
    });
  });
}
