import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/active_llm.dart';
import '../../data/app_database.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/status_badge.dart';
import 'asset_models.dart';
import 'asset_providers.dart';

/// 资产画廊：角色 / 场景 / 道具分类网格，支持从骨架提取资产清单。
class AssetGalleryPage extends ConsumerStatefulWidget {
  const AssetGalleryPage({
    super.key,
    required this.projectId,
    required this.scriptId,
  });

  final int projectId;
  final int scriptId;

  @override
  ConsumerState<AssetGalleryPage> createState() => _AssetGalleryPageState();
}

class _AssetGalleryPageState extends ConsumerState<AssetGalleryPage> {
  String _filter = '全部';
  bool _extracting = false;

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsByScriptProvider(widget.scriptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('资产'),
        actions: [
          IconButton(
            tooltip: '从骨架提取资产清单',
            icon: _extracting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _extracting ? null : _extract,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            filter: _filter,
            onChanged: (v) => setState(() => _filter = v),
          ),
          Expanded(
            child: assetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (assets) {
                final visible = _filter == '全部'
                    ? assets
                    : assets.where((a) => a.type == _filter).toList();
                if (visible.isEmpty) {
                  return const Center(child: Text('暂无资产，点右上角从骨架提取'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final asset = visible[index];
                    return _AssetCard(
                      projectId: widget.projectId,
                      scriptId: widget.scriptId,
                      asset: asset,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _extract() async {
    final llm = await ref.read(activeLlmProvider.future);
    if (llm == null) {
      _showMessage('请先在设置中配置 LLM 供应商');
      return;
    }
    final svc = ref.read(assetServiceProvider);
    final prompt = await svc.buildSkeletonContext(widget.scriptId);
    if (!mounted) return;
    if (!await ConfirmSheet.confirm(
      context,
      objectName: '资产清单提取',
      quantity: '1 次提取',
      promptPreview: prompt,
      params: ['供应商：${llm.provider.label}', '模型：${llm.modelId}'],
      note: '同 stableId 的资产会复用已有条目，不重复创建。',
      title: '确认提取资产',
    )) {
      return;
    }

    setState(() => _extracting = true);
    try {
      final summary = await svc.extractAndSave(
        scriptId: widget.scriptId,
        llm: llm,
      );
      _showMessage(
        '提取完成：新建 ${summary.created}，复用 ${summary.reused}，变体 ${summary.variants}',
      );
    } catch (e) {
      _showMessage('提取失败：$e');
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final String filter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = ['全部', ...AssetTypes.all];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return ChoiceChip(
            label: Text(option),
            selected: filter == option,
            onSelected: (_) => onChanged(option),
          );
        },
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.projectId,
    required this.scriptId,
    required this.asset,
  });

  final int projectId;
  final int scriptId;
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final path = asset.imagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/script/$projectId/script/$scriptId/asset/${asset.id}',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: hasImage
                  ? Image.file(File(path), fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        asset.type,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      StatusBadge(status: asset.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
