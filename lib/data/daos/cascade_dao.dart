import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';
import 'generation_attempt_dao.dart';

part 'cascade_dao.g.dart';

/// 级联删除访问对象：所有「按父 id 清理整棵子树」的复合写操作集中在此，统一内置事务。
///
/// 删除按外键依赖的拓扑序（最下游先行）：
/// ShotRevisions → GenerationAttempts → ChapterRevisions → ShotFrames → AssetRefs
///   → VideoTasks → Beats → Scenes → Shots → Assets → AssetRevisions
///   → ScriptRevisions → Scripts → TruthFiles → Chapters → NovelBooks → Projects
///
/// PromptOverrides / PromptOverrideVersions / GateLogs 与 GenerationAttempts
/// 同层：只按 projectId 归属项目、互不引用，谁先删都可以。
/// CharacterRelations 按 bookId 归属作品，随 _deleteBookSubtree 一起清理。
///
/// 业务层不得自行拼 `deleteByX` + 多次 `insert`，一律调用本 DAO 的复合方法；
/// 复合方法内部开启事务，中间任一步失败整段回滚，不留中间态。
@DriftAccessor(
  tables: [
    Projects,
    NovelBooks,
    Chapters,
    ChapterRevisions,
    TruthFiles,
    Scripts,
    ScriptRevisions,
    Scenes,
    Beats,
    Assets,
    Shots,
    ShotFrames,
    AssetRefs,
    VideoTasks,
    ShotRevisions,
    AssetRevisions,
    GenerationAttempts,
    PromptOverrides,
    PromptOverrideVersions,
    CharacterRelations,
    GateLogs,
  ],
)
class CascadeDao extends DatabaseAccessor<AppDatabase> with _$CascadeDaoMixin {
  CascadeDao(super.db);

  /// 删除整个项目及其全部下游数据。
  Future<void> deleteProjectCascade(int projectId) async {
    await attachedDatabase.transaction(() async {
      final books = await (select(
        novelBooks,
      )..where((t) => t.projectId.equals(projectId))).get();
      for (final book in books) {
        await _deleteBookSubtree(book.id);
      }
      // 生成尝试台账按项目归属清理（subjectId 可能指向已删除对象）。
      await (delete(
        generationAttempts,
      )..where((t) => t.projectId.equals(projectId))).go();
      // 项目级提示词覆盖随项目清理；scope='global' 的行 projectId 为 null，
      // 谓词天然排除，不重复删除。
      await (delete(
        promptOverrides,
      )..where((t) => t.projectId.equals(projectId))).go();
      // 覆盖的历史版本同一归属规则：清掉项目级的存档，全局级的保留。
      await (delete(
        promptOverrideVersions,
      )..where((t) => t.projectId.equals(projectId))).go();
      // 质量门日志同一归属规则：清掉项目级的记录，projectId 为空的全局记录保留。
      await (delete(
        gateLogs,
      )..where((t) => t.projectId.equals(projectId))).go();
      await (delete(projects)..where((t) => t.id.equals(projectId))).go();
    });
  }

  /// 删除整本书及其剧本链路。
  Future<void> deleteBookCascade(int bookId) async {
    await attachedDatabase.transaction(() => _deleteBookSubtree(bookId));
  }

  /// 删除章节及其版本快照。
  Future<void> deleteChapterCascade(int chapterId) async {
    await attachedDatabase.transaction(() async {
      await (delete(
        chapterRevisions,
      )..where((t) => t.chapterId.equals(chapterId))).go();
      await (delete(chapters)..where((t) => t.id.equals(chapterId))).go();
    });
  }

  /// 删除剧本及其场次 / 节拍 / 资产 / 镜头链路。
  Future<void> deleteScriptCascade(int scriptId) async {
    await attachedDatabase.transaction(() => _deleteScriptSubtree(scriptId));
  }

  /// 删除镜头及其帧 / 参考 / 视频任务。
  Future<void> deleteShotCascade(int shotId) async {
    await attachedDatabase.transaction(() => _deleteShotSubtree(shotId));
  }

  /// 删除资产及其参考引用 / 版本快照 / 生成台账。
  ///
  /// 必须一并删 `assetRevisions`：该表有指向 Assets 的外键，而库已开
  /// `PRAGMA foreign_keys=ON`，只删 assets 会让任何出过图的资产
  /// `deleteAssetCascade` 直接抛约束冲突。台账无外键但按逻辑归属一并清理。
  Future<void> deleteAssetCascade(int assetId) async {
    await attachedDatabase.transaction(() async {
      await (delete(
        assetRevisions,
      )..where((t) => t.assetId.equals(assetId))).go();
      await (delete(assetRefs)..where((t) => t.assetId.equals(assetId))).go();
      await (delete(generationAttempts)..where(
            (t) =>
                t.subjectId.equals(assetId) &
                t.subjectType.equals(AttemptSubjects.assetImage),
          ))
          .go();
      await (delete(assets)..where((t) => t.id.equals(assetId))).go();
    });
  }

  /// 删除剧本下全部场次（含节拍）：重新改编剧本前调用。
  Future<void> deleteScenesCascade(int scriptId) async {
    await attachedDatabase.transaction(() async {
      await _deleteBeatsOfScript(scriptId);
      await (delete(scenes)..where((t) => t.scriptId.equals(scriptId))).go();
    });
  }

  /// 删除剧本下全部骨架产物（镜头链路 + 节拍）：重新提取骨架前调用。
  Future<void> deleteSkeletonCascade(int scriptId) async {
    await attachedDatabase.transaction(() async {
      await _deleteShotSubtreesByScript(scriptId);
      await _deleteBeatsOfScript(scriptId);
    });
  }

