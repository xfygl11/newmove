import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';

/// 书籍状态徽章。
class BookStatusBadge extends StatelessWidget {
  const BookStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  ({String label, Color color}) _statusInfo(String status) {
    switch (status) {
      case '草稿':
        return (label: '草稿', color: Colors.grey);
      case '写作中':
        return (label: '写作中', color: Colors.blue);
      case '审校中':
        return (label: '审校中', color: Colors.orange);
      case '已定稿':
        return (label: '已定稿', color: Colors.green);
      case '已归档':
        return (label: '已归档', color: Colors.grey);
      default:
        return (label: '未知', color: Colors.grey);
    }
  }
}

/// 书籍统计信息。
class _BookStats {
  const _BookStats({required this.chapterCount, required this.wordCount});

  final int chapterCount;
  final int wordCount;

  String get wordCountDisplay => wordCount >= 10000
      ? '${(wordCount / 10000).toStringAsFixed(1)}万字'
      : '$wordCount字';
}

/// 书架页面：列出所有书籍，支持搜索、分组、长按菜单、阅读进度显示。
class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage> {
  final _searchController = TextEditingController();
  bool _searchMode = false;
  Map<int, _BookStats> _statsCache = {};
  Map<int, ReadingProgress> _progressMap = {};
  bool _groupByProject = false;

  @override
  void initState() {
    super.initState();
    _loadStatsAndProgress();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatsAndProgress() async {
    final dao = ref.read(novelDaoProvider);
    final progressDao = ref.read(readingProgressDaoProvider);
    final progressMap = await progressDao.findAll();
    // 一次聚合查询获取所有书统计，避免 N 本书 N 次串行查询。
    final statsMap = await dao.getAllBookStats();
    final stats = <int, _BookStats>{
      for (final entry in statsMap.entries)
        entry.key: _BookStats(
          chapterCount: entry.value.chapterCount,
          wordCount: entry.value.wordCount,
        ),
    };
    if (mounted) {
      setState(() {
        _statsCache = stats;
        _progressMap = progressMap;
      });
    }
  }

  void _showBookMenu(NovelBook book) {
    final projectId = book.projectId;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑作品'),
              onTap: () => context.push('/project/$projectId/book/${book.id}'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('开始阅读'),
              onTap: () => context.push('/shelf/${book.id}/reader'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除书籍'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('删除书籍'),
                    content: Text('确定要删除《${book.title}》吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  final dao = ref.read(novelDaoProvider);
                  final progressDao = ref.read(readingProgressDaoProvider);
                  await dao.deleteBook(book.id);
                  await progressDao.deleteByBook(book.id);
                  await _loadStatsAndProgress();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(NovelBook book) {
    final stats = _statsCache[book.id];
    final progress = _progressMap[book.id];
    final totalChapters = stats?.chapterCount ?? 0;
    final currentChapter = progress?.chapterSeq ?? 0;
    final progressPercent =
        totalChapters > 0 ? (currentChapter / totalChapters) * 100 : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/shelf/${book.id}/reader'),
        onLongPress: () => _showBookMenu(book),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (book.status.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: BookStatusBadge(status: book.status),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (book.genre?.isNotEmpty == true)
                      Text(
                        book.genre!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          book.workType,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (stats != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${stats.chapterCount}章',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            stats.wordCountDisplay,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    if (progressPercent > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          minHeight: 4,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '阅读进度: 第$currentChapter 章 / 共$totalChapters 章',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  List<NovelBook> _filterBooks(List<NovelBook> books) {
    if (!_searchMode || _searchController.text.isEmpty) {
      return books;
    }
    final query = _searchController.text.toLowerCase();
    return books.where((b) {
      return b.title.toLowerCase().contains(query) ||
          (b.genre?.toLowerCase().contains(query) ?? false) ||
          b.workType.toLowerCase().contains(query);
    }).toList();
  }

  Map<int, List<NovelBook>> _groupBooksByProject(List<NovelBook> books) {
    final grouped = <int, List<NovelBook>>{};
    for (final book in books) {
      grouped.putIfAbsent(book.projectId, () => []).add(book);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(
      StreamProvider<List<NovelBook>>(
        (ref) => ref.watch(novelDaoProvider).watchAllBooks(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: _searchMode
            ? SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '搜索书籍',
                    border: InputBorder.none,
                  ),
                ),
              )
            : const Text('书架'),
        actions: [
          IconButton(
            tooltip: _searchMode ? '关闭搜索' : '搜索',
            onPressed: () {
              setState(() {
                _searchMode = !_searchMode;
                if (!_searchMode) {
                  _searchController.clear();
                }
              });
            },
            icon: Icon(
              _searchMode ? Icons.close : Icons.search,
            ),
          ),
          IconButton(
            tooltip: '按项目分组',
            onPressed: () {
              setState(() {
                _groupByProject = !_groupByProject;
              });
            },
            icon: Icon(
              _groupByProject ? Icons.folder_open : Icons.folder,
            ),
          ),
          IconButton(
            tooltip: '刷新',
            onPressed: _loadStatsAndProgress,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (books) {
          if (books.isEmpty) {
            return const Center(
              child: Text('还没有书籍，去「项目」创建小说吧'),
            );
          }

          final filteredBooks = _filterBooks(books);

          if (filteredBooks.isEmpty) {
            return const Center(child: Text('没有找到匹配的书籍'));
          }

          if (_groupByProject) {
            final grouped = _groupBooksByProject(filteredBooks);
            final projectDao = ref.read(projectDaoProvider);
            final projectsFuture = projectDao.listAll();

            return FutureBuilder<Map<int, Project>>(
              future: projectsFuture.then((projects) => {
                for (final p in projects) p.id: p,
              }),
              builder: (context, snapshot) {
                final projectMap = snapshot.data ?? {};
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grouped.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('按项目分组', style: TextStyle(fontSize: 12)),
                        ),
                      );
                    }
                    final entries = grouped.entries.toList();
                    final entry = entries[index - 1];
                    final project = projectMap[entry.key];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            project?.name ?? '项目 ${entry.key}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ...entry.value.map(_buildBookCard),
                      ],
                    );
                  },
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBooks.length,
            itemBuilder: (context, index) {
              return _buildBookCard(filteredBooks[index]);
            },
          );
        },
      ),
    );
  }
}
