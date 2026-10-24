import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'reading_progress_dao.g.dart';

/// 阅读进度数据访问对象。
@DriftAccessor(tables: [ReadingProgresses])
class ReadingProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingProgressDaoMixin {
  ReadingProgressDao(super.db);

  /// 获取某本书的阅读进度。
  Future<ReadingProgress?> findByBook(int bookId) {
    return (select(readingProgresses)
          ..where((t) => t.bookId.equals(bookId)))
        .getSingleOrNull();
  }

  /// 保存阅读进度（有则更新，无则插入）。
  Future<int> save(int bookId, int chapterSeq, int? chapterId) async {
    final existing = await findByBook(bookId);
    if (existing == null) {
      return into(readingProgresses).insert(
        ReadingProgressesCompanion(
          bookId: Value(bookId),
          chapterSeq: Value(chapterSeq),
          chapterId: Value(chapterId),
        ),
      );
    }
    await (update(readingProgresses)
          ..where((t) => t.bookId.equals(bookId)))
        .write(
          ReadingProgressesCompanion(
            chapterSeq: Value(chapterSeq),
            chapterId: Value(chapterId),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return existing.id;
  }

  /// 获取所有书籍的阅读进度。
  Future<Map<int, ReadingProgress>> findAll() async {
    final rows = await (select(readingProgresses)).get();
    final result = <int, ReadingProgress>{};
    for (final row in rows) {
      result[row.bookId] = row;
    }
    return result;
  }

  /// 删除某本书的阅读进度。
  Future<int> deleteByBook(int bookId) {
    return (delete(readingProgresses)..where((t) => t.bookId.equals(bookId))).go();
  }
}
