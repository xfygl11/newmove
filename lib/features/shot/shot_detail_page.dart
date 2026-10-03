import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/active_image.dart';
import '../../data/app_database.dart';
import '../asset/asset_providers.dart';
import 'shot_models.dart';
import 'shot_providers.dart';

/// 镜头详情：分镜图预览、提示词编辑、参考绑定、生成与验收。
class ShotDetailPage extends ConsumerStatefulWidget {
  const ShotDetailPage({
    super.key,
    required this.projectId,
    required this.scriptId,
    required this.shotId,
  });

  final int projectId;
  final int scriptId;
  final int shotId;

  @override
  ConsumerState<ShotDetailPage> createState() => _ShotDetailPageState();
}

class _ShotDetailPageState extends ConsumerState<ShotDetailPage> {
  late TextEditingController _promptCtrl;
  bool _editing = false;
  bool _generating = false;
  bool _initialized = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shotAsync = ref.watch(shotProvider(widget.shotId));
    final framesAsync = ref.watch(shotFramesProvider(widget.shotId));
    final refsAsync = ref.watch(shotRefsProvider(widget.shotId));
    final assetsAsync = ref.watch(assetsByScriptProvider(widget.scriptId));

    return Scaffold(
      appBar: AppBar(title: Text(shotAsync.value?.globalSeq ?? '镜头详情')),
      body: shotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (shot) {
          if (shot == null) {
            return const Center(child: Text('镜头不存在'));
          }

          // 首次构建时同步提示词到编辑器。
          if (!_initialized) {
            _promptCtrl = TextEditingController(text: shot.prompt);
            _initialized = true;
          }

          final refs = refsAsync.value ?? const <AssetRef>[];
          final assets = assetsAsync.value ?? const <Asset>[];
          final assetById = {for (final a in assets) a.id: a};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Preview(shot: shot),
              const SizedBox(height: 16),
              _PromptSection(
                shot: shot,
                controller: _promptCtrl,
                editing: _editing,
                onEditToggle: () => setState(() => _editing = !_editing),
                onSave: () => _savePrompt(shot),
              ),
              const SizedBox(height: 16),
              Text('参考绑定（${refs.length}）',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (refs.isEmpty)
                Text(
                  '暂无绑定，重新运行「生成分镜提示词」或先提取资产清单',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                for (var i = 0; i < refs.length; i++)
                  _RefTile(
                    order: i + 1,
                    asset: assetById[refs[i].assetId],
                    role: refs[i].role,
                  ),
              const SizedBox(height: 16),
              Text('分镜帧（${framesAsync.value?.length ?? 0}）',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final frame in framesAsync.value ?? const <ShotFrame>[])
                _FrameTile(frame: frame),
            ],
          );
        },
      ),
      bottomNavigationBar: shotAsync.maybeWhen(
        data: (shot) {
          if (shot == null) return null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (shot.status == ShotStatuses.reviewing) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(shotServiceProvider)
                            .rejectShot(shot.id),
                        child: const Text('驳回重生成'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _confirm(shot.id),
                        icon: const Icon(Icons.check),
                        label: const Text('确认分镜图'),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _generating ? null : () => _generate(shot),
                        icon: _generating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image_outlined),
                        label: Text(
                          switch (shot.status) {
                            ShotStatuses.awaitingPrompt => '先生成分镜提示词',
                            ShotStatuses.generating => '生成中…',
                            _ => '生成分镜图',
                          },
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

  /// 保存用户编辑后的提示词。
  Future<void> _savePrompt(Shot shot) async {
    await ref.read(shotServiceProvider).updatePrompt(
          shotId: shot.id,
          prompt: _promptCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _editing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('提示词已保存')));
  }

  /// 确认分镜图（待验收 → 分镜图已确认）。
  Future<void> _confirm(int shotId) async {
    await ref.read(shotServiceProvider).confirmShot(shotId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分镜图已确认')));
  }

  Future<void> _generate(Shot shot) async {
    if (shot.status == ShotStatuses.awaitingPrompt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在列表页生成分镜提示词')),
      );
      return;
    }
    final image = await ref.read(activeImageProvider.future);
    if (!mounted) return;
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在「设置」配置可用的图片供应商')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认生成'),
        content: Text(
          '将生成本镜分镜图（${refsHint(shot)}），供应商 ${image.provider.label} / 模型 ${image.modelId}。',
        ),
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
      await ref
          .read(shotServiceProvider)
          .generate(shotId: shot.id, image: image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String refsHint(Shot shot) => shot.prompt.contains('{{ref') ? '含参考图' : '无参考';
}

/// 顶部预览。
class _Preview extends StatelessWidget {
  const _Preview({required this.shot});

  final Shot shot;

  @override
  Widget build(BuildContext context) {
    final path = shot.outputPath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: hasImage
            ? Image.file(File(path), fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_outlined, size: 40),
                    const SizedBox(height: 8),
                    Text(shot.status, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
      ),
    );
  }
}

/// 提示词区块：只读展示 + 编辑切换。
class _PromptSection extends StatelessWidget {
  const _PromptSection({
    required this.shot,
    required this.controller,
    required this.editing,
    required this.onEditToggle,
    required this.onSave,
  });

  final Shot shot;
  final TextEditingController controller;
  final bool editing;
  final VoidCallback onEditToggle;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('分镜提示词', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: onEditToggle,
                  child: Text(editing ? '取消' : '编辑'),
                ),
                if (editing)
                  FilledButton(onPressed: onSave, child: const Text('保存')),
              ],
            ),
            const SizedBox(height: 8),
            if (editing)
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '支持 {{ref1}}、{{ref2}} 参考占位',
                ),
              )
            else if (shot.prompt.isEmpty)
              Text(
                '尚未生成提示词',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              SelectableText(shot.prompt),
          ],
        ),
      ),
    );
  }
}

/// 参考绑定行：顺序号 + 头像 + 角色/名称。
class _RefTile extends StatelessWidget {
  const _RefTile({
    required this.order,
    required this.asset,
    required this.role,
  });

  final int order;
  final Asset? asset;
  final String role;

  @override
  Widget build(BuildContext context) {
    final path = asset?.imagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: hasImage ? FileImage(File(path)) : null,
        child: hasImage
            ? null
            : const Icon(Icons.image_outlined, size: 18),
      ),
      title: Text('{{ref$order}} ${asset?.name ?? '未知资产'}'),
      subtitle: Text(role),
    );
  }
}

/// 分镜帧卡。
class _FrameTile extends StatelessWidget {
  const _FrameTile({required this.frame});

  final ShotFrame frame;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('帧 ${frame.seq} · ${frame.timeRange}',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text('${frame.shotSize} · ${frame.angle}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (frame.subject.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('主体：${frame.subject}'),
            ],
            if (frame.blocking.isNotEmpty)
              Text('站位：${frame.blocking}',
                  style: Theme.of(context).textTheme.bodySmall),
            if (frame.performance.isNotEmpty)
              Text('表演：${frame.performance}',
                  style: Theme.of(context).textTheme.bodySmall),
            if (frame.dialogue != null && frame.dialogue!.isNotEmpty)
              Text('台词：${frame.dialogue}',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
