import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'novel_providers.dart';

/// 阅读器页面：按章节翻页阅读小说。
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(chaptersByBookProvider(widget.bookId));
    final bookAsync = ref.watch(
      StreamProvider<NovelBook?>(
        (ref) => ref.watch(novelDaoProvider).watchBookById(widget.bookId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bookAsync.value?.title ?? '阅读器',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: '上一章',
            onPressed: _currentIndex > 0
                ? () => setState(() => _currentIndex--)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: '下一章',
            onPressed: () {
              final chapters = chaptersAsync.value ?? [];
              if (_currentIndex < chapters.length - 1) {
                setState(() => _currentIndex++);
              }
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (chapters) {
          if (chapters.isEmpty) {
            return const Center(child: Text('还没有章节'));
          }
          final chapter = chapters[_currentIndex];
          return Column(
            children: [
              // 章节标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '第 ${chapter.seq} 章',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      '${_currentIndex + 1} / ${chapters.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 章节正文
              Expanded(
                child: chapter.content != null && chapter.content!.isNotEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          chapter.content!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            height: 1.8,
                          ),
                        ),
                      )
                    : const Center(child: Text('本章暂无正文')),
              ),
            ],
          );
        },
      ),
    );
  }
}
