import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/active_image.dart';
import '../../data/app_database.dart';
import 'asset_models.dart';
import 'asset_providers.dart';

/// 资产详情：大图预览、外观锚点、变体列表、生成/验收操作。
class AssetDetailPage extends ConsumerStatefulWidget {
  const AssetDetailPage({
    super.key,
    required this.projectId,
    required this.scriptId,
    required this.assetId,
  });

  final int projectId;
  final int scriptId;
  final int assetId;

  @override
  ConsumerState<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends ConsumerState<AssetDetailPage> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final assetAsync = ref.watch(assetProvider(widget.assetId));
    final allAssets = ref.watch(assetsByScriptProvider(widget.scriptId));

    return Scaffold(
      appBar: AppBar(
        title: Text(assetAsync.value?.name ?? '资产详情'),
        actions: [
          IconButton(
            tooltip: '重新生成',
            icon: const Icon(Icons.refresh),
            onPressed: _working ? null : () => _regenerate(),
          ),
          IconButton(
            tooltip: '采用',
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _working ? null : () => _adopt(),
          ),
          IconButton(
            tooltip: '废弃',
            icon: const Icon(Icons.delete_outline),
            onPressed: _working ? null : () => _discard(),
          ),
        ],
      ),
      body: assetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (asset) {
          if (asset == null) return const Center(child: Text('资产不存在'));
          final variants = allAssets.value
                  ?.where((a) => a.variantOf == asset.id)
                  .toList() ??
              const <Asset>[];
          return _DetailBody(
            asset: asset,
            variants: variants,
            working: _working,
            onGenerateVariant: _createVariant,
          );
        },
      ),
    );
  }

  Future<void> _regenerate() async {
    final image = await _resolveImage();
    if (image == null) return;
    setState(() => _working = true);
    try {
      await ref.read(assetServiceProvider).regenerate(
            assetId: widget.assetId,
            image: image,
          );
    } catch (e) {
      _showMessage('重新生成失败：$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _adopt() async {
    await ref.read(assetServiceProvider).adopt(widget.assetId);
  }

  Future<void> _discard() async {
    await ref.read(assetServiceProvider).discard(widget.assetId);
  }

  Future<void> _createVariant() async {
    final image = await _resolveImage();
    if (image == null) return;
    setState(() => _working = true);
    try {
      await ref.read(assetServiceProvider).createVariant(
            assetId: widget.assetId,
            image: image,
          );
      _showMessage('变体已生成，待验收');
    } catch (e) {
      _showMessage('生成变体失败：$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<ActiveImage?> _resolveImage() async {
    final image = await ref.read(activeImageProvider.future);
    if (image == null) {
      _showMessage('请先在设置中配置图片供应商');
      return null;
    }
    return image;
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.asset,
    required this.variants,
    required this.working,
    required this.onGenerateVariant,
  });

  final Asset asset;
  final List<Asset> variants;
  final bool working;
  final VoidCallback onGenerateVariant;

  @override
  Widget build(BuildContext context) {
    final path = asset.imagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 1,
            child: hasImage
                ? InteractiveViewer(
                    child: Image.file(File(path), fit: BoxFit.contain),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.image_outlined, size: 64)),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(asset.name, style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    _StatusBadge(status: asset.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${asset.type} · ${asset.boardLayout} · ${asset.stableId}'),
                if (asset.variantOf != null)
                  Text('变体父资产 #${asset.variantOf}'),
                const Divider(height: 24),
                Text('外观锚点', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(_formatAnchor(asset.appearanceAnchor)),
                const Divider(height: 24),
                Text('生成提示词', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(asset.prompt),
              ],
            ),
          ),
        ),
        if (variants.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('变体', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: variants.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final v = variants[index];
                final vPath = v.imagePath;
                final vHas = vPath != null &&
                    vPath.isNotEmpty &&
                    File(vPath).existsSync();
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: 96,
                    child: vHas
                        ? Image.file(File(vPath), fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.image_outlined)),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: working ? null : onGenerateVariant,
          icon: working
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.content_copy),
          label: const Text('生成变体'),
        ),
      ],
    );
  }

  String _formatAnchor(String? json) {
    if (json == null || json.isEmpty) return '—';
    try {
      final map = jsonDecode(json);
      if (map is Map) {
        return map.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      }
    } on FormatException {
      // 忽略，回退原文。
    }
    return json;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AssetStatuses.pending => Colors.grey,
      AssetStatuses.generating => Colors.blue,
      AssetStatuses.reviewing => Colors.orange,
      AssetStatuses.accepted => Colors.green,
      AssetStatuses.discarded => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: TextStyle(color: color)),
    );
  }
}
