import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'novel_dao.g.dart';

/// 小说书与章节数据访问对象。
@DriftAccessor(tables: [NovelBooks, Chapters])
class NovelDao extends DatabaseAccessor<AppDatabase> with _$NovelDaoMixin {
  NovelDao(super.db);

  // ---- 小说书 ----

  Future<NovelBook?> findBookByProject(int projectId) {
    return (select(
      novelBooks,
    )..where((t) => t.projectId.equals(projectId))).getSingleOrNull();
  }

  /// 一个项目下的全部书。`NovelBooks.projectId` 无唯一约束，允许一个项目
  /// 下多本书，全量取用避免只取第一本后静默丢弃其余。
  Future<List<NovelBook>> listBooksByProject(int projectId) {
    return (select(novelBooks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Stream<List<NovelBook>> watchAllBooks() {
    return (select(novelBooks)
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  Stream<NovelBook?> watchBookByProject(int projectId) {
    return (select(
      novelBooks,
    )..where((t) => t.projectId.equals(projectId))).watchSingleOrNull();
  }

  Future<NovelBook?> findBook(int id) {
    return (select(
      novelBooks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<NovelBook?> watchBookById(int id) {
    return (select(
      novelBooks,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// 一次聚合查询获取全部书籍的章节数与总字数（书架页加载用）。
  /// 避免 N 本书 N 次串行查询；空书（无章节）按 0/0 计。
  Future<Map<int, ({int chapterCount, int wordCount})>> getAllBookStats() async {
    final countExpr = chapters.id.count();
    final wordExpr = chapters.wordCount.sum();
    final query = selectOnly(chapters)
      ..addColumns([chapters.bookId, countExpr, wordExpr])
      ..groupBy([chapters.bookId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(chapters.bookId)!: (
          chapterCount: row.read(countExpr) ?? 0,
          wordCount: row.read(wordExpr) ?? 0,
        ),
    };
  }

  Future<int> insertBook(NovelBooksCompanion entry) {
    return into(novelBooks).insert(entry);
  }

  Future<bool> updateBook(NovelBook row) {
    return update(novelBooks).replace(row);
  }

  // ---- 章节 ----

  Future<List<Chapter>> listChapters(int bookId) {
    return (select(chapters)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
  }

  Stream<List<Chapter>> watchChapters(int bookId) {
    return (select(chapters)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .watch();
  }

  Future<Chapter?> findChapter(int id) {
    return (select(chapters)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Chapter?> watchChapter(int id) {
    return (select(
      chapters,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insertChapter(ChaptersCompanion entry) {
    return into(chapters).insert(entry);
  }

  Future<bool> updateChapter(Chapter row) {
    return update(chapters).replace(row);
  }

  Future<int> deleteChapter(int id) {
    return (delete(chapters)..where((t) => t.id.equals(id))).go();
  }

  /// 当前书的最大章节序号（下一章 = maxSeq + 1）。
  Future<int> maxSeq(int bookId) async {
    final max = chapters.seq.max();
    final query = selectOnly(chapters)
      ..addColumns([max])
      ..where(chapters.bookId.equals(bookId));
    final row = await query.getSingle();
    return row.read(max) ?? 0;
  }
}
