import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/active_image.dart';
import '../../data/app_database.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/image_version_panel.dart';
import '../../widgets/status_badge.dart';
import 'asset_models.dart';
import 'asset_providers.dart';
import 'asset_service.dart';

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
          final variants =
              allAssets.value?.where((a) => a.variantOf == asset.id).toList() ??
              const <Asset>[];
          return _DetailBody(
            asset: asset,
            variants: variants,
            working: _working,
            onGenerateVariant: _createVariant,
            onReplaceImage: _replaceImage,
            onSelectVersion: _selectVersion,
          );
        },
      ),
    );
  }

  Future<void> _regenerate() async {
    final asset = ref.read(assetProvider(widget.assetId)).value;
    final image = await _resolveImage();
    if (image == null || !mounted) return;
    // 消耗算力前必须过确认框：展示即将执行的提示词、模型与尺寸。
    final ok = await ConfirmSheet.confirm(
      context,
      objectName: '资产图 · ${asset?.name ?? ''}',
      quantity: '1 张',
      promptPreview: asset?.prompt ?? '',
      params: ['模型：${image.modelId}', '尺寸：${image.imageSize}'],
      gate: '资产图阶段门：确认提示词后重新生成一张图',
      title: '重新生成资产图',
    );
    if (!ok || !mounted) return;
    setState(() => _working = true);
    try {
      await ref
          .read(assetServiceProvider)
          .regenerate(assetId: widget.assetId, image: image);
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
    final asset = ref.read(assetProvider(widget.assetId)).value;
    final image = await _resolveImage();
    if (image == null || !mounted) return;
    // 变体走图生图：把基础图作为参考上传，提示词在服务端追加固定后缀。
    final ok = await ConfirmSheet.confirm(
      context,
      objectName: '资产变体 · ${asset?.name ?? ''}',
      quantity: '1 张',
      promptPreview: asset == null
          ? ''
          : '${asset.prompt}\n${AssetService.variantPromptSuffix}',
      params: ['模型：${image.modelId}', '尺寸：${image.imageSize}'],
      refs: ['参考图 1：基础资产图'],
      gate: '资产图阶段门：确认提示词后基于基础图生成一张变体',
      title: '生成资产变体',
    );
    if (!ok || !mounted) return;
    setState(() => _working = true);
    try {
      await ref
          .read(assetServiceProvider)
          .createVariant(assetId: widget.assetId, image: image);
      _showMessage('变体已生成，待验收');
    } catch (e) {
      _showMessage('生成变体失败：$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// 切换到资产图历史版本（M17 T19.2）。
  Future<void> _selectVersion(String imagePath) async {
    setState(() => _working = true);
    try {
      await ref
          .read(assetServiceProvider)
          .selectImageVersion(assetId: widget.assetId, imagePath: imagePath);
      _showMessage('已切换版本，待重新验收');
    } catch (e) {
      _showMessage('切换失败：$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// 用本地图片替换资产图（≤100MB）；旧图已存为历史版本，可切回。
  Future<void> _replaceImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;
    final path = result.single.path;
    if (path == null || !mounted) return;
    setState(() => _working = true);
    try {
      await ref
          .read(assetServiceProvider)
          .replaceImage(assetId: widget.assetId, sourcePath: path);
      _showMessage('已替换图片，待重新验收');
    } catch (e) {
      _showMessage('替换失败：$e');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.asset,
    required this.variants,
    required this.working,
    required this.onGenerateVariant,
    required this.onReplaceImage,
    required this.onSelectVersion,
  });

  final Asset asset;
  final List<Asset> variants;
  final bool working;
  final VoidCallback onGenerateVariant;
  final VoidCallback onReplaceImage;
  final ValueChanged<String> onSelectVersion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 64),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        _ImageHistoryPanel(
          assetId: asset.id,
          currentPath: path,
          working: working,
          onReplace: onReplaceImage,
          onSelect: onSelectVersion,
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
                    Text(
                      asset.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    StatusBadge(status: asset.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${asset.type} · ${asset.boardLayout} · ${asset.stableId}',
                ),
                if (asset.variantOf != null) Text('变体父资产 #${asset.variantOf}'),
                const Divider(height: 24),
                Text('外观锚点', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(_formatAnchor(asset.appearanceAnchor)),
                const Divider(height: 24),
                if (_bodyParams(asset).isNotEmpty) ...[
                  Text('身体参数', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(_bodyParams(asset)),
                  const Divider(height: 24),
                ],
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
                final vHas =
                    vPath != null &&
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

  /// M19 T21.13 角色身体参数明细：身高 / 体型 / 服装套逐套展开。
  /// 非角色或字段全缺省时返回空串，整块不渲染。
  String _bodyParams(Asset asset) {
    if (asset.type != AssetTypes.character) return '';
    final lines = <String>[
      if (asset.heightCm != null) '身高：${asset.heightCm} cm',
      if (asset.bodyType != null) '体型：${asset.bodyType}',
    ];
    final sets = <Map>[];
    final rawSets = asset.costumeSets;
    if (rawSets != null && rawSets.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSets);
        if (decoded is List) {
          sets.addAll(decoded.whereType<Map>());
        }
      } on FormatException {
        // 忽略，视为未指定。
      }
    }
    if (sets.isNotEmpty) {
      lines.add('服装套：');
      for (var i = 0; i < sets.length; i++) {
        final name = setString(sets[i], 'name');
        final desc = setString(sets[i], 'description');
        lines.add('  ${i + 1}. ${name.isNotEmpty ? name : '未命名'}'
            '${desc.isEmpty ? '' : '——$desc'}');
      }
    }
    return lines.join('\n');
  }

  static String setString(Map set, String key) {
    final v = set[key];
    return v == null ? '' : v.toString().trim();
  }
}

/// 资产图历史版本面板（M17 T19.2）：读快照表 kind=image 的记录，
/// 每条对应一份独立落盘文件，点击即切换指针，不重跑生成。
class _ImageHistoryPanel extends ConsumerWidget {
  const _ImageHistoryPanel({
    required this.assetId,
    required this.currentPath,
    required this.working,
    required this.onReplace,
    required this.onSelect,
  });

  final int assetId;
  final String? currentPath;
  final bool working;
  final VoidCallback onReplace;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revisions =
        ref.watch(assetRevisionsProvider(assetId)).value ??
        const <AssetRevision>[];
    return ImageVersionPanel(
      items: [
        for (final r in revisions)
          if (r.kind == 'image')
            ImageVersionItem(
              label: '版本 ${r.revision} · ${formatSnapshotTime(r.createdAt)}',
              path: imagePathOfSnapshot(r.snapshot),
              subtitle: r.summary,
            ),
      ],
      currentPath: currentPath,
      onSelect: onSelect,
      onReplace: onReplace,
      working: working,
    );
  }
}
