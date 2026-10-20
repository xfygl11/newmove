import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gate_issue.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../../widgets/gate_issue_list.dart';
import 'novel_models.dart';
import 'novel_providers.dart';
import 'outline_gate.dart';
import 'truth_file_kinds.dart';
import 'truth_file_store.dart';

/// 大纲独立编辑页：双视图结构。
///
/// - 章节目标：自由文本 Markdown 大纲，逐章卡片编辑。
/// - 结构化大纲：场景清单 + 叙事道具表，写入 `outline_structure` TruthFile。
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
          return _OutlineTabbedBody(book: book);
        },
      ),
    );
  }
}

class _OutlineTabbedBody extends ConsumerStatefulWidget {
  const _OutlineTabbedBody({required this.book});

  final NovelBook book;

  @override
  ConsumerState<_OutlineTabbedBody> createState() => _OutlineTabbedBodyState();
}

class _OutlineTabbedBodyState extends ConsumerState<_OutlineTabbedBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '章节目标'),
              Tab(text: '结构化大纲'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ChapterGoalsView(book: widget.book),
                _StructuredOutlineView(book: widget.book),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 章节目标视图：逐章 Markdown 编辑。
class _ChapterGoalsView extends ConsumerStatefulWidget {
  const _ChapterGoalsView({required this.book});

  final NovelBook book;

  @override
  ConsumerState<_ChapterGoalsView> createState() => _ChapterGoalsViewState();
}

class _ChapterGoalsViewState extends ConsumerState<_ChapterGoalsView> {
  late final List<_ChapterGoal> _goals;
  late final List<TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _goals = _parseOutline(widget.book.outline);
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

  static List<_ChapterGoal> _parseOutline(String? outline) {
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
        final updated = current.detailText.isEmpty
            ? line
            : '${current.detailText}\n$line';
        goals[goals.length - 1] = current.copyWith(detailText: updated);
      }
    }
    return goals;
  }

  String _serialize() {
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
      final text = _serialize();
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
      for (var i = 0; i < _goals.length; i++) {
        _goals[i] = _goals[i].copyWith(seq: i + 1);
      }
    });
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
}

/// 结构化大纲视图：场景 + 道具编辑 + 门体检。
class _StructuredOutlineView extends ConsumerStatefulWidget {
  const _StructuredOutlineView({required this.book});

  final NovelBook book;

  @override
  ConsumerState<_StructuredOutlineView> createState() =>
      _StructuredOutlineViewState();
}

class _StructuredOutlineViewState extends ConsumerState<_StructuredOutlineView> {
  List<OutlineScene> _scenes = [];
  List<OutlineProp> _props = [];
  bool _loading = true;
  bool _saving = false;
  int? _currentRevision;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dao = ref.read(truthFileDaoProvider);
    final store = TruthFileStore(dao: dao, bookId: widget.book.id);
    final row = await store.readRow(TruthFileKind.outlineStructure);
    final json = await store.read(TruthFileKind.outlineStructure);
    setState(() {
      _scenes = [
        for (final s in json['scenes'] is List
            ? json['scenes'] as List<dynamic>
            : const <dynamic>[])
          OutlineScene.fromJson(Map<String, dynamic>.from(s as Map)),
      ];
      _props = [
        for (final p in json['props'] is List
            ? json['props'] as List<dynamic>
            : const <dynamic>[])
          OutlineProp.fromJson(Map<String, dynamic>.from(p as Map)),
      ];
      _currentRevision = row?.revision;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dao = ref.read(truthFileDaoProvider);
      final store = TruthFileStore(dao: dao, bookId: widget.book.id);
      await store.write(
        TruthFileKind.outlineStructure,
        {
          'scenes': [for (final s in _scenes) s.toJson()],
          'props': [for (final p in _props) p.toJson()],
        },
        expectedRevision: _currentRevision,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('结构化大纲已保存')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addScene() {
    setState(() {
      _scenes.add(const OutlineScene(name: ''));
    });
  }

  void _removeScene(int index) {
    setState(() => _scenes.removeAt(index));
  }

  void _updateScene(int index, OutlineScene scene) {
    setState(() => _scenes[index] = scene);
  }

  void _addProp() {
    setState(() {
      _props.add(const OutlineProp(name: ''));
    });
  }

  void _removeProp(int index) {
    setState(() => _props.removeAt(index));
  }

  void _updateProp(int index, OutlineProp prop) {
    setState(() => _props[index] = prop);
  }

  int _chapterCount() {
    if (widget.book.outline == null || widget.book.outline!.trim().isEmpty) {
      return 0;
    }
    final re = RegExp(r'^#{0,6}\s*第\s*\d+\s*章', multiLine: true);
    return re.allMatches(widget.book.outline!).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final issues = OutlineGate.validate(
      scenes: _scenes,
      props: _props,
      episodeCount: _chapterCount(),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GateIssueList(
                issues: issues,
                title: '大纲体检',
                showEmpty: true,
                onRecord: () => ref.read(gateLogDaoProvider).recordValidation(
                  subjectType: GateSubjects.outline,
                  subjectLabel: '大纲结构 · 体检',
                  gates: const ['大纲结构门'],
                  issues: issues,
                  projectId: widget.book.projectId,
                ),
              ),
              const SizedBox(height: 16),
              _SceneSection(
                scenes: _scenes,
                onAdd: _addScene,
                onRemove: _removeScene,
                onUpdate: _updateScene,
              ),
              const SizedBox(height: 16),
              _PropSection(
                props: _props,
                onAdd: _addProp,
                onRemove: _removeProp,
                onUpdate: _updateProp,
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存结构化大纲'),
            ),
          ),
        ),
      ],
    );
  }
}

