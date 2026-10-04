import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_database.dart';
import '../novel/novel_providers.dart';
import '../shot/shot_providers.dart';
import 'script_adapt_sheet.dart';
import 'script_models.dart';
import 'script_providers.dart';

/// 剧本详情：场次列表 + 改编提案确认 + 定稿/重改编。
class ScriptDetailPage extends ConsumerWidget {
  const ScriptDetailPage({
    super.key,
    required this.projectId,
    required this.scriptId,
  });

  final int projectId;
  final int scriptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scriptAsync = ref.watch(scriptProvider(scriptId));
    final scenesAsync = ref.watch(scenesByScriptProvider(scriptId));

    return Scaffold(
      appBar: AppBar(
        title: Text(scriptAsync.value?.title ?? '剧本详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: '剧本骨架',
            onPressed: () => context.push(
              '/script/$projectId/script/$scriptId/skeleton',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: '资产',
            onPressed: () => context.push(
              '/script/$projectId/script/$scriptId/assets',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.movie_filter_outlined),
            tooltip: '镜头',
            onPressed: () => context.push(
              '/script/$projectId/script/$scriptId/shots',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '版本历史',
            onPressed: () => context.push(
              '/script/$projectId/script/$scriptId/versions',
            ),
          ),
        ],
      ),
      body: scriptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (script) {
          if (script == null) {
            return const Center(child: Text('剧本不存在'));
          }
          final proposals = ref
              .read(scriptServiceProvider)
              .listProposals(script);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(projectId: projectId, script: script),
              const SizedBox(height: 16),
              if (proposals.isNotEmpty) ...[
                Text('改编提案（需确认）', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final p in proposals)
                  _ProposalCard(
                    projectId: projectId,
                    script: script,
                    proposal: p,
                  ),
                const SizedBox(height: 16),
              ],
              Text(
                '分场（${scenesAsync.value?.length ?? 0}）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              scenesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('加载失败：$e'),
                data: (scenes) {
                  if (scenes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('还没有场次'),
                    );
                  }
                  return Column(
                    children: [
                      for (final s in scenes)
                        _SceneTile(
                          projectId: projectId,
                          scriptId: script.id,
                          scene: s,
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({required this.projectId, required this.script});

  final int projectId;
  final Script script;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFinal = script.status == '定稿';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    script.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  label: Text(
                    script.status,
                    style: TextStyle(
                      color: isFinal ? Colors.green : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('版本 v${script.version} · ${script.fidelityMode}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新改编'),
                    onPressed: () async {
                      final book = await ref
                          .read(novelBookByProjectProvider(projectId).future);
                      if (book == null) return;
                      if (!context.mounted) return;
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => AdaptSheet(
                          book: book,
                          existing: script,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('定稿'),
                    onPressed: isFinal
                        ? null
                        : () => _finalize(context, ref),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _ComposeRow(projectId: projectId, scriptId: script.id),
          ],
        ),
      ),
    );
  }

  Future<void> _finalize(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认定稿'),
        content: const Text('定稿后将进入骨架提取阶段，仍可重新改编。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('定稿'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(scriptServiceProvider).finalizeScript(script.id);
  }
}

class _ComposeRow extends ConsumerWidget {
  const _ComposeRow({required this.projectId, required this.scriptId});

  final int projectId;
  final int scriptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.call_split),
            label: const Text('合成成片'),
            onPressed: () => _compose(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final script = ref.watch(scriptProvider(scriptId)).value;
    final outName =
        'compose_${script?.title ?? 'script'}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Expanded(child: Text('正在合成…（FFmpeg 本地拼接）')),
          ],
        ),
      ),
    );
    try {
      final path = await ref
          .read(shotComposeServiceProvider)
          .composeScript(scriptId: scriptId, outputName: outName);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('已合成：$path')));
      final file = XFile(path);
      await SharePlus.instance.share(
        ShareParams(files: [file]),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('合成失败：$e')));
    }
  }
}

class _SceneTile extends StatelessWidget {
  const _SceneTile({
    required this.projectId,
    required this.scriptId,
    required this.scene,
  });

  final int projectId;
  final int scriptId;
  final Scene scene;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          '${scene.seq}. ${scene.location.isEmpty ? '未设定地点' : scene.location}',
        ),
        subtitle: Text(
          [scene.time, scene.summary].whereType<String>().join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          '/script/$projectId/script/$scriptId/scene/${scene.id}',
        ),
      ),
    );
  }
}

class _ProposalCard extends ConsumerWidget {
  const _ProposalCard({
    required this.projectId,
    required this.script,
    required this.proposal,
  });

  final int projectId;
  final Script script;
  final AdaptationProposal proposal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accepted = proposal.accepted;
    final Color accent = accepted ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(accepted ? Icons.check_circle : Icons.error_outline,
                    color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '提案 #${proposal.id} · ${proposal.type}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(proposal.text),
            if (proposal.source.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '原文依据：${proposal.source}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _setAccepted(ref, false),
                  child: const Text('拒绝'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _setAccepted(ref, true),
                  child: const Text('采纳'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setAccepted(WidgetRef ref, bool value) async {
    await ref.read(scriptServiceProvider).setProposalAccepted(
          script,
          proposalId: proposal.id,
          accepted: value,
        );
  }
}
