import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/json_values.dart';
import 'novel_providers.dart';
import 'truth_file_kinds.dart';

/// 伏笔池管理页：登记/追踪/回收伏笔钩子，写回 TruthFile（hooks）。
///
/// 数据源为 hooks TruthFile：`{ "hooks": [{id, description, plantedChapter,
/// status, resolvedChapter?}] }`。与 Settler 定稿固化共用同一存储；
/// 手工编辑后定稿按 id 合并（同 id 覆盖，新 id 追加）。
class HookManagerPage extends ConsumerWidget {
  const HookManagerPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(novelBookByProjectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('伏笔池')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('尚未创建小说书'));
          }
          return _HookList(bookId: book.id);
        },
      ),
    );
  }
}

class _HookList extends ConsumerStatefulWidget {
  const _HookList({required this.bookId});

  final int bookId;

  @override
  ConsumerState<_HookList> createState() => _HookListState();
}

class _HookListState extends ConsumerState<_HookList> {
  List<Map<String, dynamic>> _hooks = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final data = await _load();
      if (!mounted) return;
      setState(() {
        _hooks = [for (final h in jsonList(data['hooks'])) jsonMap(h)];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('加载失败：$_error'));
    }
    return Column(
      children: [
        _statusFilterBar(),
        Expanded(
          child: _hooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      const Text('暂无伏笔登记'),
                      const SizedBox(height: 4),
                      Text(
                        '章节定稿后 Settler 自动登记，也可手动添加',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _hooks.length,
                  itemBuilder: (context, i) => _HookCard(
                    hook: _hooks[i],
                    onResolve: () => _resolveHook(_hooks[i]),
                    onEdit: () => _showEditDialog(_hooks[i]),
                    onRemove: () => _removeHook(_hooks[i]),
                  ),
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _saving ? null : () => _showEditDialog(null),
              icon: const Icon(Icons.add),
              label: const Text('登记伏笔'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusFilterBar() {
    final openCount = _hooks.where((h) => h['status'] != 'resolved').length;
    final resolvedCount = _hooks.length - openCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statusChip('未闭合', openCount),
          const SizedBox(width: 8),
          _statusChip('已回收', resolvedCount),
          const Spacer(),
          TextButton(
            onPressed: _saving ? null : _reload,
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, int count) {
    return Chip(
      label: Text('$label $count'),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Future<Map<String, dynamic>> _load() async {
    final store = ref.read(novelServiceProvider).storeFor(widget.bookId);
    return store.read(TruthFileKind.hooks);
  }

  Future<void> _persist(List<Map<String, dynamic>> hooks) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(novelServiceProvider).storeFor(widget.bookId).write(
        TruthFileKind.hooks,
        {'hooks': hooks},
      );
      if (!mounted) return;
      setState(() {
        _hooks = hooks;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic>? existing) async {
    final result = await showDialog<({String id, String desc, String planted})>(
      context: context,
      builder: (ctx) => _HookEditDialog(
        existing: existing,
        defaultId: 'hook_${_hooks.length + 1}',
      ),
    );
    if (result == null) return;

    final newHook = <String, dynamic>{
      'id': result.id,
      'description': result.desc.trim(),
      'plantedChapter': result.planted.trim(),
      'status': existing?['status'] ?? 'open',
    };
    if (existing?['resolvedChapter'] != null) {
      newHook['resolvedChapter'] = existing!['resolvedChapter'];
    }

    final updated = <Map<String, dynamic>>[];
    if (existing == null) {
      updated.addAll(_hooks);
      updated.add(newHook);
    } else {
      for (final h in _hooks) {
        updated.add(h['id'] == existing['id'] ? newHook : h);
      }
    }
    await _persist(updated);
  }

  Future<void> _resolveHook(Map<String, dynamic> hook) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('回收伏笔'),
        content: Text('确定将「${hook['description']}」标记为已回收？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认回收'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final updated = [
      for (final h in _hooks)
        h['id'] == hook['id']
            ? {...h, 'status': 'resolved', 'resolvedChapter': '当前章'}
            : h,
    ];
    await _persist(updated);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('伏笔已回收')));
    }
  }

  Future<void> _removeHook(Map<String, dynamic> hook) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除伏笔'),
        content: Text('确定删除「${hook['description']}」？'),
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
    if (ok != true) return;

    final updated = [
      for (final h in _hooks)
        if (h['id'] != hook['id']) h,
    ];
    await _persist(updated);
  }
}

class _HookCard extends StatelessWidget {
  const _HookCard({
    required this.hook,
    required this.onResolve,
    required this.onEdit,
    required this.onRemove,
  });

  final Map<String, dynamic> hook;
  final VoidCallback onResolve;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isResolved = hook['status'] == 'resolved';
    final desc = hook['description']?.toString() ?? '（未填写描述）';
    final planted = hook['plantedChapter']?.toString() ?? '';
    final resolvedAt = hook['resolvedChapter']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isResolved
          ? Theme.of(context).colorScheme.surfaceContainerLow
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    isResolved ? '已回收' : '未闭合',
                    style: TextStyle(
                      color: isResolved
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (planted.isNotEmpty)
                  Text(
                    '埋设于 $planted',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const Spacer(),
                Text(
                  hook['id']?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(desc, style: Theme.of(context).textTheme.bodyMedium),
            if (isResolved && resolvedAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '回收于 $resolvedAt',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onEdit, child: const Text('编辑')),
                TextButton(onPressed: onRemove, child: const Text('删除')),
                if (!isResolved)
                  FilledButton.tonal(
                    onPressed: onResolve,
                    child: const Text('回收'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 伏笔登记/编辑对话框：controller 由 State 持有，退出动画结束后才释放。
class _HookEditDialog extends StatefulWidget {
  const _HookEditDialog({required this.existing, required this.defaultId});

  final Map<String, dynamic>? existing;
  final String defaultId;

  @override
  State<_HookEditDialog> createState() => _HookEditDialogState();
}

class _HookEditDialogState extends State<_HookEditDialog> {
  late final TextEditingController _id;
  late final TextEditingController _desc;
  late final TextEditingController _planted;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(
      text: widget.existing?['id']?.toString() ?? '',
    );
    _desc = TextEditingController(
      text: widget.existing?['description']?.toString() ?? '',
    );
    _planted = TextEditingController(
      text: widget.existing?['plantedChapter']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _id.dispose();
    _desc.dispose();
    _planted.dispose();
    super.dispose();
  }

  void _submit() {
    final desc = _desc.text.trim();
    if (desc.isEmpty) return;
    final id = _id.text.trim().isEmpty ? widget.defaultId : _id.text.trim();
    Navigator.of(context).pop((
      id: id,
      desc: desc,
      planted: _planted.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? '登记伏笔' : '编辑伏笔'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _id,
              decoration: const InputDecoration(
                labelText: '伏笔 ID（如 hook_01）',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              autofocus: isNew,
              decoration: const InputDecoration(labelText: '伏笔描述 *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _planted,
              decoration: const InputDecoration(labelText: '埋设章节（如「第 3 章」）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
