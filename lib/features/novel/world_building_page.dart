import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'novel_providers.dart';

/// 世界观管理页（M29，1.2 世界观侧）：地点树 + 故事弧线。
///
/// 地点按 `parentId` 层级树组织，弧线四态 active/paused/completed/abandoned，
/// 弧线节点记录「预估推进章节」与「实际落地章节」。地点与弧线都是作品级数据，
/// 由用户在此手工维护；弧线节点的实际落地由 Settler 每章定稿后自动推进。
class WorldBuildingPage extends ConsumerWidget {
  const WorldBuildingPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(novelBookByProjectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('世界观')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('尚未创建小说书'));
          }
          return _WorldBody(bookId: book.id);
        },
      ),
    );
  }
}

class _WorldBody extends StatelessWidget {
  const _WorldBody({required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: '地点'), Tab(text: '故事弧线')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _LocationTab(bookId: bookId),
                _ArcTab(bookId: bookId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- 地点树 ----

class _LocationTab extends ConsumerStatefulWidget {
  const _LocationTab({required this.bookId});

  final int bookId;

  @override
  ConsumerState<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends ConsumerState<_LocationTab> {
  List<Location> _locations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final rows = await ref.read(locationDaoProvider).listByBook(widget.bookId);
      if (!mounted) return;
      setState(() {
        _locations = rows;
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

  /// 按 parentId 组装层级树，悬空子地点提升为顶层。
  List<Location> _childrenOf(int? parentId) {
    return [
      for (final l in _locations)
        if (l.parentId == parentId) l,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('加载失败：$_error'));

    final roots = _childrenOf(null);
    return Column(
      children: [
        Expanded(
          child: roots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      const Text('暂无地点'),
                      const SizedBox(height: 4),
                      Text(
                        '添加地点后，场景可引用具体地点',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final root in roots)
                      _locationNode(root, 0),
                  ],
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _showEditDialog(null, null),
              icon: const Icon(Icons.add),
              label: const Text('添加地点'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationNode(Location location, int depth) {
    final children = _childrenOf(location.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LocationCard(
          location: location,
          depth: depth,
          onEdit: () => _showEditDialog(location, location.parentId),
          onAddChild: () => _showEditDialog(null, location.id),
          onRemove: () => _remove(location),
        ),
        for (final child in children) _locationNode(child, depth + 1),
      ],
    );
  }

  Future<void> _remove(Location location) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除地点'),
        content: Text('确定删除「${location.name}」？其子地点会变成顶层地点。'),
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
    await ref.read(locationDaoProvider).deleteById(location.id);
    await _reload();
  }

  Future<void> _showEditDialog(Location? existing, int? parentId) async {
    final result = await showDialog<({String name, String type, String desc})>(
      context: context,
      builder: (ctx) => _LocationEditDialog(existing: existing),
    );
    if (result == null) return;
    final dao = ref.read(locationDaoProvider);
    if (existing == null) {
      await dao.insert(
        LocationsCompanion.insert(
          bookId: widget.bookId,
          name: result.name,
          type: Value(result.type),
          parentId: Value(parentId),
          description: Value(result.desc.isEmpty ? null : result.desc),
        ),
      );
    } else {
      await dao.updateById(
        existing.id,
        LocationsCompanion(
          name: Value(result.name),
          type: Value(result.type),
          description: Value(result.desc.isEmpty ? null : result.desc),
        ),
      );
    }
    await _reload();
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.depth,
    required this.onEdit,
    required this.onAddChild,
    required this.onRemove,
  });

  final Location location;
  final int depth;
  final VoidCallback onEdit;
  final VoidCallback onAddChild;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(left: depth * 16.0, bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.place_outlined, size: 20),
        title: Text(location.name),
        subtitle: Text(
          location.description == null || location.description!.isEmpty
              ? location.type
              : '${location.type} · ${location.description}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '添加子地点',
              icon: const Icon(Icons.add, size: 18),
              onPressed: onAddChild,
            ),
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- 故事弧线 ----

class _ArcTab extends ConsumerStatefulWidget {
  const _ArcTab({required this.bookId});

  final int bookId;

  @override
  ConsumerState<_ArcTab> createState() => _ArcTabState();
}

class _ArcTabState extends ConsumerState<_ArcTab> {
  List<StoryArc> _arcs = [];
  Map<int, List<ArcNode>> _nodes = {};
  bool _loading = true;
  String? _error;

  static const _arcStatusLabels = {
    'active': '进行中',
    'paused': '暂停',
    'completed': '已完成',
    'abandoned': '已放弃',
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final dao = ref.read(storyArcDaoProvider);
      final arcs = await dao.listArcsByBook(widget.bookId);
      final nodes = <int, List<ArcNode>>{};
      for (final arc in arcs) {
        nodes[arc.id] = await dao.listNodesByArc(arc.id);
      }
      if (!mounted) return;
      setState(() {
        _arcs = arcs;
        _nodes = nodes;
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('加载失败：$_error'));

    return Column(
      children: [
        Expanded(
          child: _arcs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.route_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      const Text('暂无故事弧线'),
                      const SizedBox(height: 4),
                      Text(
                        '弧线代表跨章并行叙事线，如主线 / 感情线 / 反派线',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final arc in _arcs) _arcCard(arc),
                  ],
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _showArcDialog(null),
              icon: const Icon(Icons.add),
              label: const Text('添加弧线'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _arcCard(StoryArc arc) {
    final nodes = _nodes[arc.id] ?? const <ArcNode>[];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    arc.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(_arcStatusLabels[arc.status] ?? arc.status),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
            if (arc.description != null && arc.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(arc.description!),
              ),
            const SizedBox(height: 8),
            for (final node in nodes) _nodeRow(arc.id, node),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showNodeDialog(arc.id, null),
                  child: const Text('加节点'),
                ),
                TextButton(
                  onPressed: () => _showArcDialog(arc),
                  child: const Text('编辑'),
                ),
                TextButton(
                  onPressed: () => _removeArc(arc),
                  child: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nodeRow(int arcId, ArcNode node) {
    final landed = node.chapterId != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            landed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: landed
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '第 ${node.targetSeq} 章${landed ? '（已落地）' : ''}'
              '${node.summary == null ? '' : ' · ${node.summary}'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: '编辑节点',
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: () => _showNodeDialog(arcId, node),
          ),
          IconButton(
            tooltip: '删除节点',
            icon: const Icon(Icons.delete_outline, size: 16),
            onPressed: () async {
              await ref.read(storyArcDaoProvider).deleteNodeById(node.id);
              await _reload();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _removeArc(StoryArc arc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除弧线'),
        content: Text('确定删除「${arc.name}」及其全部节点？'),
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
    await ref.read(storyArcDaoProvider).deleteArc(arc.id);
    await _reload();
  }

  Future<void> _showArcDialog(StoryArc? existing) async {
    final result = await showDialog<({String name, String status, String desc})>(
      context: context,
      builder: (ctx) => _ArcEditDialog(existing: existing),
    );
    if (result == null) return;
    final dao = ref.read(storyArcDaoProvider);
    if (existing == null) {
      await dao.insertArc(
        StoryArcsCompanion.insert(
          bookId: widget.bookId,
          name: result.name,
          status: Value(result.status),
          description: Value(result.desc.isEmpty ? null : result.desc),
        ),
      );
    } else {
      await dao.updateArcById(
        existing.id,
        StoryArcsCompanion(
          name: Value(result.name),
          status: Value(result.status),
          description: Value(result.desc.isEmpty ? null : result.desc),
        ),
      );
    }
    await _reload();
  }

  Future<void> _showNodeDialog(int arcId, ArcNode? existing) async {
    final result = await showDialog<({int targetSeq, String summary})>(
      context: context,
      builder: (ctx) => _NodeEditDialog(existing: existing),
    );
    if (result == null) return;
    final dao = ref.read(storyArcDaoProvider);
    if (existing == null) {
      await dao.insertNode(
        ArcNodesCompanion.insert(
          arcId: arcId,
          targetSeq: result.targetSeq,
          summary: Value(result.summary.isEmpty ? null : result.summary),
        ),
      );
    } else {
      await dao.updateNodeById(
        existing.id,
        ArcNodesCompanion(
          targetSeq: Value(result.targetSeq),
          summary: Value(result.summary.isEmpty ? null : result.summary),
        ),
      );
    }
    await _reload();
  }
}

// ---- 编辑对话框 ----

class _LocationEditDialog extends StatefulWidget {
  const _LocationEditDialog({required this.existing});

  final Location? existing;

  @override
  State<_LocationEditDialog> createState() => _LocationEditDialogState();
}

class _LocationEditDialogState extends State<_LocationEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  String _type = '其他';

  static const _types = ['大陆', '国家', '城市', '建筑', '室内', '野外', '其他'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _desc = TextEditingController(text: widget.existing?.description ?? '');
    _type = widget.existing?.type ?? '其他';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? '添加地点' : '编辑地点'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: isNew,
              decoration: const InputDecoration(labelText: '地点名 *'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '地点类型'),
              items: [
                for (final t in _types)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _type = v ?? '其他'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: '描述'),
              maxLines: 3,
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
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((
              name: name,
              type: _type,
              desc: _desc.text.trim(),
            ));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _ArcEditDialog extends StatefulWidget {
  const _ArcEditDialog({required this.existing});

  final StoryArc? existing;

  @override
  State<_ArcEditDialog> createState() => _ArcEditDialogState();
}

class _ArcEditDialogState extends State<_ArcEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  String _status = 'active';

  static const _statuses = ['active', 'paused', 'completed', 'abandoned'];
  static const _statusLabels = {
    'active': '进行中',
    'paused': '暂停',
    'completed': '已完成',
    'abandoned': '已放弃',
  };

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _desc = TextEditingController(text: widget.existing?.description ?? '');
    _status = widget.existing?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? '添加弧线' : '编辑弧线'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: isNew,
              decoration: const InputDecoration(labelText: '弧线名（如 主线）*'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: '状态'),
              items: [
                for (final s in _statuses)
                  DropdownMenuItem(
                    value: s,
                    child: Text(_statusLabels[s] ?? s),
                  ),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: '描述'),
              maxLines: 3,
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
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((
              name: name,
              status: _status,
              desc: _desc.text.trim(),
            ));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _NodeEditDialog extends StatefulWidget {
  const _NodeEditDialog({required this.existing});

  final ArcNode? existing;

  @override
  State<_NodeEditDialog> createState() => _NodeEditDialogState();
}

class _NodeEditDialogState extends State<_NodeEditDialog> {
  late final TextEditingController _seq;
  late final TextEditingController _summary;

  @override
  void initState() {
    super.initState();
    _seq = TextEditingController(text: widget.existing?.targetSeq.toString() ?? '');
    _summary = TextEditingController(text: widget.existing?.summary ?? '');
  }

  @override
  void dispose() {
    _seq.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? '添加节点' : '编辑节点'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _seq,
              autofocus: isNew,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '预估推进到第几章 *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _summary,
              decoration: const InputDecoration(labelText: '节点概述'),
              maxLines: 3,
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
          onPressed: () {
            final seq = int.tryParse(_seq.text.trim());
            if (seq == null) return;
            Navigator.of(context).pop((
              targetSeq: seq,
              summary: _summary.text.trim(),
            ));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
