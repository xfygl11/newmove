import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'truth_file_dao.g.dart';

/// 真相状态（TruthFiles）数据访问对象。
@DriftAccessor(tables: [TruthFiles])
class TruthFileDao extends DatabaseAccessor<AppDatabase> with _$TruthFileDaoMixin {
  TruthFileDao(super.db);

  Future<List<TruthFile>> listByBook(int bookId) {
    return (select(truthFiles)..where((t) => t.bookId.equals(bookId))).get();
  }

  Stream<List<TruthFile>> watchByBook(int bookId) {
    return (select(truthFiles)..where((t) => t.bookId.equals(bookId))).watch();
  }

  Future<TruthFile?> findByKind(int bookId, String kind) {
    return (select(truthFiles)
          ..where((t) => t.bookId.equals(bookId) & t.kind.equals(kind)))
        .getSingleOrNull();
  }

  /// 存在则更新（按 bookId+kind 唯一约束），不存在则插入。
  Future<void> upsert(TruthFilesCompanion entry) async {
    final existing = await findByKind(entry.bookId.value, entry.kind.value);
    if (existing == null) {
      await into(truthFiles).insert(entry);
      return;
    }
    await (update(truthFiles)..where((t) => t.id.equals(existing.id)))
        .write(entry);
  }
}
