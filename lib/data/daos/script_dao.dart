import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'script_dao.g.dart';

/// 剧本数据访问对象。
@DriftAccessor(tables: [Scripts])
class ScriptDao extends DatabaseAccessor<AppDatabase> with _$ScriptDaoMixin {
  ScriptDao(super.db);

  Future<List<Script>> listByBook(int bookId) {
    return (select(scripts)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.desc(t.version)]))
        .get();
  }

  Stream<List<Script>> watchByBook(int bookId) {
    return (select(scripts)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.desc(t.version)]))
        .watch();
  }

  Future<Script?> find(int id) {
    return (select(scripts)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Script?> watch(int id) {
    return (select(scripts)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insert(ScriptsCompanion entry) {
    return into(scripts).insert(entry);
  }

  Future<bool> updateRow(Script row) {
    return update(scripts).replace(row);
  }

  Future<int> deleteById(int id) {
    return (delete(scripts)..where((t) => t.id.equals(id))).go();
  }
}
