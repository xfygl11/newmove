import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/prompt_resolver.dart';
import '../../core/storage/providers.dart';
import '../../data/daos/prompt_override_dao.dart';

/// 提示词覆盖编辑器（M19 T21.11）。
///
/// 内置 skill 是打进 APK 的只读资源，用户改不了提示词。这一页列出全部
/// 可编辑插槽，支持保存项目级 / 全局级覆盖与恢复内置原文。覆盖按整段
/// 替换，不做局部合并。
class PromptOverridePage extends ConsumerWidget {
  const PromptOverridePage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('提示词')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: PromptResolver.allSlots.length,
        itemBuilder: (context, index) => _SlotTile(
          slot: PromptResolver.allSlots[index],
          projectId: projectId,
        ),
      ),
    );
  }
}

class _SlotTile extends ConsumerWidget {
  const _SlotTile({required this.slot, required this.projectId});

  final String slot;
  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(slot),
      trailing: PopupMenuButton<String>(
        onSelected: (action) async {
          if (action == 'reset') {
            await _reset(context, ref);
          } else {
            await _edit(context, ref, action);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'project', child: Text('编辑（项目级）')),
          PopupMenuItem(value: 'global', child: Text('编辑（全局级）')),
          PopupMenuItem(value: 'reset', child: Text('恢复内置原文')),
        ],
      ),
      onTap: () => _edit(context, ref, 'project'),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String initialScope,
  ) async {
    final dao = ref.read(promptOverrideDaoProvider);
    final project = await dao.find(
      PromptOverrideScopes.project, slot, projectId: projectId,
    );
    final global = await dao.find(PromptOverrideScopes.global, slot);
    // 编辑器初始值取当前生效的最高优先级正文。
    final initial = project?.body ?? global?.body ?? '';
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _EditorSheet(
        slot: slot,
        initial: initial,
        initialScope: initialScope,
        onSaved: (scope, text) =>
            _save(dialogContext, ref, scope, text),
        onReset: () => _reset(dialogContext, ref),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    String scope,
    String text,
  ) async {
    await ref.read(promptOverrideDaoProvider).upsert(
          scope: scope,
          key: slot,
          text: text,
          projectId: scope == PromptOverrideScopes.project ? projectId : null,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scope == PromptOverrideScopes.project ? '已保存项目级覆盖' : '已保存全局覆盖',
          ),
        ),
      );
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(promptOverrideDaoProvider);
    await dao.deleteRow(
      PromptOverrideScopes.project, slot, projectId: projectId,
    );
    await dao.deleteRow(PromptOverrideScopes.global, slot);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复内置原文')),
      );
    }
  }
}

class _EditorSheet extends StatefulWidget {
  const _EditorSheet({
    required this.slot,
    required this.initial,
    required this.initialScope,
    required this.onSaved,
    required this.onReset,
  });

  final String slot;
  final String initial;
  final String initialScope;
  final Future<void> Function(String, String) onSaved;
  final Future<void> Function() onReset;

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  late String _scope = widget.initialScope;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSaved(_scope, _controller.text);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onReset();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.slot),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          maxLines: 12,
          minLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '粘贴完整提示词，整段替换内置原文',
          ),
        ),
      ),
      actions: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'project',
              label: Text('项目'),
            ),
            ButtonSegment(value: 'global', label: Text('全局')),
          ],
          selected: {_scope},
          onSelectionChanged: (s) => setState(() => _scope = s.first),
        ),
        TextButton(
          onPressed: _busy ? null : _reset,
          child: const Text('恢复原文'),
        ),
        FilledButton(
          onPressed: _busy || _controller.text.trim().isEmpty ? null : _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
