import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'script_revision_dao.g.dart';

/// 剧本版本快照数据访问对象。
@DriftAccessor(tables: [ScriptRevisions])
class ScriptRevisionDao extends DatabaseAccessor<AppDatabase>
    with _$ScriptRevisionDaoMixin {
  ScriptRevisionDao(super.db);

  Future<List<ScriptRevision>> listByScript(int scriptId) {
    return (select(scriptRevisions)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([(t) => OrderingTerm.desc(t.version)]))
        .get();
  }

  Future<ScriptRevision?> findByVersion(int scriptId, int version) {
    return (select(scriptRevisions)..where(
          (t) => t.scriptId.equals(scriptId) & t.version.equals(version),
        ))
        .getSingleOrNull();
  }

  Future<int> insert(ScriptRevisionsCompanion entry) {
    return into(scriptRevisions).insert(entry);
  }
}
