import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/active_llm.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'novel_models.dart';
import 'novel_providers.dart';

/// 章节编辑器：正文编辑 + AI 写作（流式）+ 审校 + 修订 + 定稿固化。
class ChapterEditorPage extends ConsumerStatefulWidget {
  const ChapterEditorPage({super.key, required this.chapterId});

  final int chapterId;

  @override
  ConsumerState<ChapterEditorPage> createState() => _ChapterEditorPageState();
}

class _ChapterEditorPageState extends ConsumerState<ChapterEditorPage> {
  QuillController? _controller;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _busy = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  QuillController _ensureController(String content) {
    return _controller ??= QuillController(
      document: Document.fromJson([
        {'insert': content},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  String get _plainText => _controller!.document.toPlainText().trimRight();

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterProvider(widget.chapterId));

    return Scaffold(
      appBar: AppBar(
        title: chapterAsync.value == null
            ? const Text('章节')
            : Text(chapterAsync.value!.title),
        actions: [
          IconButton(
            tooltip: '版本历史',
            onPressed: () => _showRevisions(chapterAsync.value),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (chapter) {
          if (chapter == null) {
            return const Center(child: Text('章节不存在'));
          }
          final controller = _ensureController(chapter.content ?? '');
          return Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    QuillSimpleToolbar(
                      controller: controller,
                      config: const QuillSimpleToolbarConfig(),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: QuillEditor(
                        controller: controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        config: const QuillEditorConfig(),
                      ),
                    ),
                  ],
                ),
              ),
              _BottomBar(
                busy: _busy,
                status: chapter.status,
                hasContent: _plainText.isNotEmpty,
                onWrite: () => _write(chapter),
                onReview: () => _review(chapter),
                onFinalize: () => _finalize(chapter),
                onSave: () => _save(chapter),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<ActiveLlm?> _activeLlm() async {
    final llm = await ref.read(activeLlmProvider.future);
    if (llm == null && mounted) {
      _toast('请先在「设置」配置可用的 LLM 供应商');
    }
    return llm;
  }

  /// AI 写正文（空章节）或续写（已有内容），流式追加到编辑器。
  Future<void> _write(Chapter chapter) async {
    final llm = await _activeLlm();
    if (llm == null) return;
    setState(() => _busy = true);
    try {
      final existing = _plainText;
      final stream = ref.read(novelServiceProvider).writeChapter(
            bookId: chapter.bookId,
            chapterNumber: chapter.seq,
            targetWords: 2000,
            existingContent: existing,
            llm: llm,
          );
      await for (final chunk in stream) {
        _appendText(chunk);
      }
      await _save(chapter);
    } catch (e) {
      _toast('写作失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(Chapter chapter) async {
    final llm = await _activeLlm();
    if (llm == null) return;
    setState(() => _busy = true);
    try {
      final issues = await ref.read(novelServiceProvider).reviewChapter(
            bookId: chapter.bookId,
            content: _plainText,
            llm: llm,
          );
      if (!mounted) return;
      await _showReviewSheet(chapter, issues);
    } catch (e) {
      _toast('审校失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finalize(Chapter chapter) async {
    final llm = await _activeLlm();
    if (llm == null) return;
    setState(() => _busy = true);
    try {
      await _save(chapter);
      final latest = await ref.read(novelDaoProvider).findChapter(chapter.id);
      if (latest == null) return;
      await ref.read(novelServiceProvider).settleChapter(
            bookId: latest.bookId,
            chapter: latest,
            llm: llm,
          );
      await ref.read(novelDaoProvider).updateChapter(
            latest.copyWith(status: '定稿'),
          );
      _toast('已定稿并固化状态');
    } catch (e) {
      _toast('定稿失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(Chapter chapter) async {
    final content = _plainText;
    await ref.read(novelDaoProvider).updateChapter(
          chapter.copyWith(
            content: Value(content),
            wordCount: content.length,
          ),
        );
  }

  void _appendText(String chunk) {
    final controller = _controller!;
    final plain = controller.document.toPlainText();
    final insertAt = plain.isEmpty ? 0 : plain.length - 1;
    controller.replaceText(
      insertAt,
      0,
      chunk,
      TextSelection.collapsed(offset: insertAt + chunk.length),
    );
  }

  Future<void> _applyFix(Chapter chapter, ReviewIssue issue) async {
    final llm = await _activeLlm();
    if (llm == null) return;
    setState(() => _busy = true);
    try {
      final latest = await ref.read(novelDaoProvider).findChapter(chapter.id);
      if (latest == null) return;
      final revised = await ref.read(novelServiceProvider).reviseChapter(
            chapter: latest,
            instruction: '${issue.problem}（修复方向：${issue.fix}）',
            mode: issue.isStructural ? RevisionMode.rewrite : RevisionMode.spotFix,
            llm: llm,
          );
      _replaceContent(revised);
      _toast('已修订');
    } catch (e) {
      _toast('修订失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _replaceContent(String content) {
    final controller = _controller!;
    controller.document = Document.fromJson([
      {'insert': content},
    ]);
    controller.updateSelection(
      TextSelection.collapsed(offset: content.length),
      ChangeSource.local,
    );
  }

  Future<void> _showReviewSheet(Chapter chapter, List<ReviewIssue> issues) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtl) {
          return ListView(
            controller: scrollCtl,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '审校结果 ${issues.length} 条',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (issues.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('未发现问题。'),
                ),
              for (final issue in issues)
                _IssueCard(
                  issue: issue,
                  onApply: () {
                    Navigator.of(sheetCtx).pop();
                    _applyFix(chapter, issue);
                  },
                ),
            ],
          );
        },
      ),
    ).then((_) async {
      // Sheet 关闭后重新加载最新正文（修订可能已更新）。
      final latest = await ref.read(novelDaoProvider).findChapter(chapter.id);
      if (latest != null && latest.content != null) {
        _replaceContent(latest.content!);
      }
    });
  }

  Future<void> _showRevisions(Chapter? chapter) async {
    if (chapter == null) return;
    final revisions = await ref
        .read(chapterRevisionDaoProvider)
        .listByChapter(chapter.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('版本历史', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (revisions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('暂无历史版本。'),
            ),
          for (final r in revisions)
            ListTile(
              leading: Text('v${r.revision}'),
              title: Text(
                r.content ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${r.createdAt}'),
            ),
        ],
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue, required this.onApply});

  final ReviewIssue issue;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(issue.type.label)),
                const SizedBox(width: 8),
                if (issue.isStructural)
                  const Chip(label: Text('结构')),
                const Spacer(),
                Text(
                  issue.location,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(issue.problem),
            const SizedBox(height: 4),
            Text(
              '依据：${issue.evidence}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '修复：${issue.fix}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('采纳修订'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.busy,
    required this.status,
    required this.hasContent,
    required this.onWrite,
    required this.onReview,
    required this.onFinalize,
    required this.onSave,
  });

  final bool busy;
  final String status;
  final bool hasContent;
  final VoidCallback onWrite;
  final VoidCallback onReview;
  final VoidCallback onFinalize;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : onWrite,
                icon: const Icon(Icons.auto_awesome),
                label: Text(hasContent ? '续写' : 'AI 写正文'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '审校',
              onPressed: busy ? null : onReview,
              icon: const Icon(Icons.fact_check_outlined),
            ),
            IconButton(
              tooltip: '定稿',
              onPressed: busy ? null : onFinalize,
              icon: const Icon(Icons.check_circle_outline),
            ),
            IconButton(
              tooltip: '保存',
              onPressed: busy ? null : onSave,
              icon: const Icon(Icons.save_outlined),
            ),
            if (busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
