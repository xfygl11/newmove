import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/prompt_resolver.dart';
import '../../core/storage/providers.dart';
import '../../data/daos/prompt_override_dao.dart';
import '../../data/app_database.dart';

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
      body: Column(
        children: [
          _ProjectPromptsSwitch(projectId: projectId),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: PromptResolver.allSlots.length,
              itemBuilder: (context, index) => _SlotTile(
                slot: PromptResolver.allSlots[index],
                projectId: projectId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 项目级提示词开关：关闭后本项目只用全局级覆盖与内置 skill 原文。
///
/// 存量项目该列值为 null，按「已开启」显示，与升级前的行为一致。
class _ProjectPromptsSwitch extends ConsumerWidget {
  const _ProjectPromptsSwitch({required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(promptOverrideDaoProvider);
    var enabled = true;
    bool settled = false;

    return StatefulBuilder(
      builder: (context, setState) {
        if (!settled) {
          settled = true;
          // ignore: unawaited_futures
          dao.projectPromptsEnabled(projectId).then(
            (value) {
              if (value != enabled) {
                setState(() => enabled = value);
              }
            },
          );
        }
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('使用项目级提示词'),
          subtitle: Text(
            enabled
                ? '本项目自定义的提示词优先生效'
                : '本项目跳过项目级，只用全局与内置',
          ),
          value: enabled,
          onChanged: (value) async {
            setState(() => enabled = value);
            await dao.setProjectPromptsEnabled(projectId, value);
          },
        );
      },
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
          switch (action) {
            case 'reset':
              await _reset(context, ref);
            case 'history':
              await _showHistory(context, ref);
            default:
              await _edit(context, ref, action);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'project', child: Text('编辑（项目级）')),
          PopupMenuItem(value: 'global', child: Text('编辑（全局级）')),
          PopupMenuItem(value: 'history', child: Text('版本历史')),
          PopupMenuItem(value: 'reset', child: Text('恢复内置原文')),
        ],
      ),
      onTap: () => _edit(context, ref, 'project'),
    );
  }

  /// 列出该插槽两个作用域下的历史版本，点选回退。
  ///
  /// 回退 = 用该历史版本的正文再走一次 upsert，因此回退本身又会产生一条
  /// 新版本；当前正文先被存档，历史链不回溯删除。
  Future<void> _showHistory(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(promptOverrideDaoProvider);
    final projectScope = PromptOverrideScopes.project;
    final rows = await dao.listVersions(projectScope, slot, projectId: projectId);
    if (!context.mounted) return;

    if (rows.isEmpty) {
      final globalRows = await dao.listVersions(PromptOverrideScopes.global, slot);
      if (!context.mounted) return;
      if (globalRows.isEmpty) {
        _toast(context, '还没有历史版本');
        return;
      }
      _showVersionDialog(context, ref, '全局级历史', globalRows);
      return;
    }
    _showVersionDialog(context, ref, '项目级历史', rows);
  }

  Future<void> _showVersionDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<PromptOverrideVersion> rows,
  ) async {
    final dao = ref.read(promptOverrideDaoProvider);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$slot · $title'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '按时间倒序。点选任一条会把它作为新版本写回当前正文。',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final row in rows)
                        ListTile(
                          dense: true,
                          title: Text(
                            row.body.trim().isEmpty
                                ? '（空）'
                                : row.body.trim().split('\n').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_formatTime(row.createdAt)} · '
                            '${row.body.length} 字',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await dao.restoreVersion(row.id);
                            if (context.mounted) {
                              _toast(context, '已回退到 ${_formatTime(row.createdAt)} 的版本');
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
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

  String _formatTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  void _toast(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      // Dialog 会把键盘 inset 加到外边距上，8 行 minLines 的高度可能超出可用高度。
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
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
