import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'novel_providers.dart';
import 'truth_file_kinds.dart';

/// 设定工坊：静态设定（世界观/命题/风格/大纲）编辑 + TruthFile 7 类状态查看。
///
/// 对应 T1.2 / T1.4。TruthFile 只读展示，由 Settler 在章节定稿时自动更新；
/// 静态设定由用户在此处手工编辑（生成初始值来自 Planner/Architect）。
class SettingWorkshopPage extends ConsumerWidget {
  const SettingWorkshopPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(novelBookByProjectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('设定工坊')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('尚未创建小说书'));
          }
          return _WorkshopBody(book: book);
        },
      ),
    );
  }
}

class _WorkshopBody extends StatelessWidget {
  const _WorkshopBody({required this.book});

  final NovelBook book;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StaticSettings(book: book),
        const Divider(height: 1),
        Expanded(child: _TruthFileTabs(bookId: book.id)),
      ],
    );
  }
}

/// 静态设定：世界观、故事命题、风格指南、大纲。
class _StaticSettings extends ConsumerWidget {
  const _StaticSettings({required this.book});

  final NovelBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('基础设定', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(book.title, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          _EditRow(
            label: '世界观',
            value: book.world,
            onEdit: (text) => _update(
              context,
              ref,
              book.copyWith(world: Value(text.isEmpty ? null : text)),
            ),
          ),
          _EditRow(
            label: '故事命题',
            value: book.premise,
            onEdit: (text) => _update(
              context,
              ref,
              book.copyWith(premise: Value(text.isEmpty ? null : text)),
            ),
          ),
          _EditRow(
            label: '风格指南',
            value: book.styleGuide,
            onEdit: (text) => _update(
              context,
              ref,
              book.copyWith(styleGuide: Value(text.isEmpty ? null : text)),
            ),
          ),
          _EditRow(
            label: '大纲',
            value: book.outline,
            multiline: true,
            onEdit: (text) => _update(
              context,
              ref,
              book.copyWith(outline: Value(text.isEmpty ? null : text)),
            ),
            onAction: () => context.push('/novel/${book.projectId}/outline'),
          ),
        ],
      ),
    );
  }

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    NovelBook updated,
  ) async {
    try {
      await ref.read(novelDaoProvider).updateBook(updated);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }
}

class _EditRow extends StatelessWidget {
  const _EditRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.multiline = false,
    this.onAction,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onEdit;
  final bool multiline;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = value ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      subtitle: Text(
        text.isEmpty ? '（未填写）' : text,
        maxLines: multiline ? 3 : 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onAction != null)
            IconButton(
              tooltip: '打开大纲编辑器',
              icon: const Icon(Icons.edit_note, size: 18),
              onPressed: onAction,
            ),
          IconButton(
            tooltip: '快速编辑',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      onTap: () => _showEditDialog(context),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: value ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑$label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: multiline ? 10 : 5,
          minLines: multiline ? 4 : 1,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) onEdit(result);
  }
}

/// TruthFile 7 类 Tab 查看器。
class _TruthFileTabs extends ConsumerWidget {
  const _TruthFileTabs({required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(truthFilesByBookProvider(bookId));
    final rows = rowsAsync.value ?? const <TruthFile>[];

    return DefaultTabController(
      length: TruthFileKind.all.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final kind in TruthFileKind.all)
                Tab(text: TruthFileKind.label(kind)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final kind in TruthFileKind.all)
                  _TruthFileView(
                    row: _find(rows, kind),
                    kind: kind,
                    bookId: bookId,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TruthFile? _find(List<TruthFile> rows, String kind) {
    for (final r in rows) {
      if (r.kind == kind) return r;
    }
    return null;
  }
}

class _TruthFileView extends StatelessWidget {
  const _TruthFileView({
    required this.row,
    required this.kind,
    required this.bookId,
  });

  final TruthFile? row;
  final String kind;
  final int bookId;

  @override
  Widget build(BuildContext context) {
    final content = row?.content ?? '';
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(content);
      json = decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      json = const {};
    }

    final cards = switch (kind) {
      TruthFileKind.worldFacts => _factCards(json),
      TruthFileKind.characterMatrix => _characterCards(context, json),
      TruthFileKind.resources => _resourceCards(json),
      TruthFileKind.hooks => _hookCards(json),
      TruthFileKind.chapterSummaries => _summaryCards(json),
      TruthFileKind.authorIntent ||
      TruthFileKind.currentFocus => [_textCard(json['text'] as String? ?? '')],
      _ => [_rawCard(content)],
    };

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (cards.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('暂无数据，章节定稿后由 Settler 自动更新')),
          )
        else
          ...cards,
      ],
    );
  }

  List<Widget> _factCards(Map<String, dynamic> json) {
    final facts = (json['facts'] as List<dynamic>? ?? const []);
    return [
      for (final f in facts)
        _kvCard(
          '${f['subject']} — ${f['predicate']} — ${f['object']}',
          _rangeText(f),
        ),
    ];
  }

  List<Widget> _characterCards(
    BuildContext context,
    Map<String, dynamic> json,
  ) {
    final chars = (json['characters'] as List<dynamic>? ?? const []);
    return [
      Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ListTile(
          leading: const Icon(Icons.person_outline, size: 22),
          title: Text('角色矩阵（${chars.length} 个角色）'),
          subtitle: const Text('点按管理可增删改角色'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/novel/$bookId/characters'),
        ),
      ),
      for (final c in chars)
        _kvCard(
          '${c['name']}（${c['role'] ?? ''}）',
          '目标：${c['goal'] ?? ''}\n状态：${c['state'] ?? ''}\n关系：${c['relations'] ?? ''}',
        ),
    ];
  }

  List<Widget> _resourceCards(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const []);
    return [for (final i in items) _kvCard('${i['name']}', _compact(i))];
  }

  List<Widget> _hookCards(Map<String, dynamic> json) {
    final hooks = (json['hooks'] as List<dynamic>? ?? const []);
    return [
      for (final h in hooks)
        _kvCard('${h['id'] ?? ''}（${h['status'] ?? 'open'}）', _compact(h)),
    ];
  }

  List<Widget> _summaryCards(Map<String, dynamic> json) {
    final rows = (json['rows'] as List<dynamic>? ?? const []);
    return [for (final r in rows) _kvCard('第 ${r['chapter']} 章', _compact(r))];
  }

  Widget _textCard(String text) {
    return _kvCard(kind, text.isEmpty ? '（空）' : text);
  }

  Widget _rawCard(String raw) {
    return _kvCard(kind, raw.isEmpty ? '（空）' : raw);
  }

  /// 把事实对象的生效区间格式化为 "第N章起" / "第N章—第M章"。
  String _rangeText(dynamic f) {
    final map = (f as Map).cast<dynamic, dynamic>();
    final from = map['validFromChapter'];
    final until = map['validUntilChapter'];
    if (from == null && until == null) return '';
    if (until == null) return '自第 $from 章起';
    return '第 $from — $until 章';
  }

  /// 把 map 中的非关键字段压缩为多行文本。
  String _compact(dynamic v) {
    final map = (v as Map).cast<dynamic, dynamic>();
    final buf = StringBuffer();
    for (final e in map.entries) {
      if (e.key == 'name' || e.key == 'id') continue;
      buf.writeln('$e.key：$e.value');
    }
    return buf.toString().trimRight();
  }

  Widget _kvCard(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ],
        ),
      ),
    );
  }
}
