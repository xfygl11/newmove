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

  /// 存档旧正文并把章节正文替换为 [content]（含字数与修订号推进），两步同一事务。
  ///
  /// 版本历史里的「恢复」走这里。不允许业务层自己先 `insert` 快照再
  /// `updateChapter`：中间态会让用户在事后看到「快照已存、正文没换」的
  /// 孤儿版本，或「正文换了、旧正文丢了」的不可恢复章节。
  Future<void> snapshotAndReplace({
    required Chapter chapter,
    required String content,
    required int wordCount,
  }) {
    return attachedDatabase.transaction(() async {
      await into(chapterRevisions).insert(
        ChapterRevisionsCompanion.insert(
          chapterId: chapter.id,
          revision: chapter.revision,
          content: Value(chapter.content),
        ),
      );
      await (update(attachedDatabase.chapters)
            ..where((t) => t.id.equals(chapter.id)))
          .write(
        ChaptersCompanion(
          content: Value(content),
          wordCount: Value(wordCount),
          revision: Value(chapter.revision + 1),
        ),
      );
    });
  }
}
