import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';

/// 书架页面：列出所有书籍，点击进入阅读器。
class BookshelfPage extends ConsumerWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(
      StreamProvider<List<NovelBook>>(
        (ref) => ref.watch(novelDaoProvider).watchAllBooks(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('书架')),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (books) {
          if (books.isEmpty) {
            return const Center(
              child: Text('还没有书籍，去「项目」创建小说吧'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.push('/shelf/${book.id}/reader'),
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
                              Text(
                                book.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (book.genre != null && book.genre!.isNotEmpty)
                                Text(
                                  book.genre!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                book.workType,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
