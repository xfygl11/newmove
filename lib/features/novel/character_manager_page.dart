import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/active_llm.dart';
import '../../core/gate_issue.dart';
import '../../core/json_values.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/character_relation_graph.dart';
import '../../widgets/gate_issue_list.dart';
import 'character_gate.dart';
import 'novel_models.dart';
import 'novel_providers.dart';
import 'truth_file_kinds.dart';

/// 角色矩阵管理页：增删改角色，写回 TruthFile。
///
/// 数据源为 character_matrix TruthFile；与 Settler 定稿固化共用同一存储，
/// 手工编辑后定稿会按名字合并（同名覆盖字段，新名追加）。
///
/// M23 T24.6 起页面顶部并列「角色体检」：分档缺档、分档超限、引文未在正文
/// 命中，全部只提示不阻塞。
class CharacterManagerPage extends ConsumerWidget {
  const CharacterManagerPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(novelBookByProjectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('角色管理')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('尚未创建小说书'));
          }
          return _CharacterList(bookId: book.id, projectId: projectId);
        },
      ),
    );
  }
}

class _CharacterList extends ConsumerStatefulWidget {
  const _CharacterList({required this.bookId, required this.projectId});

  final int bookId;
  final int projectId;

  @override
  ConsumerState<_CharacterList> createState() => _CharacterListState();
}

