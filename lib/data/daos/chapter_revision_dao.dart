import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'chapter_revision_dao.g.dart';

/// 章节版本快照数据访问对象。
@DriftAccessor(tables: [ChapterRevisions])
class ChapterRevisionDao extends DatabaseAccessor<AppDatabase>
    with _$ChapterRevisionDaoMixin {
  ChapterRevisionDao(super.db);

  Future<int> insert(ChapterRevisionsCompanion entry) {
    return into(chapterRevisions).insert(entry);
  }

  /// 按版本号倒序列出某章节的历史快照。
  Future<List<ChapterRevision>> listByChapter(int chapterId) {
    return (select(chapterRevisions)
          ..where((t) => t.chapterId.equals(chapterId))
          ..orderBy([(t) => OrderingTerm.desc(t.revision)]))
        .get();
  }
}
