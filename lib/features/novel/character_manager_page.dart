import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'novel_models.dart';
import 'novel_providers.dart';
import 'truth_file_kinds.dart';

/// 角色矩阵管理页：增删改角色（姓名/定位/目标/状态/关系），写回 TruthFile。
///
/// 数据源为 character_matrix TruthFile；与 Settler 定稿固化共用同一存储，
/// 手工编辑后定稿会按名字合并（同名覆盖字段，新名追加）。
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
          return _CharacterList(bookId: book.id);
        },
      ),
    );
  }
}

class _CharacterList extends ConsumerStatefulWidget {
  const _CharacterList({required this.bookId});

  final int bookId;

  @override
  ConsumerState<_CharacterList> createState() => _CharacterListState();
}

/// 内部 State：读取并管理角色列表。
class _CharacterListState extends ConsumerState<_CharacterList> {
  List<CharacterSpec> _characters = [];
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    if (widget.bookId < 0) return const SizedBox.shrink();

    return FutureBuilder<List<CharacterSpec>>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        _characters = snap.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _characters.length + 1, // +1 为底部「新增角色」行
          itemBuilder: (context, i) {
            if (i >= _characters.length) {
              return _AddCharacterTile(onTap: () => _showEditDialog(null));
            }
            return _CharacterCard(
              character: _characters[i],
              onEdit: () => _showEditDialog(_characters[i]),
              onDelete: () => _confirmDelete(_characters[i]),
            );
          },
        );
      },
    );
  }

  Future<List<CharacterSpec>> _load() async {
    final store = ref.read(novelServiceProvider).storeFor(widget.bookId);
    final json = await store.read(TruthFileKind.characterMatrix);
    final list = json['characters'] as List<dynamic>? ?? const [];
    return [
      for (final c in list)
        CharacterSpec.fromJson((c as Map).cast<String, dynamic>()),
    ];
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
      setState(() => _characters = chars);
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
    final name = TextEditingController(text: existing?.name ?? '');
    final role = TextEditingController(text: existing?.role ?? '');
    final goal = TextEditingController(text: existing?.goal ?? '');
    final state_ = TextEditingController(text: existing?.state ?? '');
    final relations = TextEditingController(text: existing?.relations ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '新增角色' : '编辑角色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: existing == null,
                decoration: const InputDecoration(labelText: '姓名 *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: role,
                decoration: const InputDecoration(labelText: '定位 / 角色'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: goal,
                decoration: const InputDecoration(labelText: '目标'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: state_,
                decoration: const InputDecoration(labelText: '当前状态'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: relations,
                decoration: const InputDecoration(labelText: '关系（用「；」分隔）'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final spec = CharacterSpec(
      name: name.text.trim(),
      role: role.text.trim(),
      goal: goal.text.trim(),
      state: state_.text.trim(),
      relations: relations.text.trim(),
    );

    if (existing == null) {
      _persist([..._characters, spec]);
    } else {
      final updated = [
        for (final c in _characters) c.name == existing.name ? spec : c,
      ];
      _persist(updated);
    }
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
    _persist([
      for (final c in _characters)
        if (c.name != target.name) c,
    ]);
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.onEdit,
    required this.onDelete,
  });

  final CharacterSpec character;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fields = <String, String>{
      if (character.role.isNotEmpty) '定位': character.role,
      if (character.goal.isNotEmpty) '目标': character.goal,
      if (character.state.isNotEmpty) '状态': character.state,
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
        title: Text(character.name.isEmpty ? '（未命名）' : character.name),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: '删除',
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
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
