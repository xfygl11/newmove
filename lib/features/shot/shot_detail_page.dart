import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../agent/active_image.dart';
import '../../agent/active_video.dart';
import '../../data/app_database.dart';
import '../asset/asset_providers.dart';
import '../provider_config/provider_models.dart';
import 'shot_models.dart';
import 'shot_providers.dart';
import 'video_prompt.dart';

/// 镜头详情：分镜图预览、提示词编辑、参考绑定、生成与验收。
///
/// 双 Tab：「分镜」覆盖 M5 图片链路；「视频模板」覆盖 M6 视频链路
/// （A9 参数选择 + 生成/重试 + video_player 预览）。
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

class _ShotDetailPageState extends ConsumerState<ShotDetailPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _promptCtrl;
  late TabController _tabCtrl;
  bool _editing = false;
  bool _generating = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shotAsync = ref.watch(shotProvider(widget.shotId));
    final framesAsync = ref.watch(shotFramesProvider(widget.shotId));
    final refsAsync = ref.watch(shotRefsProvider(widget.shotId));
    final assetsAsync = ref.watch(assetsByScriptProvider(widget.scriptId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(shotAsync.value?.globalSeq ?? '镜头详情'),
          bottom: TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: '分镜'),
              Tab(text: '视频模板'),
            ],
          ),
        ),
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

            return TabBarView(
              controller: _tabCtrl,
              children: [
                // ---- Tab 1：分镜（原 M5 内容） ----
                ListView(
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
                ),

                // ---- Tab 2：视频模板（M6） ----
                _VideoTab(shot: shot),
              ],
            );
          },
        ),
        bottomNavigationBar: shotAsync.maybeWhen(
          data: (shot) {
            if (shot == null) return null;
            // 底部操作栏只在「分镜」Tab 显示（图片链路）。
            return AnimatedBuilder(
              animation: _tabCtrl,
              builder: (context, _) {
                if (_tabCtrl.index != 0) return const SizedBox.shrink();
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
                              onPressed:
                                  _generating ? null : () => _generate(shot),
                              icon: _generating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.image_outlined),
                              label: Text(
                                switch (shot.status) {
                                  ShotStatuses.awaitingPrompt =>
                                    '先生成分镜提示词',
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
            );
          },
          orElse: () => null,
        ),
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

/// 视频模板 Tab（M6）：参数选择 + 生成/重试 + 预览。
class _VideoTab extends ConsumerStatefulWidget {
  const _VideoTab({required this.shot});

  final Shot shot;

  @override
  ConsumerState<_VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends ConsumerState<_VideoTab> {
  // 参数选择状态（A9.2：模型/画幅/分辨率/时长/音频）。
  String? _modelId;
  String _ratio = '16:9';
  String _resolution = '480p';
  double _durationSec = 5;
  bool _generateAudio = false;

  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final shot = widget.shot;
    final videoAsync = ref.watch(activeVideoProvider);
    final tasksAsync = ref.watch(videoTasksByShotProvider(shot.id));
    final tasks = tasksAsync.value ?? const <VideoTask>[];
    final activeTask = tasks.isNotEmpty ? tasks.first : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- 视频预览区 ----
        _VideoPreview(shot: shot),
        const SizedBox(height: 16),

        // ---- 生成参数 ----
        Text('生成参数', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        videoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('供应商配置读取失败：$e'),
          data: (video) => _ParamCard(
            video: video,
            modelId: _modelId ?? video?.modelId,
            onModelChanged: (v) => setState(() => _modelId = v),
            ratio: _ratio,
            onRatioChanged: (v) => setState(() => _ratio = v),
            resolution: _resolution,
            onResolutionChanged: (v) => setState(() => _resolution = v),
            durationSec: _durationSec,
            onDurationChanged: (v) => setState(() => _durationSec = v),
            generateAudio: _generateAudio,
            onAudioChanged: (v) => setState(() => _generateAudio = v),
          ),
        ),
        const SizedBox(height: 16),

        // ---- 操作按钮 ----
        _ActionRow(
          shot: shot,
          activeTask: activeTask,
          submitting: _submitting,
          onSubmit: () => _submit(),
          onRetry: activeTask == null ? null : () => _retry(activeTask.id),
        ),
        const SizedBox(height: 16),

        // ---- 任务历史 ----
        Text('任务记录（${tasks.length}）',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Text('暂无视频任务', style: Theme.of(context).textTheme.bodySmall)
        else
          for (final t in tasks) _TaskTile(task: t),
      ],
    );
  }

  /// 提交视频生成（需用户确认）。
  Future<void> _submit() async {
    final video = await ref.read(activeVideoProvider.future);
    if (!mounted) return;
    if (video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在「设置」配置可用的视频供应商（含 API Key 与模型）')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认生成视频'),
        content: Text(
          '将为本镜头生成视频（${_durationSec.round()}s · $_ratio · $_resolution'
          '${_generateAudio ? ' · 含音频' : ''}），'
          '供应商 ${video.provider.label} / 模型 ${_modelId ?? video.modelId}。',
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

    setState(() => _submitting = true);
    try {
      await ref.read(shotServiceProvider).submitVideo(
            shotId: widget.shot.id,
            video: video,
            params: VideoGenParams(
              modelId: _modelId ?? video.modelId,
              durationSec: _durationSec.round(),
              ratio: _ratio,
              resolution: _resolution,
              generateAudio: _generateAudio,
              referenceCount: 0,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('视频任务已提交，可在任务中心查看进度')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('提交失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 重试失败任务：复用参数快照。
  Future<void> _retry(int videoTaskId) async {
    final video = await ref.read(activeVideoProvider.future);
    if (!mounted) return;
    if (video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在「设置」配置可用的视频供应商')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(shotServiceProvider)
          .retryVideo(videoTaskId: videoTaskId, video: video);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已重新提交视频任务')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('重试失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

/// 参数卡片：模型下拉 + 画幅/分辨率/时长/音频选择。
class _ParamCard extends StatelessWidget {
  const _ParamCard({
    required this.video,
    required this.modelId,
    required this.onModelChanged,
    required this.ratio,
    required this.onRatioChanged,
    required this.resolution,
    required this.onResolutionChanged,
    required this.durationSec,
    required this.onDurationChanged,
    required this.generateAudio,
    required this.onAudioChanged,
  });

  final ActiveVideo? video;
  final String? modelId;
  final ValueChanged<String?> onModelChanged;
  final String ratio;
  final ValueChanged<String> onRatioChanged;
  final String resolution;
  final ValueChanged<String> onResolutionChanged;
  final double durationSec;
  final ValueChanged<double> onDurationChanged;
  final bool generateAudio;
  final ValueChanged<bool> onAudioChanged;

  @override
  Widget build(BuildContext context) {
    // models 落库为 JSON 字符串，展示前解码。
    final models =
        video == null ? const <ProviderModel>[] : ProviderModelCodec.decode(video!.provider.models);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (video == null)
              Text(
                '未配置视频供应商，请到「设置」添加',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              // 模型下拉。
              DropdownButtonFormField<String>(
                initialValue: modelId,
                decoration: const InputDecoration(
                  labelText: '模型',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final m in models)
                    DropdownMenuItem(value: m.id, child: Text(m.id)),
                ],
                onChanged: onModelChanged,
              ),
              const SizedBox(height: 12),
              // 画幅。
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('画幅', style: Theme.of(context).textTheme.bodySmall),
                  for (final r in _ratioOptionsList)
                    ChoiceChip(
                      label: Text(r),
                      selected: ratio == r,
                      onSelected: (_) => onRatioChanged(r),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 分辨率。
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('分辨率', style: Theme.of(context).textTheme.bodySmall),
                  for (final r in _resolutionOptionsList)
                    ChoiceChip(
                      label: Text(r),
                      selected: resolution == r,
                      onSelected: (_) => onResolutionChanged(r),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 时长滑条。
              Row(
                children: [
                  Text('时长 ${durationSec.round()}s',
                      style: Theme.of(context).textTheme.bodySmall),
                  Expanded(
                    child: Slider(
                      min: 4,
                      max: 15,
                      divisions: 11,
                      value: durationSec.clamp(4, 15),
                      onChanged: onDurationChanged,
                    ),
                  ),
                ],
              ),
              // 音频开关。
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('生成音频',
                    style: Theme.of(context).textTheme.bodySmall),
                value: generateAudio,
                onChanged: onAudioChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _ratioOptionsList = ['16:9', '9:16', '1:1'];
  static const _resolutionOptionsList = ['480p', '720p', '1080p'];
}

/// 操作行：生成/重试按钮。
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.shot,
    required this.activeTask,
    required this.submitting,
    required this.onSubmit,
    required this.onRetry,
  });

  final Shot shot;
  final VideoTask? activeTask;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final task = activeTask;
    final generating = shot.status == ShotStatuses.videoGenerating;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: (submitting || generating) ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.movie_creation_outlined),
            label: Text(switch (shot.status) {
              ShotStatuses.awaitingPrompt => '先生成分镜提示词',
              ShotStatuses.videoGenerating => '视频生成中…',
              _ => '生成视频',
            }),
          ),
        ),
        if (task != null && task.status == '失败') ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: submitting ? null : onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ],
    );
  }
}

/// 视频预览：video_player 播放本地 mp4；无产物时显示占位。
class _VideoPreview extends ConsumerStatefulWidget {
  const _VideoPreview({required this.shot});

  final Shot shot;

  @override
  ConsumerState<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends ConsumerState<_VideoPreview> {
  VideoPlayerController? _ctrl;
  String? _loadedPath;

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  /// 按路径懒加载播放器（路径变化时重建）。
  Future<void> _ensure(String path) async {
    if (_loadedPath == path) return;
    await _ctrl?.dispose();
    final ctrl = VideoPlayerController.file(File(path));
    _ctrl = ctrl;
    _loadedPath = path;
    await ctrl.initialize();
    if (!mounted) {
      await ctrl.dispose();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.shot.outputPath;
    final isVideo = widget.shot.outputType == 'video';
    final hasVideo = isVideo &&
        path != null &&
        path.isNotEmpty &&
        File(path).existsSync();

    // 有产物则初始化播放器。
    if (hasVideo) {
      _ensure(path);
      final ctrl = _ctrl;
      if (ctrl != null && ctrl.value.isInitialized) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AspectRatio(
                aspectRatio: ctrl.value.aspectRatio,
                child: VideoPlayer(ctrl),
              ),
              VideoProgressIndicator(ctrl, allowScrubbing: true),
              _PlayButton(ctrl: ctrl),
            ],
          ),
        );
      }
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Color(0xFF2A2A2A),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // 占位：显示分镜图或状态。
    final imagePath = widget.shot.outputPath;
    final hasImage = !isVideo &&
        imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: hasImage
            ? Image.file(File(imagePath), fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.movie_outlined, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      widget.shot.status == ShotStatuses.videoGenerating
                          ? '视频生成中…'
                          : '暂无视频，配置参数后生成',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// 预览播放/暂停按钮。
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.ctrl});

  final VideoPlayerController ctrl;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final playing = ctrl.value.isPlaying;
        return Positioned.fill(
          child: Center(
            child: IconButton.filledTonal(
              iconSize: 40,
              onPressed: () {
                if (playing) {
                  ctrl.pause();
                } else {
                  ctrl.play();
                }
              },
              icon: Icon(playing ? Icons.pause_circle_outline : Icons.play_circle_outline),
            ),
          ),
        );
      },
    );
  }
}

/// 视频任务记录行。
class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final VideoTask task;

  @override
  Widget build(BuildContext context) {
    final params = VideoGenParams.decode(task.paramsJson);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(switch (task.status) {
          '成功' => Icons.check_circle_outline,
          '失败' => Icons.error_outline,
          _ => Icons.hourglass_top,
        }),
        title: Text('${params.durationSec}s · ${params.ratio} · ${params.resolution}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('状态：${task.status} · 模型 ${params.modelId}'),
            if (task.error != null && task.error!.isNotEmpty)
              Text(
                task.error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 顶部预览（分镜 Tab）。
class _Preview extends StatelessWidget {
  const _Preview({required this.shot});

  final Shot shot;

  @override
  Widget build(BuildContext context) {
    final path = shot.outputPath;
    final hasImage = path != null &&
        path.isNotEmpty &&
        shot.outputType == 'image' &&
        File(path).existsSync();

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
