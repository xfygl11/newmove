import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'cascade_dao.g.dart';

/// 级联删除访问对象：所有「按父 id 清理整棵子树」的复合写操作集中在此，统一内置事务。
///
/// 删除按外键依赖的拓扑序（最下游先行）：
/// ChapterRevisions → ShotFrames → AssetRefs → VideoTasks → Beats → Scenes
///   → Shots → Assets → ScriptRevisions → Scripts → TruthFiles → Chapters → NovelBooks → Projects
///
/// 业务层不得自行拼 `deleteByX` + 多次 `insert`，一律调用本 DAO 的复合方法；
/// 复合方法内部开启事务，中间任一步失败整段回滚，不留中间态。
@DriftAccessor(tables: [
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
])
class CascadeDao extends DatabaseAccessor<AppDatabase> with _$CascadeDaoMixin {
  CascadeDao(super.db);

  /// 删除整个项目及其全部下游数据。
  Future<void> deleteProjectCascade(int projectId) async {
    await attachedDatabase.transaction(() async {
      final books = await (select(novelBooks)
            ..where((t) => t.projectId.equals(projectId)))
          .get();
      for (final book in books) {
        await _deleteBookSubtree(book.id);
      }
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
      await (delete(chapterRevisions)
            ..where((t) => t.chapterId.equals(chapterId)))
          .go();
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

  /// 删除资产及其参考引用。
  Future<void> deleteAssetCascade(int assetId) async {
    await attachedDatabase.transaction(() async {
      await (delete(assetRefs)..where((t) => t.assetId.equals(assetId))).go();
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
    final rows = await (select(scripts)
          ..where((t) => t.bookId.equals(bookId)))
        .get();
    for (final script in rows) {
      await _deleteScriptSubtree(script.id);
    }
    await (delete(truthFiles)..where((t) => t.bookId.equals(bookId))).go();
    await _deleteChaptersOfBook(bookId);
    await (delete(novelBooks)..where((t) => t.id.equals(bookId))).go();
  }

  /// 删除书下全部章节及其版本快照。
  Future<void> _deleteChaptersOfBook(int bookId) async {
    final rows = await (select(chapters)
          ..where((t) => t.bookId.equals(bookId)))
        .get();
    for (final chapter in rows) {
      await (delete(chapterRevisions)
            ..where((t) => t.chapterId.equals(chapter.id)))
          .go();
    }
    await (delete(chapters)..where((t) => t.bookId.equals(bookId))).go();
  }

  Future<void> _deleteScriptSubtree(int scriptId) async {
    await _deleteShotSubtreesByScript(scriptId);
    await _deleteBeatsOfScript(scriptId);
    await (delete(scenes)..where((t) => t.scriptId.equals(scriptId))).go();
    await (delete(assets)..where((t) => t.scriptId.equals(scriptId))).go();
    await (delete(scriptRevisions)
          ..where((t) => t.scriptId.equals(scriptId)))
        .go();
    await (delete(scripts)..where((t) => t.id.equals(scriptId))).go();
  }

  Future<void> _deleteShotSubtree(int shotId) async {
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
    await (delete(videoTasks)..where((t) => t.shotId.isInQuery(shotIds))).go();
    await (delete(assetRefs)..where((t) => t.shotId.isInQuery(shotIds))).go();
    await (delete(shotFrames)..where((t) => t.shotId.isInQuery(shotIds))).go();
    await (delete(shots)..where((t) => t.scriptId.equals(scriptId))).go();
  }

  /// 删除剧本下全部场次对应的节拍。
  Future<void> _deleteBeatsOfScript(int scriptId) async {
    final sceneIds = selectOnly(scenes)
      ..addColumns([scenes.id])
      ..where(scenes.scriptId.equals(scriptId));
    await (delete(beats)..where((t) => t.sceneId.isInQuery(sceneIds))).go();
  }
}