/// 场景编辑区块。
class _SceneSection extends StatefulWidget {
  const _SceneSection({
    required this.scenes,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  final List<OutlineScene> scenes;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, OutlineScene scene) onUpdate;

  @override
  State<_SceneSection> createState() => _SceneSectionState();
}

class _SceneSectionState extends State<_SceneSection> {
  late List<TextEditingController> _nameControllers = [];
  late List<TextEditingController> _avoidanceControllers = [];
  late List<TextEditingController> _descriptionControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _SceneSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    final currentCount = _nameControllers.length;
    final newCount = widget.scenes.length;
    if (currentCount > newCount) {
      for (var i = currentCount - 1; i >= newCount; i--) {
        _nameControllers[i].dispose();
        _nameControllers.removeAt(i);
        _avoidanceControllers[i].dispose();
        _avoidanceControllers.removeAt(i);
        _descriptionControllers[i].dispose();
        _descriptionControllers.removeAt(i);
      }
    } else if (currentCount < newCount) {
      for (var i = currentCount; i < newCount; i++) {
        _nameControllers.add(TextEditingController());
        _avoidanceControllers.add(TextEditingController());
        _descriptionControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _avoidanceControllers) {
      c.dispose();
    }
    for (final c in _descriptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenes = widget.scenes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '场景（${scenes.length} 个，主场景 ${scenes.where((s) => s.isPrimary).length} 个）',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add),
                  tooltip: '添加场景',
                ),
              ],
            ),
            const Divider(),
            for (var i = 0; i < scenes.length; i++)
              _SceneCard(
                scene: scenes[i],
                nameController: _nameControllers[i],
                avoidanceController: _avoidanceControllers[i],
                descriptionController: _descriptionControllers[i],
                onNameChanged: (name) => widget.onUpdate(i, scenes[i].copyWith(name: name)),
                onPrimaryChanged: (isPrimary) => widget.onUpdate(i, scenes[i].copyWith(isPrimary: isPrimary)),
                onAvoidanceChanged: (avoidance) => widget.onUpdate(i, scenes[i].copyWith(onceAvoidance: avoidance)),
                onDescriptionChanged: (description) => widget.onUpdate(i, scenes[i].copyWith(description: description)),
                onRemove: () => widget.onRemove(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.nameController,
    required this.avoidanceController,
    required this.descriptionController,
    required this.onNameChanged,
    required this.onPrimaryChanged,
    required this.onAvoidanceChanged,
    required this.onDescriptionChanged,
    required this.onRemove,
  });

  final OutlineScene scene;
  final TextEditingController nameController;
  final TextEditingController avoidanceController;
  final TextEditingController descriptionController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<bool> onPrimaryChanged;
  final ValueChanged<String> onAvoidanceChanged;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  onChanged: onNameChanged,
                  decoration: const InputDecoration(
                    hintText: '场景名称',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                tooltip: '删除场景',
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: scene.isPrimary,
                onChanged: (v) => onPrimaryChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Text('主场景'),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: avoidanceController,
                  onChanged: onAvoidanceChanged,
                  decoration: const InputDecoration(
                    hintText: '一次性场景规避方案（如：复用环境资产）',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: descriptionController,
            onChanged: onDescriptionChanged,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: '场景梗概（叙述体，多人同框标拆解方案）',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 道具编辑区块。
class _PropSection extends StatefulWidget {
  const _PropSection({
    required this.props,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  final List<OutlineProp> props;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, OutlineProp prop) onUpdate;

  @override
  State<_PropSection> createState() => _PropSectionState();
}

class _PropSectionState extends State<_PropSection> {
  late List<TextEditingController> _nameControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _PropSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    final currentCount = _nameControllers.length;
    final newCount = widget.props.length;
    if (currentCount > newCount) {
      for (var i = currentCount - 1; i >= newCount; i--) {
        _nameControllers[i].dispose();
        _nameControllers.removeAt(i);
      }
    } else if (currentCount < newCount) {
      for (var i = currentCount; i < newCount; i++) {
        _nameControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final narrativeCount = props.where((p) => p.isNarrative).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '道具（${props.length} 个，叙事道具 $narrativeCount 件）',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add),
                  tooltip: '添加道具',
                ),
              ],
            ),
            const Divider(),
            for (var i = 0; i < props.length; i++)
              _PropCard(
                prop: props[i],
                nameController: _nameControllers[i],
                onNameChanged: (name) => widget.onUpdate(i, props[i].copyWith(name: name)),
                onNarrativeChanged: (isNarrative) => widget.onUpdate(i, props[i].copyWith(isNarrative: isNarrative)),
                onRemove: () => widget.onRemove(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _PropCard extends StatelessWidget {
  const _PropCard({
    required this.prop,
    required this.nameController,
    required this.onNameChanged,
    required this.onNarrativeChanged,
    required this.onRemove,
  });

  final OutlineProp prop;
  final TextEditingController nameController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<bool> onNarrativeChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: nameController,
              onChanged: onNameChanged,
              decoration: const InputDecoration(
                hintText: '道具名称',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Checkbox(
            value: prop.isNarrative,
            onChanged: (v) => onNarrativeChanged(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const Text('叙事'),
          const SizedBox(width: 8),
          IconButton(
            tooltip: '删除道具',
            onPressed: onRemove,
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
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
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
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
