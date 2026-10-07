import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/active_image.dart';
import '../../agent/active_llm.dart';
import '../../core/gate_issue.dart';
import '../../data/app_database.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/status_badge.dart';
import '../asset/asset_providers.dart';
import 'segment_budget.dart';
import 'shot_models.dart';
import 'shot_providers.dart';
import 'shot_service.dart' show GenerationCancelToken;

/// 镜头列表：按 G 序号分段展示，支持批量提取提示词与批量生成分镜图。
class ShotListPage extends ConsumerStatefulWidget {
  const ShotListPage({
    super.key,
    required this.projectId,
    required this.scriptId,
  });

  final int projectId;
  final int scriptId;

  @override
  ConsumerState<ShotListPage> createState() => _ShotListPageState();
}

class _ShotListPageState extends ConsumerState<ShotListPage> {
  bool _directing = false;
  bool _generating = false;
  String _progress = '';
  final Set<int> _selected = {};
  GenerationCancelToken? _cancelToken;

  @override
  Widget build(BuildContext context) {
    final shotsAsync = ref.watch(shotListByScriptProvider(widget.scriptId));
    final transitionIssues =
        ref.watch(shotTransitionIssuesProvider(widget.scriptId)).value ??
        const <ShotTransitionIssue>[];
    final budgetIssues =
        ref.watch(shotBudgetIssuesProvider(widget.scriptId)).value ??
        const <SegmentBudgetIssue>[];
    final costumeIssues =
        ref.watch(shotCostumeIssuesProvider(widget.scriptId)).value ??
        const <GateIssue>[];
    final shotGateIssues =
        ref.watch(shotGateIssuesProvider(widget.scriptId)).value ??
        const <GateIssue>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('镜头'),
        actions: [
          IconButton(
            tooltip: '从骨架生成分镜提示词',
            icon: _directing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _directing ? null : _directAll,
          ),
        ],
      ),
      body: Column(
        children: [
          _GatePanel(
            transitionIssues: transitionIssues,
            budgetIssues: budgetIssues,
            costumeIssues: costumeIssues,
            shotGateIssues: shotGateIssues,
          ),

          Expanded(
            child: shotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (shots) {
                if (shots.isEmpty) {
                  return const Center(child: Text('暂无镜头，先在骨架页提取分段'));
                }
                final selected = _prune(_selected, shots.map((s) => s.id));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shots.length,
                  itemBuilder: (context, index) {
                    final shot = shots[index];
                    return _ShotCard(
                      projectId: widget.projectId,
                      scriptId: widget.scriptId,
                      shot: shot,
                      selected: selected.contains(shot.id),
                      selectable: ShotStatuses.awaitingImage == shot.status,
                      onToggle: () => setState(() {
                        if (!_selected.add(shot.id)) _selected.remove(shot.id);
                      }),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: shotsAsync.maybeWhen(
        data: (shots) {
          final eligible = shots
              .where((s) => s.status == ShotStatuses.awaitingImage)
              .toList();
          if (eligible.isEmpty) return null;
          final selected = _prune(_selected, shots.map((s) => s.id));
          final allSelected = selected.length == eligible.length;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        if (allSelected) {
                          _selected.clear();
                        } else {
                          _selected
                            ..clear()
                            ..addAll(eligible.map((s) => s.id));
                        }
                      }),
                      icon: Icon(
                        allSelected
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank,
                      ),
                      label: Text('全选（${selected.length}/${eligible.length}）'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_generating)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: _cancelGeneration,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('取消'),
                      ),
                    )
                  else
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: (_generating || selected.isEmpty)
                            ? null
                            : _generateSelected,
                        icon: _generating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.image_outlined),
                        label: Text(
                          _generating && _progress.isNotEmpty
                              ? _progress
                              : '生成选中分镜图',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  /// 批量导演：生成全部镜头的分镜提示词。
  Future<void> _directAll() async {
    final llm = await ref.read(activeLlmProvider.future);
    if (llm == null) {
      _toast('请先在「设置」配置可用的 LLM 供应商');
      return;
    }
    final shots = await ref.read(
      shotListByScriptProvider(widget.scriptId).future,
    );
    final prompt = await ref
        .read(shotServiceProvider)
        .buildDirectionContext(widget.scriptId);
    if (!mounted) return;
    if (!await ConfirmSheet.confirm(
      context,
      objectName: '分镜提示词',
      gate: '重新导演（覆盖全部镜头的分镜提示词与帧）',
      quantity: '${shots.length} 个镜头',
      promptPreview: prompt,
      params: ['供应商：${llm.provider.label}', '模型：${llm.modelId}'],
      note: '将覆盖已有的提示词、分镜帧与参考绑定。',
      title: '确认重新导演',
    )) {
      return;
    }
    setState(() => _directing = true);
    try {
      final summary = await ref
          .read(shotServiceProvider)
          .directAndSave(scriptId: widget.scriptId, llm: llm);
      _toast(
        '分镜提示词完成：${summary.shotCount} 镜 / '
        '${summary.frameCount} 帧 / ${summary.refCount} 绑定',
      );
    } catch (e) {
      _toast('分镜提示词失败：$e');
    } finally {
      if (mounted) setState(() => _directing = false);
    }
  }

  /// 只保留仍存在的镜头 id，不改动 [_selected]，避免在 build 内产生副作用。
  static Set<int> _prune(Set<int> selected, Iterable<int> existing) =>
      selected.where(existing.contains).toSet();

  /// 批量生成选中的分镜图（含确认 Sheet）。
  Future<void> _generateSelected() async {
    final image = await ref.read(activeImageProvider.future);
    if (!mounted) return;
    if (image == null) {
      _toast('请先在「设置」配置可用的图片供应商');
      return;
    }
    final ids = _selected.toList();
    final shots = (await ref.read(
      shotListByScriptProvider(widget.scriptId).future,
    )).where((s) => ids.contains(s.id)).toList();
    if (!mounted) return;
    if (!await ConfirmSheet.confirm(
      context,
      objectName: '批量分镜图',
      gate: '批量分镜图生成（小样不代表批量，验收需单独进行）',
      quantity: '${ids.length} 次生成',
      promptPreview: shots
          .map((s) => '${s.globalSeq}：${s.prompt}')
          .join('\n---\n'),
      params: ['供应商：${image.provider.label}', '模型：${image.modelId}'],
    )) {
      return;
    }

    _cancelToken = GenerationCancelToken();
    setState(() => _generating = true);
    try {
      final result = await ref
          .read(shotServiceProvider)
          .generateSelected(
            shotIds: ids,
            image: image,
            cancelToken: _cancelToken,
            onProgress: (done, total, _) {
              if (mounted) {
                setState(() => _progress = '生成中 $done/$total');
              }
            },
          );
      if (result.cancelled) {
        _toast('已取消：成功 ${result.success}，剩余 ${result.pending} 未生成');
      } else {
        _toast('批量完成：成功 ${result.success}，失败 ${result.failed}');
      }
    } catch (e) {
      _toast('批量生成失败：$e');
    } finally {
      _cancelToken = null;
      if (mounted) {
        setState(() {
          _generating = false;
          _progress = '';
        });
      }
    }
  }

  void _cancelGeneration() {
    _cancelToken?.cancelled = true;
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// 单张镜头卡。
class _ShotCard extends ConsumerWidget {
  const _ShotCard({
    required this.projectId,
    required this.scriptId,
    required this.shot,
    required this.selected,
    required this.selectable,
    required this.onToggle,
  });

  final int projectId;
  final int scriptId;
  final Shot shot;
  final bool selected;
  final bool selectable;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refsAsync = ref.watch(shotRefsProvider(shot.id));
    final assetsAsync = ref.watch(assetsByScriptProvider(scriptId));
    final refs = refsAsync.value ?? const <AssetRef>[];
    final assets = assetsAsync.value ?? const <Asset>[];
    final assetById = {for (final a in assets) a.id: a};

    final path = shot.outputPath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
    final durationSec = (shot.durationMs / 1000).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push('/script/$projectId/script/$scriptId/shot/${shot.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(File(path), fit: BoxFit.cover),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Text(
                    shot.status == ShotStatuses.awaitingPrompt
                        ? '待生成分镜提示词'
                        : '待生成分镜图',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        shot.globalSeq,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      if (shot.shotType != null) _Chip(label: shot.shotType!),
                      Text(
                        '$durationSec 秒 · ${shot.globalTimeRange}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      StatusBadge(status: shot.status),
                      if (shot.isStale != 0) ...[
                        const SizedBox(width: 6),
                        StaleBadge(isStale: shot.isStale),
                      ],
                      if (selectable) ...[
                        const SizedBox(width: 4),
                        Checkbox(value: selected, onChanged: (_) => onToggle()),
                      ],
                    ],
                  ),
                  if (refs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final ref in refs)
                          _RefAvatar(asset: assetById[ref.assetId]),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 参考资产头像（列表卡上替代连线）。
class _RefAvatar extends StatelessWidget {
  const _RefAvatar({required this.asset});

  final Asset? asset;

  @override
  Widget build(BuildContext context) {
    final path = asset?.imagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return CircleAvatar(
      radius: 14,
      backgroundImage: hasImage ? FileImage(File(path)) : null,
      child: hasImage
          ? null
          : Icon(switch (asset?.type) {
              '角色' => Icons.person_outline,
              '场景' => Icons.landscape_outlined,
              '道具' => Icons.category_outlined,
              _ => Icons.help_outline,
            }, size: 14),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

/// 镜头页统一体检入口：四类校验结果合并成一行折叠面板，默认收起。
///
/// 无问题时整体不占位；有问题时只占一行（标题 + 数量徽章），点开才展开各
/// 分类详情。门只提示不改数据，常驻铺开会把镜头列表挤到只剩一点。
class _GatePanel extends StatelessWidget {
  const _GatePanel({
    required this.transitionIssues,
    required this.budgetIssues,
    required this.costumeIssues,
    required this.shotGateIssues,
  });

  final List<ShotTransitionIssue> transitionIssues;
  final List<SegmentBudgetIssue> budgetIssues;
  final List<GateIssue> costumeIssues;
  final List<GateIssue> shotGateIssues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetErrors = budgetIssues.where((i) => i.isError).toList();
    final budgetWarns = budgetIssues.where((i) => !i.isError).toList();
    final errorCount =
        budgetErrors.length +
        costumeIssues.where((i) => i.isError).length +
        shotGateIssues.where((i) => i.isError).length;
    final totalCount =
        transitionIssues.length +
        budgetIssues.length +
        costumeIssues.length +
        shotGateIssues.length;

    if (totalCount == 0) return const SizedBox.shrink();

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          Expanded(child: Text('镜头体检', style: theme.textTheme.titleSmall)),
          _GateCountBadge(count: totalCount, errorCount: errorCount),
          const SizedBox(width: 8),
        ],
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '以下问题需手动调整，门只提示、不自动修改。',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
        if (transitionIssues.isNotEmpty)
          _gateGroup(
            context,
            title: '段间衔接（${transitionIssues.length}）',
            message: '画面区分度不足，建议调整景别/角度',
            entries: [for (final i in transitionIssues) i.message],
            isError: false,
          ),
        if (budgetErrors.isNotEmpty)
          _gateGroup(
            context,
            title: '时长约束冲突（${budgetErrors.length}）',
            message: '错误级：提交视频生成前需逐条确认',
            entries: [for (final i in budgetErrors) _budgetLine(i)],
            isError: true,
          ),
        if (budgetWarns.isNotEmpty)
          _gateGroup(
            context,
            title: '时长预算提示（${budgetWarns.length}）',
            message: '提示级：不阻塞生成，建议调整分段',
            entries: [for (final i in budgetWarns) _budgetLine(i)],
            isError: false,
          ),
        if (costumeIssues.isNotEmpty)
          _gateGroup(
            context,
            title: '服装覆盖（${costumeIssues.length}）',
            message: '分镜图与视频会按覆盖渲染，建议先修正',
            entries: [for (final i in costumeIssues) i.noteLine],
            isError: costumeIssues.any((i) => i.isError),
          ),
        if (shotGateIssues.isNotEmpty)
          _gateGroup(
            context,
            title: '镜头体检（${shotGateIssues.length}）',
            message: '出图与视频前建议先修正',
            entries: [for (final i in shotGateIssues) i.noteLine],
            isError: shotGateIssues.any((i) => i.isError),
          ),
      ],
    );
  }

  Widget _gateGroup(
    BuildContext context, {
    required String title,
    required String message,
    required List<String> entries,
    required bool isError,
  }) {
    final theme = Theme.of(context);
    final color = isError
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(message, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                e,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _budgetLine(SegmentBudgetIssue issue) =>
      '[${issue.isError ? 'error' : 'warn'}] ${issue.seq}：'
      '${_budgetLabelOf(issue.code)}';

  String _budgetLabelOf(String code) => switch (code) {
    'over_limit' => '超出单段上限',
    'dialogue_overflow' => '台词装不下',
    'total_mismatch' => '与目标总时长偏差大',
    'too_few_segments' => '段数偏少',
    'batch_too_large' => '单批段数过多',
    _ => code,
  };
}

/// 数量徽章：有错误时红色强调，否则中性色。
class _GateCountBadge extends StatelessWidget {
  const _GateCountBadge({required this.count, required this.errorCount});

  final int count;
  final int errorCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorCount > 0;
    final color = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.outline;
    final text = hasError ? '$count 条 · $errorCount 错误' : '$count 条';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
