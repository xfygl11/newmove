import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'prompt_preset_service.dart';

/// 提示词预设包管理页（M33）。
///
/// 预设包是命名的一组槽位覆盖，可一键应用到项目。
class PromptPresetPage extends ConsumerWidget {
  const PromptPresetPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('提示词预设包'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: '从当前项目保存预设',
            onPressed: () => _showSaveAsPresetDialog(context, ref),
          ),
        ],
      ),
      body: _PresetList(projectId: projectId),
    );
  }

  Future<void> _showSaveAsPresetDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存为预设包'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '预设包名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final service = _presetServiceOf(ref);
    try {
      await service.saveAsPreset(name: name, projectId: projectId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存为预设包')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }
}

class _PresetList extends ConsumerStatefulWidget {
  const _PresetList({required this.projectId});

  final int projectId;

  @override
  ConsumerState<_PresetList> createState() => _PresetListState();
}

class _PresetListState extends ConsumerState<_PresetList> {
  List<PromptPreset>? _presets;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = _presetServiceOf(ref);
      final presets = await service.listPresets();
      if (!mounted) return;
      setState(() {
        _presets = presets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败：$_error'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }

    final presets = _presets ?? [];
    if (presets.isEmpty) {
      return const Center(child: Text('暂无预设包'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: presets.length,
      itemBuilder: (context, index) => _PresetTile(
        preset: presets[index],
        projectId: widget.projectId,
        onChanged: _load,
      ),
    );
  }
}

class _PresetTile extends ConsumerStatefulWidget {
  const _PresetTile({
    required this.preset,
    required this.projectId,
    required this.onChanged,
  });

  final PromptPreset preset;
  final int projectId;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_PresetTile> createState() => _PresetTileState();
}

class _PresetTileState extends ConsumerState<_PresetTile> {
  bool _applying = false;

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);
    try {
      final service = _presetServiceOf(ref);
      final count = await service.applyPreset(
        widget.preset.id,
        widget.projectId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已应用 $count 个槽位')),
      );
      await widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('应用失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除预设包'),
        content: Text('确定删除「${widget.preset.name}」？'),
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

    try {
      final service = _presetServiceOf(ref);
      await service.deletePreset(widget.preset.id);
      if (!mounted) return;
      await widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _decodeSlots(widget.preset.slots);
    final slotCount = slots.length;

    return Card(
      child: ListTile(
        title: Text(widget.preset.name),
        subtitle: Text('$slotCount 个槽位'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: _applying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              tooltip: '应用到当前项目',
              onPressed: _applying ? null : _apply,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: _delete,
            ),
          ],
        ),
        onTap: () => _showSlotsDialog(context),
      ),
    );
  }

  void _showSlotsDialog(BuildContext context) {
    final slots = _decodeSlots(widget.preset.slots);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('预设包「${widget.preset.name}」'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in slots.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(entry.value),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

PromptPresetService _presetServiceOf(WidgetRef ref) {
  return PromptPresetService(
    presetDao: ref.read(promptPresetDaoProvider),
    overrideDao: ref.read(promptOverrideDaoProvider),
  );
}

Map<String, String> _decodeSlots(String slotsJson) {
  try {
    final decoded = jsonDecode(slotsJson);
    if (decoded is Map<String, dynamic>) {
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    }
  } catch (_) {}
  return const {};
}
