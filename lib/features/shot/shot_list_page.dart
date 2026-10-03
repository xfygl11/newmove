import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/active_image.dart';
import '../../agent/active_llm.dart';
import '../../data/app_database.dart';
import '../asset/asset_providers.dart';
import 'shot_models.dart';
import 'shot_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final shotsAsync = ref.watch(shotListByScriptProvider(widget.scriptId));
    final issuesAsync =
        ref.watch(shotTransitionIssuesProvider(widget.scriptId));

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
          issuesAsync.maybeWhen(
            data: (issues) {
              if (issues.isEmpty) return const SizedBox.shrink();
              return Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                color: Colors.orange.shade900.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '段间衔接提示（A7，${issues.length}）',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      for (final issue in issues)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '⚠ ${issue.message}',
                            style: TextStyle(color: Colors.orange.shade200),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: shotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (shots) {
                if (shots.isEmpty) {
                  return const Center(
                    child: Text('暂无镜头，先在骨架页提取分段'),
                  );
                }
                // 清理已不存在的选中项。
                _selected.retainAll(shots.map((s) => s.id));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shots.length,
                  itemBuilder: (context, index) {
                    final shot = shots[index];
                    return _ShotCard(
                      projectId: widget.projectId,
                      scriptId: widget.scriptId,
                      shot: shot,
                      selected: _selected.contains(shot.id),
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
          final eligible =
              shots.where((s) => s.status == ShotStatuses.awaitingImage).toList();
          if (eligible.isEmpty) return null;
          final allSelected =
              _selected.length == eligible.length && eligible.isNotEmpty;
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
                      label: Text('全选（${_selected.length}/${eligible.length}）'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed:
                          (_generating || _selected.isEmpty) ? null : _generateSelected,
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined),
                      label: Text(_generating && _progress.isNotEmpty
                          ? _progress
                          : '生成选中分镜图'),
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

  /// 批量生成选中的分镜图（含确认 Sheet）。
  Future<void> _generateSelected() async {
    final image = await ref.read(activeImageProvider.future);
    if (!mounted) return;
    if (image == null) {
      _toast('请先在「设置」配置可用的图片供应商');
      return;
    }
    final ids = _selected.toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认生成'),
        content: Text('将为选中的 ${ids.length} 个镜头生成静态分镜图，'
            '供应商 ${image.provider.label} / 模型 ${image.modelId}。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('开始生成'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _generating = true);
    try {
      final result = await ref.read(shotServiceProvider).generateSelected(
            shotIds: ids,
            image: image,
            onProgress: (done, total, _) {
              if (mounted) {
                setState(() => _progress = '生成中 $done/$total');
              }
            },
          );
      _toast('批量完成：成功 ${result.success}，失败 ${result.failed}');
    } catch (e) {
      _toast('批量生成失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
          _progress = '';
        });
      }
    }
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
        onTap: () => context.push(
          '/script/$projectId/script/$scriptId/shot/${shot.id}',
        ),
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
                      if (shot.shotType != null)
                        _Chip(label: shot.shotType!),
                      Text(
                        '$durationSec 秒 · ${shot.globalTimeRange}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      _StatusBadge(status: shot.status),
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
                          _RefAvatar(
                            asset: assetById[ref.assetId],
                          ),
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
          : Icon(
              switch (asset?.type) {
                '角色' => Icons.person_outline,
                '场景' => Icons.landscape_outlined,
                '道具' => Icons.category_outlined,
                _ => Icons.help_outline,
              },
              size: 14,
            ),
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
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ShotStatuses.awaitingPrompt => Colors.grey,
      ShotStatuses.awaitingImage => Colors.blue,
      ShotStatuses.generating => Colors.blue,
      ShotStatuses.reviewing => Colors.amber,
      ShotStatuses.confirmed => Colors.teal,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
