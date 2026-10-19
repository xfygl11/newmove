import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'story_arc_dao.g.dart';

/// 故事弧线（M29，1.2 世界观侧）数据访问对象。
///
/// 弧线按 `bookId` 归属作品，四态 active / paused / completed / abandoned，
/// 节点 `ArcNodes` 记录「预估推进到哪一章」（targetSeq）与「实际落在哪一章」
/// （chapterId）。Settler 每章定稿后调用 [landNode] 把预估落到实际章节。
@DriftAccessor(tables: [StoryArcs, ArcNodes])
class StoryArcDao extends DatabaseAccessor<AppDatabase> with _$StoryArcDaoMixin {
  StoryArcDao(super.db);

  // ---- 弧线 ----

  Future<List<StoryArc>> listArcsByBook(int bookId) {
    final query = select(storyArcs)..where((t) => t.bookId.equals(bookId));
    query.orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  Future<StoryArc?> findArcById(int id) {
    return (select(storyArcs)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertArc(StoryArcsCompanion entry) => into(storyArcs).insert(entry);

  Future<void> updateArcById(int id, StoryArcsCompanion entry) async {
    await (update(storyArcs)..where((t) => t.id.equals(id))).write(entry);
  }

  /// 删除弧线及其全部节点（节点引用弧线外键，先删节点再删弧线）。
  Future<void> deleteArc(int arcId) async {
    await attachedDatabase.transaction(() async {
      await (delete(arcNodes)..where((t) => t.arcId.equals(arcId))).go();
      await (delete(storyArcs)..where((t) => t.id.equals(arcId))).go();
    });
  }

  // ---- 节点 ----

  Future<List<ArcNode>> listNodesByArc(int arcId) {
    final query = select(arcNodes)..where((t) => t.arcId.equals(arcId));
    query.orderBy([(t) => OrderingTerm.asc(t.targetSeq)]);
    return query.get();
  }

  Future<int> insertNode(ArcNodesCompanion entry) => into(arcNodes).insert(entry);

  Future<void> updateNodeById(int id, ArcNodesCompanion entry) async {
    await (update(arcNodes)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteNodeById(int id) async {
    await (delete(arcNodes)..where((t) => t.id.equals(id))).go();
  }

  /// 推进弧线节点：把预估 targetSeq 的节点落到实际章节 id（Settler 定稿后调用）。
  ///
  /// [targetSeq] 未命中任何节点时不报错——弧线可能还没有覆盖到本章的预估节点。
  Future<void> landNode({
    required int arcId,
    required int targetSeq,
    int? chapterId,
  }) async {
    await (update(arcNodes)..where(
      (t) => t.arcId.equals(arcId) & t.targetSeq.equals(targetSeq),
    )).write(ArcNodesCompanion(chapterId: Value(chapterId)));
  }
}
