import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'novel_providers.dart';

/// 大纲独立编辑页：结构化卷/章/节三级管理，写回 book.outline（Markdown）。
///
/// 大纲以自由文本 Markdown 落库，此页提供「逐章目标卡片」编辑体验：
/// 每章一行（标题 + 目标 + 关键事件 + 结尾变化），保存时序列化回 Markdown。
/// 支持增删章节、按序号重排。
class OutlineEditorPage extends ConsumerWidget {
  const OutlineEditorPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(novelBookByProjectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('大纲编辑')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('尚未创建小说书'));
          }
          return _OutlineBody(book: book);
        },
      ),
    );
  }
}

class _OutlineBody extends ConsumerStatefulWidget {
  const _OutlineBody({required this.book});

  final NovelBook book;

  @override
  ConsumerState<_OutlineBody> createState() => _OutlineBodyState();
}

class _OutlineBodyState extends ConsumerState<_OutlineBody> {
  late final List<_ChapterGoal> _goals;
  late final List<TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _goals = parseOutline(widget.book.outline);
    _controllers = [
      for (final g in _goals) TextEditingController(text: g.detailText),
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// 解析 Markdown 大纲为逐章目标列表。
  ///
  /// 约定：每段以「第 N 章」或「## 第 N 章」开头的段落为一章，
  /// 后续非空行视为该章明细（目标/事件/结尾等自由文本）。
  static List<_ChapterGoal> parseOutline(String? outline) {
    if (outline == null || outline.trim().isEmpty) return [];
    final lines = outline.split('\n');
    final goals = <_ChapterGoal>[];
    _ChapterGoal? current;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = RegExp(r'^#{0,6}\s*第\s*(\d+)\s*章\s*[:：]?\s*(.*)$')
          .firstMatch(line);
      if (m != null) {
        current = _ChapterGoal(
          seq: int.parse(m.group(1)!),
          title: m.group(2)!.trim(),
        );
        goals.add(current);
      } else if (current != null) {
        // 追加明细行到当前章的 detailText。
        final updated = current.detailText.isEmpty
            ? line
            : '${current.detailText}\n$line';
        goals[goals.length - 1] = current.copyWith(detailText: updated);
      }
    }
    return goals;
  }

  /// 序列化为 Markdown 大纲文本（以 controller 为明细权威来源）。
  String serialize() {
    final buf = StringBuffer();
    for (var i = 0; i < _goals.length; i++) {
      final g = _goals[i];
      final header = g.title.isEmpty
          ? '第 ${g.seq} 章'
          : '第 ${g.seq} 章 ${g.title}';
      buf.writeln(header);
      for (final d in _controllers[i].text.split('\n')) {
        if (d.trim().isNotEmpty) buf.writeln(d.trim());
      }
      buf.writeln('');
    }
    return buf.toString().trimRight();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final text = serialize();
      final book = widget.book;
      await ref
          .read(novelDaoProvider)
          .updateBook(
            book.copyWith(outline: Value(text.isEmpty ? null : text)),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('大纲已保存（${_goals.length} 章）')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addGoal() {
    final seq = _goals.isEmpty
        ? 1
        : _goals.map((g) => g.seq).reduce((a, b) => a > b ? a : b) + 1;
    setState(() {
      _goals.add(_ChapterGoal(seq: seq));
      _controllers.add(TextEditingController());
    });
  }

  void _removeGoal(int index) {
    setState(() {
      _goals.removeAt(index);
      _controllers.removeAt(index).dispose();
      // 重排序号。
      for (var i = 0; i < _goals.length; i++) {
        _goals[i] = _goals[i].copyWith(seq: i + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      const Text('暂无大纲章节'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (context, i) => _GoalCard(
                    goal: _goals[i],
                    detailController: _controllers[i],
                    onTitleChanged: (t) => setState(
                      () => _goals[i] = _goals[i].copyWith(title: t),
                    ),
                    onRemove: () => _removeGoal(i),
                    onMoveUp: i > 0 ? () => _move(i, i - 1) : null,
                    onMoveDown: i < _goals.length - 1
                        ? () => _move(i, i + 1)
                        : null,
                  ),
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _addGoal,
                    icon: const Icon(Icons.add),
                    label: const Text('添加章节'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存大纲'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _move(int from, int to) {
    setState(() {
      final item = _goals.removeAt(from);
      _goals.insert(to, item);
      for (var i = 0; i < _goals.length; i++) {
        _goals[i] = _goals[i].copyWith(seq: i + 1);
      }
      final c = _controllers.removeAt(from);
      _controllers.insert(to, c);
    });
  }
}

/// 单章目标编辑卡。
class _GoalCard extends StatefulWidget {
  const _GoalCard({
    required this.goal,
    required this.detailController,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onTitleChanged,
  });

  final _ChapterGoal goal;
  final TextEditingController detailController;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.goal.title);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    '${widget.goal.seq}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _title,
                    onChanged: widget.onTitleChanged,
                    decoration: const InputDecoration(
                      hintText: '本章标题（可选）',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '上移',
                  onPressed: widget.onMoveUp,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                ),
                IconButton(
                  tooltip: '下移',
                  onPressed: widget.onMoveDown,
                  icon: const Icon(Icons.arrow_downward, size: 18),
                ),
                IconButton(
                  tooltip: '删除本章',
                  onPressed: widget.onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.detailController,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: '本章目标 / 关键事件 / 结尾变化（每行一条）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 内部章节目标结构。
class _ChapterGoal {
  const _ChapterGoal({
    required this.seq,
    this.title = '',
    this.detailText = '',
  });

  final int seq;
  final String title;
  final String detailText;

  _ChapterGoal copyWith({int? seq, String? title, String? detailText}) =>
      _ChapterGoal(
        seq: seq ?? this.seq,
        title: title ?? this.title,
        detailText: detailText ?? this.detailText,
      );
}
