import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'character_relation_dao.g.dart';

/// 角色关系历史（M24 T25.2）。
///
/// 同一 `(bookId, source, target)` 每次确立新版本就追加一行，全量历史按
/// `createdAt` 升序读出来就是这对角色关系的完整演变。`CharacterSpec.relations`
/// 仍是当前快照的自由文本，两张表职责不同：TruthFile 存「现在是什么」，
/// 这张表存「曾经是哪些」。
///
/// 历史行的正文永不 UPDATE，只有 `isCurrent` 指针位可变——新版本落库时把同组
/// 旧行的 1 改为 0，与 `ShotRevisions` 的两态 current / superseded 同一语义。
@DriftAccessor(
  tables: [
    CharacterRelations,
    NovelBooks,
    Projects,
  ],
)
class CharacterRelationDao
    extends DatabaseAccessor<AppDatabase>
    with _$CharacterRelationDaoMixin {
  CharacterRelationDao(super.db);

  /// 确立一版关系：先撤下同组旧指针，再追加新行。
  ///
  /// 两步必须在一个事务里——只撤指针不写新行会让这对角色短暂没有当前关系，
  /// 只写新行不撤旧指针会让同一组出现两行 isCurrent = 1。
  Future<int> appendRelation({
    required int bookId,
    required String source,
    required String target,
    String description = '',
    int? chapterSeq,
  }) {
    return attachedDatabase.transaction(() async {
      await (update(characterRelations)
            ..where(
              (t) =>
                  t.bookId.equals(bookId) &
                  t.source.equals(source) &
                  t.target.equals(target) &
                  t.isCurrent.equals(1),
            ))
          .write(const CharacterRelationsCompanion(isCurrent: Value(0)));
      return into(characterRelations).insert(
        CharacterRelationsCompanion.insert(
          bookId: bookId,
          source: source,
          target: target,
          description: Value(description),
          isCurrent: const Value(1),
          chapterSeq: Value(chapterSeq),
        ),
      );
    });
  }

  /// 某作品的全量关系历史，最新在前。
  Future<List<CharacterRelation>> listByBook(int bookId) async {
    final query = select(characterRelations)
      ..where((t) => t.bookId.equals(bookId));
    query.orderBy([
      (t) => OrderingTerm.desc(t.createdAt),
      (t) => OrderingTerm.desc(t.id),
    ]);
    return query.get();
  }

  /// 某角色当前有效的全部出边。
  Future<List<CharacterRelation>> currentOf(int bookId, String source) async {
    final query = select(characterRelations)
      ..where(
        (t) =>
            t.bookId.equals(bookId) &
            t.source.equals(source) &
            t.isCurrent.equals(1),
      );
    query.orderBy([(t) => OrderingTerm.asc(t.target)]);
    return query.get();
  }

  /// 某作品当前有效的全部关系边，关系图谱的数据源。
  Future<List<CharacterRelation>> currentEdges(int bookId) async {
    final query = select(characterRelations)
      ..where((t) => t.bookId.equals(bookId) & t.isCurrent.equals(1));
    query.orderBy([
      (t) => OrderingTerm.asc(t.source),
      (t) => OrderingTerm.asc(t.target),
    ]);
    return query.get();
  }

  /// 关系历史条数，UI 显示空态用。
  Future<int> countByBook(int bookId) async {
    final rows =
        await (select(characterRelations)..where((t) => t.bookId.equals(bookId)))
            .get();
    return rows.length;
  }

  /// 作品删除时清理其关系历史。
  Future<void> deleteByBook(int bookId) {
    return (delete(characterRelations)..where((t) => t.bookId.equals(bookId)))
        .go();
  }

  /// 作品所属项目 id（作品 → 项目）。作品不存在返回 null。
  Future<int?> projectOfBook(int bookId) async {
    final book =
        await (select(novelBooks)..where((t) => t.id.equals(bookId)))
            .getSingleOrNull();
    return book?.projectId;
  }
}