/// 内部 State：读取并管理角色列表。
class _CharacterListState extends ConsumerState<_CharacterList> {
  List<CharacterSpec> _characters = [];
  List<GateIssue> _issues = [];
  List<CharacterRelation> _relations = [];
  List<CharacterRelation> _history = [];
  String _chapterContext = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.bookId >= 0) {
      _reload();
    } else {
      _loading = false;
    }
  }

  Future<void> _reload() async {
    try {
      final chars = await _load();
      final context_ = await _chapterContextOf(widget.bookId);
      final relations = await ref
          .read(characterRelationDaoProvider)
          .currentEdges(widget.bookId);
      final history = await ref
          .read(characterRelationDaoProvider)
          .listByBook(widget.bookId);
      if (!mounted) return;
      setState(() {
        _characters = chars;
        _chapterContext = context_;
        _relations = relations;
        _history = history;
        _issues = CharacterGate.validate(
          characters: chars,
          content: context_,
          relations: relations,
        );
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
    if (widget.bookId < 0) return const SizedBox.shrink();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('加载失败：$_error'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 4),
        _CharacterGatePanel(
          issues: _issues,
          onRecord: () => ref.read(gateLogDaoProvider).recordValidation(
            subjectType: GateSubjects.characters,
            subjectLabel: '角色矩阵 · 体检',
            gates: const ['角色门'],
            issues: _issues,
            projectId: widget.projectId,
          ),
        ),
        const SizedBox(height: 12),
        if (_relations.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关系图谱', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  CharacterRelationGraph(edges: _relations),
                ],
              ),
            ),
          ),
        if (_superseded.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关系历史', style: Theme.of(context).textTheme.titleMedium),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    child: Text(
                      '已被新版本取代的关系，按时间倒序',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Divider(),
                  for (final row in _superseded) _RelationHistoryRow(row: row),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        for (final character in _sorted)
          _CharacterCard(
            character: character,
            onEdit: () => _showEditDialog(character),
            onDelete: () => _confirmDelete(character),
            onDesignVoice: () => _designVoice(character),
          ),
        _AddCharacterTile(onTap: () => _showEditDialog(null)),
      ],
    );
  }

  /// 主角在前、其它按分档顺序、未分档的最后。
  List<CharacterSpec> get _sorted {
    final rank = {
      CharacterTiers.lead: 0,
      CharacterTiers.support: 1,
      CharacterTiers.functional: 2,
      CharacterTiers.other: 3,
    };
    final list = List<CharacterSpec>.from(_characters);
    list.sort((a, b) =>
        (rank[a.tier] ?? 4).compareTo(rank[b.tier] ?? 4));
    return list;
  }

  /// 已被新版本取代的关系，只读回看用。
  List<CharacterRelation> get _superseded =>
      _history.where((row) => row.isCurrent == 0).toList();

  Future<List<CharacterSpec>> _load() async {
    final store = ref.read(novelServiceProvider).storeFor(widget.bookId);
    final json = await store.read(TruthFileKind.characterMatrix);
    final list = jsonList(json['characters']);
    return [for (final c in list) CharacterSpec.fromJson(jsonMap(c))];
  }

  /// 取最后一章的正文作为引文核对的语料；没有章节时返回空串。
  Future<String> _chapterContextOf(int bookId) async {
    final chapters = await ref.read(chaptersByBookProvider(bookId).future);
    if (chapters.isEmpty) return '';
    return chapters.last.content ?? '';
  }

  Future<void> _persist(List<CharacterSpec> chars) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(novelServiceProvider).storeFor(widget.bookId).write(
        TruthFileKind.characterMatrix,
        {
          'characters': [for (final c in chars) c.toJson()],
        },
      );
      if (!mounted) return;
      setState(() {
        _characters = chars;
        _issues = CharacterGate.validate(
          characters: chars,
          content: _chapterContext,
        );
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

  Future<void> _showEditDialog(CharacterSpec? existing) async {
    final spec = await showDialog<CharacterSpec>(
      context: context,
      builder: (ctx) => _CharacterEditDialog(existing: existing),
    );
    if (spec == null) return;

    if (existing == null) {
      await _persist([..._characters, spec]);
    } else {
      final updated = [
        for (final c in _characters) c.name == existing.name ? spec : c,
      ];
      await _persist(updated);
    }
  }

  /// AI 设计音色：结果先弹出来给用户看，确认后才写回角色。
  Future<void> _designVoice(CharacterSpec character) async {
    final llm = await ref.read(activeLlmProvider.future);
    if (!mounted || llm == null) {
      _toast('请先在设置里配置 LLM 供应商');
      return;
    }
    final context_ = '【作品上下文】$_chapterContext';
    final prompt =
        '【角色】${character.name}\n'
        '【定位】${character.role}\n'
        '【目标】${character.goal}\n'
        '【当前状态】${character.state}\n'
        '【表演风格】${character.performanceStyle}\n'
        '$context_\n\n'
        '请为该角色设计音色。';
    if (!await ConfirmSheet.confirm(
      context,
      objectName: character.name,
      quantity: '音色提示词 1 段',
      promptPreview: prompt,
      params: [
        '供应商：${llm.provider.label}',
        '模型：${llm.modelId}',
        '音色用于 TTS，与角色四视图提示词解耦',
        '结果先弹出来确认，写回后才生效',
      ],
      title: 'AI 设计音色',
      gate: '角色设定（一次 LLM 调用）',
    )) {
      return;
    }
    String text;
    try {
      text = await ref.read(novelAgentsProvider).designVoice(
        character: character,
        context: context_,
        llm: llm,
        bookId: widget.bookId,
      );
    } catch (e) {
      if (mounted) _toast('生成失败：$e');
      return;
    }
    if (!mounted || text.trim().isEmpty) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('为 ${character.name} 生成音色'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(text.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('放弃'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('写入角色'),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    final updated = [
      for (final c in _characters)
        c.name == character.name
            ? CharacterSpec(
                name: c.name,
                role: c.role,
                goal: c.goal,
                state: c.state,
                relations: c.relations,
                tier: c.tier,
                arc: c.arc,
                evidenceQuotes: c.evidenceQuotes,
                voiceDesign: text.trim(),
                performanceStyle: c.performanceStyle,
              )
            : c,
    ];
    await _persist(updated);
    _toast('已写入音色');
  }

  Future<void> _confirmDelete(CharacterSpec target) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除角色'),
        content: Text('确定删除「${target.name}」？'),
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
    await _persist([
      for (final c in _characters)
        if (c.name != target.name) c,
    ]);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 角色体检面板：无问题时不占位。
class _CharacterGatePanel extends StatelessWidget {
  const _CharacterGatePanel({required this.issues, required this.onRecord});

  final List<GateIssue> issues;
  final Future<bool> Function() onRecord;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GateIssueList(
          issues: issues,
          title: '角色体检',
          onRecord: onRecord,
        ),
      ),
    );
  }
}

/// 新增 / 编辑角色的对话框。保存时返回构造好的 [CharacterSpec]，取消返回 null。
class _CharacterEditDialog extends StatefulWidget {
  const _CharacterEditDialog({this.existing});

  final CharacterSpec? existing;

  @override
  State<_CharacterEditDialog> createState() => _CharacterEditDialogState();
}

class _CharacterEditDialogState extends State<_CharacterEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _goal;
  late final TextEditingController _state;
  late final TextEditingController _relations;
  late final TextEditingController _arc;
  late final TextEditingController _quotes;
  late final TextEditingController _performance;
  late final TextEditingController _voice;
  late String _tier;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _role = TextEditingController(text: existing?.role ?? '');
    _goal = TextEditingController(text: existing?.goal ?? '');
    _state = TextEditingController(text: existing?.state ?? '');
    _relations = TextEditingController(text: existing?.relations ?? '');
    _arc = TextEditingController(text: existing?.arc ?? '');
    _quotes = TextEditingController(text: existing?.evidenceQuotes ?? '');
    _performance = TextEditingController(
      text: existing?.performanceStyle ?? '',
    );
    _voice = TextEditingController(text: existing?.voiceDesign ?? '');
    final tier = existing?.tier ?? '';
    _tier = CharacterTiers.isKnown(tier) ? tier : CharacterTiers.lead;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _goal.dispose();
    _state.dispose();
    _relations.dispose();
    _arc.dispose();
    _quotes.dispose();
    _performance.dispose();
    _voice.dispose();
    super.dispose();
  }

  CharacterSpec _build() => CharacterSpec(
    name: _name.text.trim(),
    role: _role.text.trim(),
    goal: _goal.text.trim(),
    state: _state.text.trim(),
    relations: _relations.text.trim(),
    tier: _tier,
    arc: _arc.text.trim(),
    evidenceQuotes: _quotes.text.trim(),
    voiceDesign: _voice.text.trim(),
    performanceStyle: _performance.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '新增角色' : '编辑角色'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              decoration: const InputDecoration(labelText: '姓名 *'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _tier,
              decoration: const InputDecoration(labelText: '分档'),
              items: [
                for (final t in CharacterTiers.all)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _tier = v ?? _tier),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _role,
              decoration: const InputDecoration(labelText: '定位 / 角色'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _goal,
              decoration: const InputDecoration(labelText: '目标'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _state,
              decoration: const InputDecoration(labelText: '当前状态'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _relations,
              decoration: const InputDecoration(
                labelText: '关系（用「；」分隔）',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _arc,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '人物弧光（起点 → 弧光 → 终点）',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quotes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '原文引文（多条用「；」分隔）',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _performance,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '表演风格'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _voice,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '音色设计（可手改，或用卡片的「AI 设计音色」）',
              ),
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
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_build()),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.onEdit,
    required this.onDelete,
    required this.onDesignVoice,
  });

  final CharacterSpec character;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDesignVoice;

  @override
  Widget build(BuildContext context) {
    final fields = <String, String>{
      if (character.role.isNotEmpty) '定位': character.role,
      if (character.goal.isNotEmpty) '目标': character.goal,
      if (character.state.isNotEmpty) '状态': character.state,
      if (character.arc.isNotEmpty) '弧光': character.arc,
      if (character.performanceStyle.isNotEmpty)
        '表演': character.performanceStyle,
      if (character.evidenceQuotes.isNotEmpty) '引文': character.evidenceQuotes,
      if (character.voiceDesign.isNotEmpty) '音色': character.voiceDesign,
      if (character.relations.isNotEmpty) '关系': character.relations,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            character.name.isNotEmpty ? character.name[0] : '?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                character.name.isEmpty ? '（未命名）' : character.name,
              ),
            ),
            if (CharacterTiers.isKnown(character.tier)) ...[
              const SizedBox(width: 6),
              Chip(
                label: Text(character.tier),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: fields.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in fields.entries)
                    Text(
                      '${e.key}：${e.value}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'voice') {
              onDesignVoice();
            } else if (action == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'voice', child: Text('AI 设计音色')),
            PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _RelationHistoryRow extends StatelessWidget {
  const _RelationHistoryRow({required this.row});

  final CharacterRelation row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapterSeq = row.chapterSeq;
    final when = _formatTime(row.createdAt);
    final meta = chapterSeq == null
        ? when
        : '第$chapterSeq章 · $when';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(text: row.source),
                const TextSpan(text: ' → '),
                TextSpan(text: row.target),
                if (row.description.trim().isNotEmpty)
                  TextSpan(
                    text: '  ${row.description.trim()}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (meta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                meta,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}

class _AddCharacterTile extends StatelessWidget {
  const _AddCharacterTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: const Icon(Icons.person_add_alt_1, size: 22),
        title: const Text('新增角色'),
        trailing: const Icon(Icons.add, size: 20),
        onTap: onTap,
      ),
    );
  }
}
