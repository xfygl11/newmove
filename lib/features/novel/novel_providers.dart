import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'novel_agents.dart';
import 'novel_service.dart';

final novelAgentsProvider = Provider<NovelAgents>(
  (ref) => NovelAgents(
    adapter: ref.watch(llmProviderAdapterProvider),
    resolver: ref.watch(promptResolverProvider),
  ),
);

final novelServiceProvider = Provider<NovelService>(
  (ref) => NovelService(
    novelDao: ref.watch(novelDaoProvider),
    truthDao: ref.watch(truthFileDaoProvider),
    revisionDao: ref.watch(chapterRevisionDaoProvider),
    agents: ref.watch(novelAgentsProvider),
    attemptDao: ref.watch(generationAttemptDaoProvider),
    storyArcDao: ref.watch(storyArcDaoProvider),
  ),
);

/// 项目对应的书（无则 null）。
final novelBookByProjectProvider = StreamProvider.family<NovelBook?, int>(
  (ref, projectId) => ref.watch(novelDaoProvider).watchBookByProject(projectId),
);

/// 全部书籍（跨项目，按 id 倒序），书架页数据源。
final allBooksProvider = StreamProvider<List<NovelBook>>(
  (ref) => ref.watch(novelDaoProvider).watchAllBooks(),
);

/// 书的章节列表（序号升序）。
final chaptersByBookProvider = StreamProvider.family<List<Chapter>, int>(
  (ref, bookId) => ref.watch(novelDaoProvider).watchChapters(bookId),
);

/// 单个章节实时监听。
final chapterProvider = StreamProvider.family<Chapter?, int>(
  (ref, chapterId) => ref.watch(novelDaoProvider).watchChapter(chapterId),
);

/// 单本书实时监听（阅读器标题用）。
final bookByIdProvider = StreamProvider.family<NovelBook?, int>(
  (ref, bookId) => ref.watch(novelDaoProvider).watchBookById(bookId),
);

/// 某书的 7 类 TruthFile 实时监听。
final truthFilesByBookProvider = StreamProvider.family<List<TruthFile>, int>(
  (ref, bookId) => ref.watch(truthFileDaoProvider).watchByBook(bookId),
);
