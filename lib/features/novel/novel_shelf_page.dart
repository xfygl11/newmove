import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/active_llm.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'novel_providers.dart';

/// 小说书架：某项目的章节列表 + 设定入口 + AI 写作入口。
class NovelShelfPage extends ConsumerWidget {
  const NovelShelfPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(novelBookByProjectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('AI 写小说')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (book) {
          if (book == null) {
            return _EmptyBook(onStart: () => _showSetupDialog(context));
          }
          return _BookView(book: book);
        },
      ),
    );
  }

  Future<void> _showSetupDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SetupDialog(projectId: projectId),
    );
  }
}

class _EmptyBook extends StatelessWidget {
  const _EmptyBook({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_stories,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('还没有小说书'),
          const SizedBox(height: 4),
          Text(
            '输入创意，AI 生成世界观、角色与大纲',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('开始创作'),
          ),
        ],
      ),
    );
  }
}

class _BookView extends ConsumerWidget {
  const _BookView({required this.book});

  final NovelBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersByBookProvider(book.id));

    return Column(
      children: [
        _BookHeader(book: book),
        Expanded(
          child: chaptersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (chapters) {
              if (chapters.isEmpty) {
                return const Center(child: Text('还没有章节，点击下方「写下一章」开始'));
              }
              return ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, i) =>
                    _ChapterTile(projectId: book.projectId, chapter: chapters[i]),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _createAndOpenChapter(context, ref, book),
              icon: const Icon(Icons.edit),
              label: const Text('AI 写下一章'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createAndOpenChapter(
    BuildContext context,
    WidgetRef ref,
    NovelBook book,
  ) async {
    final llm = await ref.read(activeLlmProvider.future);
    if (llm == null) {
      if (context.mounted) {
        _toast(context, '请先在「设置」配置可用的 LLM 供应商');
      }
      return;
    }
    final dao = ref.read(novelDaoProvider);
    final seq = await dao.maxSeq(book.id) + 1;
    final id = await dao.insertChapter(
      ChaptersCompanion.insert(bookId: book.id, seq: seq, title: '第 $seq 章'),
    );
    if (context.mounted) {
      context.push('/novel/${book.projectId}/chapter/$id');
    }
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.book});

  final NovelBook book;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(book.title),
      subtitle: Text(
        book.premise?.isNotEmpty == true ? book.premise! : '尚未生成设定',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: TextButton(
        onPressed: () => context.push('/novel/${book.projectId}/settings'),
        child: const Text('设定'),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.projectId, required this.chapter});

  final int projectId;
  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (chapter.status) {
      '定稿' => Colors.green,
      '审校中' => Colors.blue,
      _ => Colors.grey,
    };
    return ListTile(
      leading: CircleAvatar(radius: 16, child: Text('${chapter.seq}')),
      title: Text(chapter.title),
      subtitle: Text('${chapter.wordCount} 字 · 修订 ${chapter.revision}'),
      trailing: Text(chapter.status, style: TextStyle(color: statusColor)),
      onTap: () =>
          context.push('/novel/$projectId/chapter/${chapter.id}'),
    );
  }
}

/// 开始创作：输入创意，AI 生成设定。
class _SetupDialog extends ConsumerStatefulWidget {
  const _SetupDialog({required this.projectId});

  final int projectId;

  @override
  ConsumerState<_SetupDialog> createState() => _SetupDialogState();
}

class _SetupDialogState extends ConsumerState<_SetupDialog> {
  final _idea = TextEditingController();
  final _genre = TextEditingController();
  bool _generating = false;

  @override
  void dispose() {
    _idea.dispose();
    _genre.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final idea = _idea.text.trim();
    if (idea.isEmpty) return;
    final llm = await ref.read(activeLlmProvider.future);
    if (llm == null) {
      if (mounted) {
        _toast(context, '请先在「设置」配置可用的 LLM 供应商');
      }
      return;
    }
    setState(() => _generating = true);
    try {
      final dao = ref.read(novelDaoProvider);
      final bookId = await dao.insertBook(
        NovelBooksCompanion.insert(projectId: widget.projectId, title: '未命名作品'),
      );
      await ref.read(novelServiceProvider).generateSetup(
            bookId: bookId,
            idea: idea,
            genre: _genre.text.trim(),
            llm: llm,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _toast(context, '生成失败：$e');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('开始创作'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _idea,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '创意 / 一句话',
              hintText: '例如：一个少年在末世觉醒治愈能力',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _genre,
            decoration: const InputDecoration(labelText: '题材（可选）'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _generating ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _generating ? null : _generate,
          child: _generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('生成设定'),
        ),
      ],
    );
  }
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(text)));
}
