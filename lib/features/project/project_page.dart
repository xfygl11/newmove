import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'project_providers.dart';

/// 首页：项目列表 + 新建项目。
class ProjectPage extends ConsumerWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('小说动漫工坊'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '备份',
            onSelected: (v) => _onBackupAction(v, context, ref),
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.backup, size: 18),
                    SizedBox(width: 8),
                    Text('导出全部项目'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 18),
                    SizedBox(width: 8),
                    Text('从备份导入'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: '新建项目',
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('还没有项目'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('新建项目'),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) =>
                _ProjectCard(project: projects[index]),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _CreateProjectDialog(),
    );
  }

  /// 备份菜单分发：导出全部 / 导入（含冲突检测）。
  Future<void> _onBackupAction(
    String action,
    BuildContext context,
    WidgetRef ref,
  ) async {
    switch (action) {
      case 'export_all':
        await _exportAll(context, ref);
      case 'import':
        await _importBackup(context, ref);
    }
  }

  /// 全库备份：导出所有项目 + 供应商 + 媒体。
  Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ref.read(backupServiceProvider).exportAll();
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: '全部项目备份'),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('全库备份已导出')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }

  /// 从 zip 备份导入项目（含同名冲突检测）。
  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (picked.isEmpty || picked.single.path == null) return;

    // 冲突检测：包内项目名与本地同名时提示用户确认。
    final conflicts = await ref
        .read(backupServiceProvider)
        .findConflicts(picked.single.path!);
    if (conflicts.isNotEmpty && context.mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('同名项目'),
          content: Text(
            '以下项目名在本地已存在，导入将创建同名的新项目：\n'
            '· ${conflicts.join('\n· ')}\n\n是否继续？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('继续导入'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    try {
      final newId = await ref
          .read(backupServiceProvider)
          .importProject(picked.single.path!);
      ref.invalidate(projectListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导入成功（id $newId）')));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    }
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/novel/${project.id}'),
        onLongPress: () => _showProjectMenu(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.auto_stories, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.status,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 长按项目卡弹出操作菜单：编辑 / 导出备份 / 删除。
  Future<void> _showProjectMenu(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('编辑项目信息'),
            onTap: () => Navigator.of(ctx).pop('edit'),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('导出备份'),
            onTap: () => Navigator.of(ctx).pop('export'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('删除项目', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.of(ctx).pop('delete'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'edit':
        await _showEditDialog(context, ref);
      case 'export':
        await _exportBackup(context, ref);
      case 'delete':
        await _confirmDelete(context, ref);
    }
  }

  /// 编辑项目信息（名称 / 题材 / 描述）。
  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController(text: project.name);
    final genre = TextEditingController(text: project.genre ?? '');
    final desc = TextEditingController(text: project.description ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑项目信息'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: '项目名称 *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: genre,
                decoration: const InputDecoration(labelText: '题材（可选）'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: desc,
                decoration: const InputDecoration(labelText: '描述（可选）'),
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
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(projectDaoProvider)
          .replaceProject(
            project.copyWith(
              name: name.text.trim(),
              genre: Value(
                genre.text.trim().isEmpty ? null : genre.text.trim(),
              ),
              description: Value(
                desc.text.trim().isEmpty ? null : desc.text.trim(),
              ),
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('项目信息已更新')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导出备份'),
        content: Text('将项目「${project.name}」的全部数据与媒体导出为 zip？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('导出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final path = await ref
          .read(backupServiceProvider)
          .exportProject(project.id);
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: '项目「${project.name}」备份'),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除项目'),
        content: Text('确定删除项目「${project.name}」？该操作不可撤销。'),
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
      await ref.read(cascadeDaoProvider).deleteProjectCascade(project.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('项目已删除')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }
}

class _CreateProjectDialog extends ConsumerStatefulWidget {
  const _CreateProjectDialog();

  @override
  ConsumerState<_CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _genre = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _genre.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final genreText = _genre.text.trim();
    final descriptionText = _description.text.trim();
    try {
      await ref
          .read(projectDaoProvider)
          .insertProject(
            ProjectsCompanion.insert(
              name: _name.text.trim(),
              genre: genreText.isEmpty ? const Value(null) : Value(genreText),
              description: descriptionText.isEmpty
                  ? const Value(null)
                  : Value(descriptionText),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('创建失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建项目'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '项目名称'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写项目名称' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _genre,
              decoration: const InputDecoration(labelText: '题材（可选）'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: '描述（可选）'),
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
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }
}
