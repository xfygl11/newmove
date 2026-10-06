import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/active_llm.dart';
import '../../agent/active_video.dart';
import '../../core/gate_issue.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/gate_issue_list.dart';
import '../script/duration_gate.dart';
import '../script/script_providers.dart';
import 'skeleton_models.dart';
import 'skeleton_providers.dart';
import 'skeleton_service.dart';

/// 剧本骨架：节拍/分段/时间轴/出镜状态 + E## 映射校验。
class SkeletonPage extends ConsumerStatefulWidget {
  const SkeletonPage({
    super.key,
    required this.projectId,
    required this.scriptId,
  });

  final int projectId;
  final int scriptId;

  @override
  ConsumerState<SkeletonPage> createState() => _SkeletonPageState();
}

class _SkeletonPageState extends ConsumerState<SkeletonPage> {
  bool _timeline = false;
  bool _busy = false;
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final scriptAsync = ref.watch(scriptProvider(widget.scriptId));
    final scenesAsync = ref.watch(scenesByScriptProvider(widget.scriptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('剧本骨架'),
        actions: [
          IconButton(
            icon: Icon(_timeline ? Icons.list : Icons.timeline),
            tooltip: _timeline ? '列表视图' : '时间轴视图',
            onPressed: () => setState(() => _timeline = !_timeline),
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
          if (script.status != '定稿') {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('剧本尚未定稿。定稿后才能提取骨架。', textAlign: TextAlign.center),
              ),
            );
          }
          return _SkeletonBody(
            projectId: widget.projectId,
            script: script,
            timeline: _timeline,
            expanded: _expanded,
            onToggleExpanded: (id) => setState(() {
              if (!_expanded.add(id)) _expanded.remove(id);
            }),
          );
        },
      ),
      bottomNavigationBar: scriptAsync.value?.status == '定稿'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _reExtract(scenesAsync.value ?? const []),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('重新提取'),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _reExtract(List<Scene> scenes) async {
    final script = ref.read(scriptProvider(widget.scriptId)).value;
    if (script == null) return;
    final shots =
        ref.read(shotsByScriptProvider(widget.scriptId)).value ?? const [];
    final beats =
        ref.read(beatsByScriptProvider(widget.scriptId)).value ?? const [];
    final llm = await ref.read(activeLlmProvider.future);
    // 视频模型能力决定单段时长上限；未配置时按剧本 modelVersion 回落。
    final video = await ref.read(activeVideoProvider.future);
    if (!mounted) return;
    if (llm == null) {
      _toast('请先在「设置」配置可用的 LLM 供应商');
      return;
    }
    final svc = ref.read(skeletonServiceProvider);
    final budget = SkeletonService.budgetFor(script, videoModel: video?.model);
    if (!await ConfirmSheet.confirm(
      context,
      objectName: '骨架提取',
      gate: '骨架重新提取（覆盖场次、节拍与分段结构）',
      quantity: '${scenes.length} 场',
      promptPreview: svc.buildExtractionPrompt(
        script: script,
        scenes: scenes,
        videoModel: video?.model,
      ),
      params: [
        '供应商：${llm.provider.label}',
        '模型：${llm.modelId}',
        '单段上限 ${budget.maxSegmentMs ~/ 1000}s / '
            '合段预算 ${budget.mergeBudgetMs ~/ 1000}s',
      ],
      note:
          '将覆盖现有 ${beats.length} 个节拍与 ${shots.length} 个分段，'
          '已绑定的下游参考关系可能失效。',
      title: '确认重新提取',
      confirmLabel: '重新提取',
    )) {
      return;
    }

    setState(() => _busy = true);
    try {
      final summary = await svc.extract(
        script: script,
        scenes: scenes,
        llm: llm,
        videoModel: video?.model,
      );
      if (mounted) {
        _toast(
          '骨架已更新：${summary.segmentCount} 段 / '
          '${summary.beatCount} 拍 / ${summary.globalDurationMs}ms',
        );
      }
    } catch (e) {
      _toast('提取失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _SkeletonBody extends ConsumerWidget {
  const _SkeletonBody({
    required this.projectId,
    required this.script,
    required this.timeline,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final int projectId;
  final Script script;
  final bool timeline;
  final Set<int> expanded;
  final ValueChanged<int> onToggleExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beatsAsync = ref.watch(beatsByScriptProvider(script.id));
    final shotsAsync = ref.watch(shotsByScriptProvider(script.id));
    final coverageAsync = ref.watch(skeletonCoverageProvider(script.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: coverageAsync.maybeWhen(
            data: (issues) => GateIssueList(
              title: '认领覆盖体检',
              issues: issues,
              onRecord: () => ref.read(gateLogDaoProvider).recordValidation(
                subjectType: GateSubjects.skeleton,
                subjectLabel: '剧本 ${script.title} 认领覆盖体检',
                gates: const ['认领覆盖门'],
                issues: issues,
                projectId: projectId,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: beatsAsync.maybeWhen(
            data: (beats) {
              final issues = DurationGate.validate(
                beats: beats,
                targetDurationMs: script.targetDurationMs,
              );
              return GateIssueList(
                title: '时长体检',
                issues: issues,
                onRecord: () => ref.read(gateLogDaoProvider).recordValidation(
                  subjectType: GateSubjects.shots,
                  subjectLabel: '剧本 ${script.title} 时长体检',
                  gates: const ['时长门'],
                  issues: issues,
                  projectId: projectId,
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: shotsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (shots) {
              final beats = beatsAsync.value ?? const <Beat>[];
              final beatById = <String, Beat>{
                for (final b in beats) b.sourceRef: b,
              };
              if (shots.isEmpty) {
                return const Center(child: Text('还没有骨架，点击下方「重新提取」生成'));
              }

              final batches = <int>{for (final s in shots) s.batch}.toList()
                ..sort();
              return Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        for (final b in batches)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(label: Text('Batch $b')),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: timeline
                        ? _TimelineView(shots: shots)
                        : _ListView(
                            shots: shots,
                            beatById: beatById,
                            expanded: expanded,
                            onToggleExpanded: onToggleExpanded,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({
    required this.shots,
    required this.beatById,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final List<Shot> shots;
  final Map<String, Beat> beatById;
  final Set<int> expanded;
  final ValueChanged<int> onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: shots.length,
      itemBuilder: (context, i) => _SegmentCard(
        shot: shots[i],
        beatById: beatById,
        expanded: expanded.contains(shots[i].id),
        onToggle: () => onToggleExpanded(shots[i].id),
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({required this.shots});

  final List<Shot> shots;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in shots)
          Card(
            margin: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.globalSeq,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(s.globalTimeRange),
                    Text('${s.durationMs ~/ 1000}s · Batch ${s.batch}'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.shot,
    required this.beatById,
    required this.expanded,
    required this.onToggle,
  });

  final Shot shot;
  final Map<String, Beat> beatById;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final beatRefs = _stringList(shot.beatRefs);
    final assets = _parseAssets(shot.assetStates);
    final characters = [
      for (final c in assets.characters)
        '${c.name}(${c.timeline.isEmpty ? '' : c.timeline.first.state})',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: (_) => onToggle(),
        title: Row(
          children: [
            Text(
              shot.globalSeq,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '${shot.durationMs ~/ 1000}s',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shot.globalTimeRange),
            if (characters.isNotEmpty)
              Text(
                '出镜：${characters.join('、')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final ref in beatRefs) _beatChip(context, ref),
                  ],
                ),
                if (beatRefs.isNotEmpty) const SizedBox(height: 8),
                _AssetStates(assets: assets),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _beatChip(BuildContext context, String ref) {
    final beat = beatById[ref];
    final missing = beat == null;
    return Chip(
      label: Text(
        missing ? '$ref（缺失）' : '$ref·${beat.type}',
        style: TextStyle(
          color: missing ? Colors.red.shade200 : null,
          fontSize: 12,
        ),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AssetStates extends StatelessWidget {
  const _AssetStates({required this.assets});

  final SegmentAssets assets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assets.characters.isNotEmpty)
          _section(context, '角色', [
            for (final a in assets.characters)
              '${a.name}：${a.timeline.map((t) => '${t.range} ${t.state}').join('；')}',
          ]),
        if (assets.scenes.isNotEmpty)
          _section(context, '场景', [
            for (final a in assets.scenes)
              '${a.name}：${a.timeline.map((t) => '${t.range} ${t.state}').join('；')}',
          ]),
        if (assets.props.isNotEmpty)
          _section(context, '道具', [
            for (final a in assets.props)
              '${a.name}：${a.timeline.map((t) => '${t.range} ${t.state}').join('；')}',
          ]),
      ],
    );
  }

  Widget _section(BuildContext context, String label, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          for (final line in lines) Text(line),
        ],
      ),
    );
  }
}

List<String> _stringList(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is List) return [for (final v in decoded) v.toString()];
  } on FormatException {
    // 忽略损坏数据。
  }
  return const [];
}

SegmentAssets _parseAssets(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return SegmentAssets.fromJson(decoded);
    }
  } on FormatException {
    // 忽略损坏数据。
  }
  return const SegmentAssets(characters: [], scenes: [], props: []);
}
