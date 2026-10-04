import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/active_llm.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../novel/novel_providers.dart';
import 'script_providers.dart';

/// 新建 / 重新改编：选择原文章节范围 + 忠实度模式。
class AdaptSheet extends ConsumerStatefulWidget {
  const AdaptSheet({super.key, required this.book, this.existing});

  final NovelBook book;
  final Script? existing;

  @override
  ConsumerState<AdaptSheet> createState() => _AdaptSheetState();
}

class _AdaptSheetState extends ConsumerState<AdaptSheet> {
  final Set<int> _selectedChapterIds = {};
  String _fidelity = '严格保留';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fidelity = widget.existing?.fidelityMode ?? '严格保留';
  }

  Future<void> _generate() async {
    if (_selectedChapterIds.isEmpty) {
      _toast('请选择至少一章原文');
      return;
    }
    final llm = await ref.read(activeLlmProvider.future);
    if (llm == null) {
      _toast('请先在「设置」配置可用的 LLM 供应商');
      return;
    }

    final chapters = await ref
        .read(novelDaoProvider)
        .listChapters(widget.book.id);
    final sourceTexts = [
      for (final c in chapters)
        if (_selectedChapterIds.contains(c.id)) c.content ?? '',
    ];
    if (sourceTexts.every((t) => t.trim().isEmpty)) {
      _toast('所选章节还没有正文');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(scriptServiceProvider)
          .adaptChapters(
            bookId: widget.book.id,
            existing: widget.existing,
            title: widget.existing?.title ?? widget.book.title,
            sourceTexts: sourceTexts,
            fidelityMode: _fidelity,
            llm: llm,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('改编失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(chaptersByBookProvider(widget.book.id));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? '新建改编' : '重新改编',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('忠实度', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '严格保留', label: Text('严格保留')),
              ButtonSegment(value: '允许合理压缩', label: Text('允许合理压缩')),
            ],
            selected: {_fidelity},
            onSelectionChanged: _busy
                ? null
                : (s) => setState(() => _fidelity = s.first),
          ),
          const SizedBox(height: 8),
          Text('选择原文章节', style: Theme.of(context).textTheme.bodySmall),
          Flexible(
            child: chaptersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('加载失败：$e'),
              data: (chapters) {
                if (chapters.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('还没有章节'),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in chapters)
                        CheckboxListTile(
                          dense: true,
                          title: Text(
                            '${c.seq}. ${c.title}（${c.wordCount} 字）',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: _selectedChapterIds.contains(c.id),
                          onChanged: _busy
                              ? null
                              : (v) => setState(() {
                                  if (v == true) {
                                    _selectedChapterIds.add(c.id);
                                  } else {
                                    _selectedChapterIds.remove(c.id);
                                  }
                                }),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _generate,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('开始改编'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
