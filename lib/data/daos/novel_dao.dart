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

  /// 列出所有书籍（跨项目），供书架页面使用。
  Future<List<NovelBook>> listAllBooks() {
    return (select(novelBooks)
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
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

  /// 获取书籍详情：章节总数和总字数。
  Future<({int chapterCount, int wordCount})> getBookStats(int bookId) async {
    final chapters = await listChapters(bookId);
    return (
      chapterCount: chapters.length,
      wordCount: chapters.fold(0, (sum, c) => sum + c.wordCount),
    );
  }

  /// 按项目分组列出书籍。
  Future<Map<int, List<NovelBook>>> listBooksGroupedByProject() async {
    final allBooks = await listAllBooks();
    final grouped = <int, List<NovelBook>>{};
    for (final book in allBooks) {
      grouped.putIfAbsent(book.projectId, () => []).add(book);
    }
    return grouped;
  }

  /// 删除书籍及其所有章节。
  Future<void> deleteBook(int id) async {
    await (delete(chapters)..where((t) => t.bookId.equals(id))).go();
    await (delete(novelBooks)..where((t) => t.id.equals(id))).go();
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