  // ---- 子树内部实现（调用方已处于事务内，可嵌套） ----

  Future<void> _deleteBookSubtree(int bookId) async {
    final rows = await (select(
      scripts,
    )..where((t) => t.bookId.equals(bookId))).get();
    for (final script in rows) {
      await _deleteScriptSubtree(script.id);
    }
    await (delete(truthFiles)..where((t) => t.bookId.equals(bookId))).go();
    // 角色关系历史按 bookId 归属，随作品一起清理；当前快照在 TruthFiles 里已删。
    await (delete(characterRelations)
          ..where((t) => t.bookId.equals(bookId)))
        .go();
    await _deleteChaptersOfBook(bookId);
    await (delete(novelBooks)..where((t) => t.id.equals(bookId))).go();
  }

  /// 删除书下全部章节及其版本快照。
  Future<void> _deleteChaptersOfBook(int bookId) async {
    final rows = await (select(
      chapters,
    )..where((t) => t.bookId.equals(bookId))).get();
    for (final chapter in rows) {
      await (delete(
        chapterRevisions,
      )..where((t) => t.chapterId.equals(chapter.id))).go();
    }
    await (delete(chapters)..where((t) => t.bookId.equals(bookId))).go();
  }

  Future<void> _deleteScriptSubtree(int scriptId) async {
    await _deleteShotSubtreesByScript(scriptId);
    await _deleteAssetsOfScript(scriptId);
    await _deleteBeatsOfScript(scriptId);
    await (delete(scenes)..where((t) => t.scriptId.equals(scriptId))).go();
    await (delete(
      scriptRevisions,
    )..where((t) => t.scriptId.equals(scriptId))).go();
    // 脚本级台账（subjectId=scriptId）随剧本删除；改编 / 骨架提取 / 导演 /
    // 资产提取的历史审计一并清理，避免留孤儿行。
    await (delete(generationAttempts)..where(
          (t) =>
              t.subjectId.equals(scriptId) &
              t.subjectType.isIn([
                AttemptSubjects.scriptAdapt,
                AttemptSubjects.skeletonExtract,
                AttemptSubjects.shotDirection,
                AttemptSubjects.assetExtract,
              ]),
        ))
        .go();
    await (delete(scripts)..where((t) => t.id.equals(scriptId))).go();
  }

  Future<void> _deleteShotSubtree(int shotId) async {
    await _deleteRevisionsForShot(shotId);
    await (delete(videoTasks)..where((t) => t.shotId.equals(shotId))).go();
    await (delete(assetRefs)..where((t) => t.shotId.equals(shotId))).go();
    await (delete(shotFrames)..where((t) => t.shotId.equals(shotId))).go();
    await (delete(shots)..where((t) => t.id.equals(shotId))).go();
  }

  /// 删除剧本下全部镜头及其帧 / 参考 / 视频任务。
  Future<void> _deleteShotSubtreesByScript(int scriptId) async {
    final shotIds = selectOnly(shots)
      ..addColumns([shots.id])
      ..where(shots.scriptId.equals(scriptId));
    await (delete(
      shotRevisions,
    )..where((t) => t.shotId.isInQuery(shotIds))).go();
    // 镜头级台账（subjectId=shotId）随镜头删除；脚本级台账
    // （skeleton_extract / shot_direction，subjectId=scriptId）由
    // _deleteScriptSubtree 单独按 scriptId 清理，不能混进 shotIds 过滤。
    await (delete(generationAttempts)..where(
          (t) =>
              t.subjectId.isInQuery(shotIds) &
              t.subjectType.isIn([
                AttemptSubjects.shotImage,
                AttemptSubjects.shotVideo,
              ]),
        ))
        .go();
    await (delete(videoTasks)..where((t) => t.shotId.isInQuery(shotIds))).go();
    await (delete(assetRefs)..where((t) => t.shotId.isInQuery(shotIds))).go();
    await (delete(shotFrames)..where((t) => t.shotId.isInQuery(shotIds))).go();
    await (delete(shots)..where((t) => t.scriptId.equals(scriptId))).go();
  }

  Future<void> _deleteAssetsOfScript(int scriptId) async {
    final assetIds = selectOnly(assets)
      ..addColumns([assets.id])
      ..where(assets.scriptId.equals(scriptId));
    await (delete(assetRevisions)..where(
          (t) => t.assetId.isInQuery(assetIds),
        ))
        .go();
    // 资产级台账（subjectId=assetId）须在删 assets 之前清理：删后再查 assets
    // 子查询恒空，台账会永远残留。asset_extract（subjectId=scriptId）由
    // _deleteScriptSubtree 单独清理。
    await (delete(generationAttempts)..where(
          (t) =>
              t.subjectId.isInQuery(assetIds) &
              t.subjectType.equals(AttemptSubjects.assetImage),
        ))
        .go();
    await (delete(assets)..where((t) => t.scriptId.equals(scriptId))).go();
  }

  Future<void> _deleteRevisionsForShot(int shotId) {
    return (delete(shotRevisions)..where((t) => t.shotId.equals(shotId))).go();
  }

  /// 删除剧本下全部场次对应的节拍。
  Future<void> _deleteBeatsOfScript(int scriptId) async {
    final sceneIds = selectOnly(scenes)
      ..addColumns([scenes.id])
      ..where(scenes.scriptId.equals(scriptId));
    await (delete(beats)..where((t) => t.sceneId.isInQuery(sceneIds))).go();
  }
}
