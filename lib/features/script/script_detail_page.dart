import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../core/gate_issue.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../../data/daos/script_dao.dart';
import '../../widgets/gate_issue_list.dart';
import '../novel/novel_providers.dart';
import '../shot/shot_compose_service.dart';
import '../shot/shot_providers.dart';
import 'art_styles.dart';
import 'duration_gate.dart';
import 'script_adapt_sheet.dart';
import 'script_gate.dart';
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
            onPressed: () =>
                context.push('/script/$projectId/script/$scriptId/skeleton'),
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: '资产',
            onPressed: () =>
                context.push('/script/$projectId/script/$scriptId/assets'),
          ),
          IconButton(
            icon: const Icon(Icons.movie_filter_outlined),
            tooltip: '镜头',
            onPressed: () =>
                context.push('/script/$projectId/script/$scriptId/shots'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '版本历史',
            onPressed: () =>
                context.push('/script/$projectId/script/$scriptId/versions'),
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
              const SizedBox(height: 12),
              scenesAsync.maybeWhen(
                data: (scenes) {
                  final issues = DurationGate.longLinesOfScenes(scenes);
                  return GateIssueList(
                    title: '台词体检',
                    issues: issues,
                    onRecord: () => ref.read(gateLogDaoProvider).recordValidation(
                      subjectType: GateSubjects.script,
                      subjectLabel: '剧本 ${script.title} 台词体检',
                      gates: const ['台词门'],
                      issues: issues,
                      projectId: projectId,
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              // 场次侧体检（M22 T23.2）：画面动作缺失、动作夹对话、说话人越界。
              scenesAsync.maybeWhen(
                data: (scenes) {
                  final issues = ScriptGate.validate(scenes: scenes);
                  if (issues.isEmpty) return const SizedBox.shrink();
                  return GateIssueList(
                    title: '剧本体检',
                    issues: issues,
                    onRecord: () => ref.read(gateLogDaoProvider).recordValidation(
                      subjectType: GateSubjects.script,
                      subjectLabel: '剧本 ${script.title} 剧本体检',
                      gates: const ['剧本门'],
                      issues: issues,
                      projectId: projectId,
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              if (proposals.isNotEmpty) ...[
                Text(
                  '改编提案（需确认）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
            _ArtStyleEditor(
              script: script,
              scriptDao: ref.read(scriptDaoProvider),
            ),
            const Divider(height: 16),
            _EpisodeParamEditor(
              script: script,
              scriptDao: ref.read(scriptDaoProvider),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新改编'),
                    onPressed: () async {
                      final book = await ref.read(
                        novelBookByProjectProvider(projectId).future,
                      );
                      if (book == null) return;
                      if (!context.mounted) return;
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) =>
                            AdaptSheet(book: book, existing: script),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('定稿'),
                    onPressed: isFinal ? null : () => _finalize(context, ref),
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

class _ArtStyleEditor extends StatefulWidget {
  const _ArtStyleEditor({required this.script, required this.scriptDao});

  final Script script;
  final ScriptDao scriptDao;

  @override
  State<_ArtStyleEditor> createState() => _ArtStyleEditorState();
}

class _ArtStyleEditorState extends State<_ArtStyleEditor> {
  /// 已入库的画风短名；未设置或历史自由文本都落到默认名。
  late String _currentName = effectiveArtStyleName(widget.script.artStyle);

  late String _selectedName = _currentName;

  /// 库里存的是未登记的历史自由文本，选中画风会覆盖它。
  bool get _hasCustomText {
    final raw = widget.script.artStyle;
    return !ArtStyleCatalog.isDefaultOrEmpty(raw) &&
        ArtStyleCatalog.promptOf(raw) == null;
  }

  bool get _dirty => _selectedName != _currentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ArtStyleCatalog.byName(_selectedName);
    final prompt = selected?.prompt ?? defaultArtStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.palette_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text('画面风格', style: theme.textTheme.labelMedium),
            const Spacer(),
            TextButton(
              onPressed: _selectedName == ArtStyleCatalog.defaultName
                  ? null
                  : () => setState(() {
                        _selectedName = ArtStyleCatalog.defaultName;
                      }),
              child: const Text('恢复默认'),
            ),
          ],
        ),
        if (_hasCustomText)
          Text(
            '当前风格是自定义文案，选择下面的画风会覆盖它。',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        const SizedBox(height: 8),
        ...ArtStyleCatalog.grouped.entries.expand(
          (entry) => [
            Text(
              '${entry.key}族',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final style in entry.value)
                  ChoiceChip(
                    label: Text(style.name),
                    selected: _selectedName == style.name,
                    onSelected: (_) =>
                        setState(() => _selectedName = style.name),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        SelectableText(prompt, style: theme.textTheme.bodySmall),
        if (_dirty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '保存后按新风格执行资产图与视频',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              FilledButton(
                onPressed: _save,
                child: const Text('保存风格'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    final name = _selectedName;
    await widget.scriptDao.updateRow(
      widget.script.copyWith(
        artStyle: Value(name == ArtStyleCatalog.defaultName ? null : name),
      ),
    );
    if (!mounted) return;
    setState(() => _currentName = name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          name == ArtStyleCatalog.defaultName
              ? '已恢复默认画风'
              : '已保存画风：$name',
        ),
      ),
    );
  }
}

/// 分集参数（M16）：集序号、目标总时长与目标模型版本。
///
/// 一集 = 剧本一行，不新增集表。保存后影响骨架提取的时长预算与
/// 视频提交前的校验，不参与算力授权。
class _EpisodeParamEditor extends StatefulWidget {
  const _EpisodeParamEditor({required this.script, required this.scriptDao});

  final Script script;
  final ScriptDao scriptDao;

  @override
  State<_EpisodeParamEditor> createState() => _EpisodeParamEditorState();
}

class _EpisodeParamEditorState extends State<_EpisodeParamEditor> {
  late final TextEditingController _episodeNo;
  late final TextEditingController _targetDuration;

  /// '' 表示未指定，单段上限与批次容量由选中的视频模型能力推导。
  late String _modelVersion;

  @override
  void initState() {
    super.initState();
    final script = widget.script;
    _episodeNo = TextEditingController(
      text: script.episodeNo?.toString() ?? '',
    );
    _targetDuration = TextEditingController(
      text: script.targetDurationMs > 0
          ? '${script.targetDurationMs ~/ 1000}'
          : '',
    );
    _modelVersion = script.modelVersion ?? '';
  }

  bool get _dirty {
    final episodeText = _episodeNo.text.trim();
    final episode = episodeText.isEmpty ? null : int.tryParse(episodeText);
    if (episode != widget.script.episodeNo) return true;

    final seconds = int.tryParse(_targetDuration.text.trim()) ?? 0;
    if (seconds * 1000 != widget.script.targetDurationMs) return true;

    final version = _modelVersion.isEmpty ? null : _modelVersion;
    return version != widget.script.modelVersion;
  }

  @override
  void dispose() {
    _episodeNo.dispose();
    _targetDuration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberInput = const InputDecoration(border: OutlineInputBorder());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.live_tv_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text('分集参数', style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _episodeNo,
                keyboardType: TextInputType.number,
                decoration: numberInput.copyWith(labelText: '集序号（可空）'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _targetDuration,
                keyboardType: TextInputType.number,
                decoration: numberInput.copyWith(labelText: '目标总时长（秒）'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _modelVersion,
          decoration: numberInput.copyWith(
            labelText: '目标模型版本',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          items: const [
            DropdownMenuItem(value: '', child: Text('按视频模型能力')),
            DropdownMenuItem(
              value: '2.0',
              child: Text('Seedance 2.0（单段 15s · 单批 6 段）'),
            ),
            DropdownMenuItem(
              value: '2.5',
              child: Text('Seedance 2.5（单段 30s · 单批 3 段）'),
            ),
          ],
          onChanged: (v) => setState(() => _modelVersion = v ?? ''),
        ),
        if (_dirty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '目标总时长影响时长预算校验；0 表示由内容自然节奏决定',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              FilledButton(onPressed: _save, child: const Text('保存参数')),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    final episodeText = _episodeNo.text.trim();
    final seconds = int.tryParse(_targetDuration.text.trim()) ?? 0;
    await widget.scriptDao.updateRow(
      widget.script.copyWith(
        episodeNo: Value(
          episodeText.isEmpty ? null : int.tryParse(episodeText),
        ),
        targetDurationMs: seconds > 0 ? seconds * 1000 : 0,
        modelVersion: Value(_modelVersion.isEmpty ? null : _modelVersion),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已保存分集参数')));
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

    // 合成耗时可达数分钟：用可取消的 SnackBar 逐阶段刷新，
    // 且服务侧带超时兜底，不会再出现永久进度条挡住操作。
    final token = ComposeCancelToken();
    final messenger = rootMessenger;
    void showPhase(String phase) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('正在合成：$phase')),
            ],
          ),
          action: SnackBarAction(
            label: '取消',
            onPressed: () {
              token.cancel();
            },
          ),
        ),
      );
    }

    try {
      final path = await ref
          .read(shotComposeServiceProvider)
          .composeScript(
            scriptId: scriptId,
            outputName: outName,
            cancelToken: token,
            onProgress: showPhase,
          );
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('已合成：$path')));
      final file = XFile(path);
      await SharePlus.instance.share(ShareParams(files: [file]));
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
                Icon(
                  accepted ? Icons.check_circle : Icons.error_outline,
                  color: accent,
                ),
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
    await ref
        .read(scriptServiceProvider)
        .setProposalAccepted(script, proposalId: proposal.id, accepted: value);
  }
}
