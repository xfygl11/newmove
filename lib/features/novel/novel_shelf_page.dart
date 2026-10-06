import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/active_llm.dart';
import '../../core/status_constants.dart';
import '../../core/storage/providers.dart';
import '../../core/text/chapter_import.dart';
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
            return _EmptyBook(
              onStart: () => context.push('/novel/$projectId/setup'),
            );
          }
          return _BookView(book: book);
        },
      ),
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
                itemBuilder: (context, i) => _ChapterTile(
                  projectId: book.projectId,
                  chapter: chapters[i],
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _createAndOpenChapter(context, ref, book),
                    icon: const Icon(Icons.edit),
                    label: const Text('AI 写下一章'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '导入章节',
                  onPressed: () => _importChapter(context, ref, book),
                  icon: const Icon(Icons.file_upload_outlined),
                ),
              ],
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

  /// 从本地 .md / .html / .txt 文件导入为新一章。
  Future<void> _importChapter(
    BuildContext context,
    WidgetRef ref,
    NovelBook book,
  ) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['md', 'markdown', 'html', 'txt'],
    );
    if (picked.isEmpty || picked.single.path == null) return;

    final fileName = picked.single.name;
    final path = picked.single.path!;
    try {
      final raw = await ChapterImport.readText(path);
      final content = ChapterImport.cleanText(raw, fileName: fileName);
      if (content.isEmpty) {
        if (context.mounted) {
          _toast(context, '文件内容为空，导入失败');
        }
        return;
      }
      // 标题取首段 H1，否则用文件名（去扩展名），并去掉正文中重复的首行标题。
      final extracted = ChapterImport.extractTitle(content, fileName: fileName);
      final dao = ref.read(novelDaoProvider);
      final seq = await dao.maxSeq(book.id) + 1;
      await dao.insertChapter(
        ChaptersCompanion.insert(
          bookId: book.id,
          seq: seq,
          title: extracted.title.isNotEmpty ? extracted.title : '第 $seq 章（导入）',
          content: Value(extracted.content),
          wordCount: Value(ChapterImport.countWords(extracted.content)),
          status: const Value(ChapterStatuses.draft),
        ),
      );
      if (context.mounted) {
        _toast(context, '已导入为第 $seq 章');
        ref.invalidate(chaptersByBookProvider(book.id));
      }
    } catch (e) {
      if (context.mounted) {
        _toast(context, '导入失败：$e');
      }
    }
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.book});

  final NovelBook book;

  @override
  Widget build(BuildContext context) {
    final workType = book.workType;
    final isDefault = workType == '长篇';
    return ListTile(
      title: Row(
        children: [
          if (!isDefault)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                workType,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          Expanded(child: Text(book.title, overflow: TextOverflow.ellipsis)),
        ],
      ),
      subtitle: Text(
        book.premise?.isNotEmpty == true ? book.premise! : '尚未生成设定',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => context.push('/novel/${book.projectId}/outline'),
            child: const Text('大纲'),
          ),
          TextButton(
            onPressed: () =>
                context.push('/novel/${book.projectId}/characters'),
            child: const Text('角色'),
          ),
          TextButton(
            onPressed: () => context.push('/novel/${book.projectId}/hooks'),
            child: const Text('伏笔'),
          ),
          TextButton(
            onPressed: () => context.push('/script/${book.projectId}'),
            child: const Text('剧本'),
          ),
          TextButton(
            onPressed: () => context.push('/novel/${book.projectId}/settings'),
            child: const Text('设定'),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends ConsumerWidget {
  const _ChapterTile({required this.projectId, required this.chapter});

  final int projectId;
  final Chapter chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      onTap: () => context.push('/novel/$projectId/chapter/${chapter.id}'),
      onLongPress: () => _showChapterMenu(context, ref),
    );
  }

  /// 长按章节弹出操作菜单：删除。
  Future<void> _showChapterMenu(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              '删除第 ${chapter.seq} 章「${chapter.title}」',
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => Navigator.of(ctx).pop('delete'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
    if (action != 'delete' || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除章节'),
        content: Text('确定删除「${chapter.title}」？该章节及其版本历史将不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(cascadeDaoProvider).deleteChapterCascade(chapter.id);
      if (context.mounted) {
        _toast(context, '已删除「${chapter.title}」');
      }
    } catch (e) {
      if (context.mounted) _toast(context, '删除失败：$e');
    }
  }
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
