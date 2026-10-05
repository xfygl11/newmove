import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../agent/active_image.dart';
import '../../agent/active_video.dart';
import '../../core/status_constants.dart';
import '../../data/app_database.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/image_version_panel.dart';
import '../asset/asset_models.dart';
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
  bool _imageWorking = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // 预初始化，避免镜头不存在（shot == null）时 dispose 触发 LateInitializationError。
    _promptCtrl = TextEditingController();
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
              _promptCtrl.text = shot.prompt;
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
                    _ShotImageHistoryPanel(
                      shotId: shot.id,
                      currentPath: shot.outputType == 'image'
                          ? shot.outputPath
                          : null,
                      working: _imageWorking,
                      onSelect: (path) => _selectImageVersion(shot, path),
                      onReplace: () => _replaceShotImage(shot),
                    ),
                    const SizedBox(height: 16),
                    _PromptSection(
                      shot: shot,
                      controller: _promptCtrl,
                      editing: _editing,
                      onEditToggle: () => setState(() => _editing = !_editing),
                      onSave: () => _savePrompt(shot),
                    ),
                    const SizedBox(height: 16),
                    _CostumeOverridesSection(
                      shot: shot,
                      refs: refs,
                      assets: assets,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '参考绑定（${refs.length}）',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                    Text(
                      '分镜帧（${framesAsync.value?.length ?? 0}）',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final frame
                        in framesAsync.value ?? const <ShotFrame>[])
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
                              onPressed: _generating
                                  ? null
                                  : () => _generate(shot),
                              icon: _generating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.image_outlined),
                              label: Text(switch (shot.status) {
                                ShotStatuses.awaitingPrompt => '先生成分镜提示词',
                                ShotStatuses.generating => '生成中…',
                                _ => '生成分镜图',
                              }),
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
    await ref
        .read(shotServiceProvider)
        .updatePrompt(shotId: shot.id, prompt: _promptCtrl.text.trim());
    if (!mounted) return;
    setState(() => _editing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('提示词已保存')));
  }

  /// 切换到分镜图历史版本（M17 T19.3）。
  Future<void> _selectImageVersion(Shot shot, String outputPath) async {
    setState(() => _imageWorking = true);
    try {
      await ref
          .read(shotServiceProvider)
          .selectImageVersion(shotId: shot.id, outputPath: outputPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已切换分镜图版本')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('切换失败：$e')));
    } finally {
      if (mounted) setState(() => _imageWorking = false);
    }
  }

  /// 用本地图片替换分镜图（≤100MB），旧图已存为历史版本。
  Future<void> _replaceShotImage(Shot shot) async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;
    final path = result.single.path;
    if (path == null || !mounted) return;
    setState(() => _imageWorking = true);
    try {
      await ref
          .read(shotServiceProvider)
          .replaceImage(shotId: shot.id, sourcePath: path);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已替换分镜图')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('替换失败：$e')));
    } finally {
      if (mounted) setState(() => _imageWorking = false);
    }
  }

  /// 确认分镜图（待验收 → 分镜图已确认）。
  Future<void> _confirm(int shotId) async {
    await ref.read(shotServiceProvider).confirmShot(shotId);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('分镜图已确认')));
  }

  Future<void> _generate(Shot shot) async {
    if (shot.status == ShotStatuses.awaitingPrompt) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先在列表页生成分镜提示词')));
      return;
    }
    final image = await ref.read(activeImageProvider.future);
    if (!mounted) return;
    if (image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先在「设置」配置可用的图片供应商')));
      return;
    }
    // 统一走 ConfirmSheet：开关关闭时直接放行（设置页 T9.3）。
    if (!await ConfirmSheet.confirm(
      context,
      objectName: '分镜图 · 镜头 ${shot.globalSeq}',
      gate: '分镜图生成（需用户逐张验收后才可用于视频）',
      quantity: '1 次生成',
      promptPreview: shot.prompt,
      params: [
        '供应商：${image.provider.label}',
        '模型：${image.modelId}',
        refsHint(shot),
      ],
    )) {
      return;
    }

    setState(() => _generating = true);
    try {
      await ref
          .read(shotServiceProvider)
          .generate(shotId: shot.id, image: image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('生成失败：$e')));
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
  // 参数选择状态（A9.2：模型/画幅/分辨率/时长/音频/首帧通道）。
  String? _modelId;
  String _ratio = '16:9';
  String _resolution = '480p';
  double _durationSec = 5;
  bool _generateAudio = false;
  bool _useFirstFrame = false;

  bool _submitting = false;

  /// 按当前模型能力归一化参数（时长/分辨率回落合法值、音频三态、首帧通道）。
  (ProviderModel?, VideoGenParams) _effective(ActiveVideo? video) {
    final models = video == null
        ? const <ProviderModel>[]
        : ProviderModelCodec.decode(video.provider.models)
              .where((m) => m.enabled)
              .toList();
    final selectedId = _modelId ?? video?.modelId;
    final model = models.isEmpty
        ? null
        : models.firstWhere(
            (m) => m.id == selectedId,
            orElse: () => models.first,
          );
    final duration =
        model?.normalizeDuration(_durationSec.round()) ?? _durationSec.round();
    final resolution =
        model?.normalizeResolution(duration, _resolution) ?? _resolution;
    final audio = model == null
        ? _generateAudio
        : (model.audioRequired
              ? true
              : model.audioDisabled
              ? false
              : _generateAudio);
    return (
      model,
      VideoGenParams(
        modelId: model?.id ?? selectedId ?? '',
        durationSec: duration,
        ratio: _ratio,
        resolution: resolution,
        generateAudio: audio,
        referenceCount: 0,
        useFirstFrame: (model?.supportsStartFrame ?? false) && _useFirstFrame,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shot = widget.shot;
    final videoAsync = ref.watch(activeVideoProvider);
    final tasksAsync = ref.watch(videoTasksByShotProvider(shot.id));
    final tasks = tasksAsync.value ?? const <VideoTask>[];
    final activeTask = tasks.isNotEmpty ? tasks.first : null;

    final video = videoAsync.value;
    final (selectedModel, params) = _effective(video);

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
          data: (_) => _ParamCard(
            video: video,
            selectedModel: selectedModel,
            modelId: params.modelId.isEmpty ? null : params.modelId,
            onModelChanged: (v) => setState(() => _modelId = v),
            ratio: params.ratio,
            onRatioChanged: (v) => setState(() => _ratio = v),
            resolution: params.resolution,
            onResolutionChanged: (v) => setState(() => _resolution = v),
            durationSec: params.durationSec.toDouble(),
            onDurationChanged: (v) =>
                setState(() => _durationSec = v.toDouble()),
            generateAudio: params.generateAudio,
            onAudioChanged: (v) => setState(() => _generateAudio = v),
            supportsFirstFrame: selectedModel?.supportsStartFrame ?? false,
            useFirstFrame: params.useFirstFrame,
            onFirstFrameChanged: (v) => setState(() => _useFirstFrame = v),
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
          onCancel:
              (activeTask != null &&
                  VideoTaskStatuses.inProgress.contains(activeTask.status))
              ? () => _cancel(activeTask.id)
              : null,
        ),
        const SizedBox(height: 16),

        // ---- 历史版本 + 替换输出 ----
        _HistoryVersions(
          tasks: tasks,
          currentPath: shot.outputPath,
          onSelect: _selectVersion,
          onImport: _importVideo,
        ),
        const SizedBox(height: 16),

        // ---- 任务历史 ----
        Text(
          '任务记录（${tasks.length}）',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
    // 「生成前确认」开关关闭时直接提交（设置页 T9.3）。
    final (_, params) = _effective(video);

    // 临执行复核：时长与容量校验（M16）。error 级条目必须逐条回传，
    // 由用户确认后才放行；warn 级只在列表页面板提示。
    final models = ProviderModelCodec.decode(video.provider.models);
    final selectedModel = models.firstWhere(
      (m) => m.id == params.modelId,
      orElse: () => video.model,
    );
    final svc = ref.read(shotServiceProvider);
    final budgetIssues = await svc.listBudgetIssues(
      widget.shot.scriptId,
      videoModel: selectedModel,
    );
    if (!mounted) return;
    final budgetErrors = svc.errorIssuesOf(budgetIssues);
    final note = budgetErrors.isEmpty
        ? ''
        : '时长约束冲突（确认后仍会提交）：\n'
              '${budgetErrors.map((e) => '· ${e.noteLine}').join('\n')}';
    if (!await ConfirmSheet.confirm(
      context,
      objectName: '镜头视频 · ${widget.shot.globalSeq}',
      gate: '镜头视频生成（授权范围仅限本次镜头的视频）',
      quantity: '1 次生成',
      promptPreview: widget.shot.prompt,
      params: [
        '时长 ${params.durationSec}s · 比例 ${params.ratio} · 分辨率 ${params.resolution}',
        '音频：${params.generateAudio ? '含音频' : '无音频'}',
        '首帧：${params.useFirstFrame ? '锁定分镜图为首帧' : '不锁定'}',
        '供应商：${video.provider.label}',
        '模型：${params.modelId}',
      ],
      note: note,
      confirmLabel: budgetErrors.isEmpty
          ? ConfirmSheet.confirmLabel
          : '知道了，仍要提交',
    )) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(shotServiceProvider)
          .submitVideo(shotId: widget.shot.id, video: video, params: params);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('视频任务已提交，可在任务中心查看进度')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('提交失败：$e')));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先在「设置」配置可用的视频供应商')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(shotServiceProvider)
          .retryVideo(videoTaskId: videoTaskId, video: video);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已重新提交视频任务')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('重试失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 取消进行中任务（本地取消，停轮询 + 回滚镜头状态）。
  Future<void> _cancel(int videoTaskId) async {
    setState(() => _submitting = true);
    try {
      await ref.read(shotServiceProvider).cancelVideoTask(videoTaskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已取消视频生成')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('取消失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 切换镜头采用的视频版本（历史成功任务）。
  Future<void> _selectVersion(String path) async {
    try {
      await ref
          .read(shotServiceProvider)
          .selectVideoVersion(shotId: widget.shot.id, outputPath: path);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已切换视频版本')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('切换失败：$e')));
      }
    }
  }

  /// 用本地视频文件替换镜头产物（≤100MB）。
  Future<void> _importVideo() async {
    final result = await FilePicker.pickFiles(type: FileType.video);
    if (result.isEmpty) return;
    final path = result.single.path;
    if (path == null) return;
    try {
      await ref
          .read(shotServiceProvider)
          .replaceVideo(shotId: widget.shot.id, sourcePath: path);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已替换视频')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('替换失败：$e')));
      }
    }
  }
}

/// 参数卡片：模型下拉 + 画幅/分辨率/时长/音频选择。
class _ParamCard extends StatelessWidget {
  const _ParamCard({
    required this.video,
    required this.selectedModel,
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
    required this.supportsFirstFrame,
    required this.useFirstFrame,
    required this.onFirstFrameChanged,
  });

  final ActiveVideo? video;
  final ProviderModel? selectedModel;
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
  final bool supportsFirstFrame;
  final bool useFirstFrame;
  final ValueChanged<bool> onFirstFrameChanged;

  /// 可选分辨率：优先模型能力（按时长），否则回退通用词表。
  List<String> _resolutionOptions() {
    final fromCap =
        selectedModel?.resolutionsFor(durationSec.round()) ?? const [];
    return fromCap.isNotEmpty ? fromCap : _fallbackResolutions;
  }

  /// 可选时长（模型能力，升序）；无能力时回退 4-15 连续区间。
  List<int> get _durationOptions =>
      selectedModel?.supportedDurations ?? const [];

  @override
  Widget build(BuildContext context) {
    final models = video == null
        ? const <ProviderModel>[]
        : ProviderModelCodec.decode(video!.provider.models)
              .where((m) => m.enabled)
              .toList();
    final resolutions = _resolutionOptions();
    final durations = _durationOptions;
    final effectiveResolution = resolutions.contains(resolution)
        ? resolution
        : resolutions.first;
    final effectiveDuration = durations.isEmpty
        ? durationSec.round()
        : durationSec.round();

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
              // 分辨率（按时长联动）。
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('分辨率', style: Theme.of(context).textTheme.bodySmall),
                  for (final r in resolutions)
                    ChoiceChip(
                      label: Text(r),
                      selected: effectiveResolution == r,
                      onSelected: (_) => onResolutionChanged(r),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 时长：有模型能力时离散选择，否则 4-15s 连续滑条。
              if (durations.isNotEmpty)
                _DurationSlider(
                  options: durations,
                  value: effectiveDuration,
                  onChanged: onDurationChanged,
                )
              else
                Row(
                  children: [
                    Text(
                      '时长 $effectiveDuration s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
              // 音频：模型强制开/关时禁用开关。
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  selectedModel?.audioRequired == true
                      ? '生成音频（模型强制开启）'
                      : selectedModel?.audioDisabled == true
                      ? '生成音频（模型不支持）'
                      : '生成音频',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: generateAudio,
                onChanged:
                    (selectedModel?.audioRequired == true ||
                        selectedModel?.audioDisabled == true)
                    ? null
                    : onAudioChanged,
              ),
              // 首帧通道：仅模型支持时显示（A9.2）。
              if (supportsFirstFrame)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '以分镜图作首帧（锁定起手画面）',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: useFirstFrame,
                  onChanged: onFirstFrameChanged,
                ),
            ],
          ],
        ),
      ),
    );
  }

  static const _ratioOptionsList = ['16:9', '9:16', '1:1'];
  static const _fallbackResolutions = ['480p', '720p', '1080p'];
}

/// 离散时长滑条：在模型支持的时长列表上取最近索引。
class _DurationSlider extends StatelessWidget {
  const _DurationSlider({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<int> options;
  final int value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    var index = options.indexOf(value);
    if (index < 0) {
      index = 0;
      var best = (options.first - value).abs();
      for (var i = 1; i < options.length; i++) {
        final d = (options[i] - value).abs();
        if (d < best) {
          best = d;
          index = i;
        }
      }
    }
    return Row(
      children: [
        Text(
          '时长 ${options[index]}s',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: (options.length - 1).toDouble(),
            divisions: options.length > 1 ? options.length - 1 : null,
            value: index.toDouble(),
            label: '${options[index]}s',
            onChanged: (v) => onChanged(options[v.round()].toDouble()),
          ),
        ),
      ],
    );
  }
}

/// 操作行：生成/重试/取消按钮。
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.shot,
    required this.activeTask,
    required this.submitting,
    required this.onSubmit,
    required this.onRetry,
    required this.onCancel,
  });

  final Shot shot;
  final VideoTask? activeTask;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

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
        if (task != null && task.status == VideoTaskStatuses.failed) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: submitting ? null : onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
        if (onCancel != null) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: submitting ? null : onCancel,
            icon: const Icon(Icons.stop),
            label: const Text('停止'),
          ),
        ],
      ],
    );
  }
}

/// 历史版本：成功任务产物列表（可切换采用版本）+ 替换输出入口。
class _HistoryVersions extends StatelessWidget {
  const _HistoryVersions({
    required this.tasks,
    required this.currentPath,
    required this.onSelect,
    required this.onImport,
  });

  final List<VideoTask> tasks;
  final String? currentPath;
  final ValueChanged<String> onSelect;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final versions = [
      for (final t in tasks)
        if (t.outputPath != null && t.status == VideoTaskStatuses.succeeded) t,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '视频版本（${versions.length}）',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('替换'),
                ),
              ],
            ),
            if (versions.isEmpty)
              Text(
                '暂无成功版本，可生成视频或从本地替换',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final t in versions)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    currentPath == t.outputPath
                        ? Icons.check_circle
                        : Icons.video_library,
                    size: 20,
                  ),
                  title: Text(
                    '版本 ${t.id} · ${DateTime.fromMillisecondsSinceEpoch((t.createdAt.millisecondsSinceEpoch ~/ 1000) * 1000).toLocal()}',
                  ),
                  subtitle: currentPath == t.outputPath
                      ? const Text('当前采用')
                      : null,
                  onTap: currentPath == t.outputPath
                      ? null
                      : () => onSelect(t.outputPath!),
                ),
          ],
        ),
      ),
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
    final hasVideo =
        isVideo && path != null && path.isNotEmpty && File(path).existsSync();

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
    final hasImage =
        !isVideo &&
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
              icon: Icon(
                playing
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
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
          VideoTaskStatuses.succeeded => Icons.check_circle_outline,
          VideoTaskStatuses.failed => Icons.error_outline,
          _ => Icons.hourglass_top,
        }),
        title: Text(
          '${params.durationSec}s · ${params.ratio} · ${params.resolution}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('状态：${task.status} · 模型 ${params.modelId}'),
            if (task.error != null && task.error!.isNotEmpty)
              Text(
                task.error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    final hasImage =
        path != null &&
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
                    Text(
                      shot.status,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
            ...shot.cinemaParamsOf(context),
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
              Text('尚未生成提示词', style: Theme.of(context).textTheme.bodySmall)
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
        child: hasImage ? null : const Icon(Icons.image_outlined, size: 18),
      ),
      title: Text('{{ref$order}} ${asset?.name ?? '未知资产'}'),
      subtitle: Text(role),
    );
  }
}

/// M19 T21.12 段级摄影参数只读展示：字段缺省时整行跳过，全缺省不占位。
extension ShotCinemaParams on Shot {
  List<Widget> cinemaParamsOf(BuildContext context) {
    final all = [
      ('构图', composition),
      ('焦距景深', lens),
      ('机位', cameraPosition),
      ('视线', eyeline),
      ('焦点', focus),
      ('稳定性', stability),
      ('走位', blocking),
      (
        '对白占比',
        (dialogueStartRatio != null || dialogueEndRatio != null)
            ? '${dialogueStartRatio ?? '-'}%–${dialogueEndRatio ?? '-'}%'
            : null,
      ),
    ];
    final entries = all.where((e) => e.$2 != null && e.$2!.isNotEmpty);

    if (entries.isEmpty) return const [];

    return [
      const SizedBox(height: 4),
      for (final entry in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '${entry.$1}：${entry.$2}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ];
  }
}

/// 镜头级服装覆盖编辑（M19 T21.13）。
///
/// 只对本镜头参考绑定里、且已登记服装套的角色开放；套名取自该角色的
/// costumeSets，不在清单内不可选。本镜头没有出镜角色时整段不占位。
class _CostumeOverridesSection extends ConsumerStatefulWidget {
  const _CostumeOverridesSection({
    required this.shot,
    required this.refs,
    required this.assets,
  });

  final Shot shot;
  final List<AssetRef> refs;
  final List<Asset> assets;

  @override
  ConsumerState<_CostumeOverridesSection> createState() =>
      _CostumeOverridesSectionState();
}

class _CostumeOverridesSectionState
    extends ConsumerState<_CostumeOverridesSection> {
  late Map<String, String> _selection;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selection = {
      for (final o in _decode(widget.shot.costumeOverrides)) o.stableId: o.name,
    };
  }

  static List<ShotCostumeOverride> _decode(String? raw) =>
      ShotCostumeOverride.decode(raw);

  /// 本镜头出镜且已登记服装套的角色资产。
  List<Asset> get _characters {
    final assetById = {for (final a in widget.assets) a.id: a};
    return [
      for (final ref in widget.refs)
        if (ref.role.contains('角色'))
          if (assetById[ref.assetId]?.costumeNames.isNotEmpty ?? false)
            assetById[ref.assetId]!,
    ];
  }

  bool get _dirty {
    final saved = {
      for (final o in _decode(widget.shot.costumeOverrides)) o.stableId: o.name,
    };
    if (saved.length != _selection.length) return true;
    return saved.entries.any((e) => _selection[e.key] != e.value);
  }

  Future<void> _save() async {
    final overrides = [
      for (final entry in _selection.entries)
        if (entry.value.isNotEmpty)
          ShotCostumeOverride(stableId: entry.key, name: entry.value),
    ];
    setState(() => _saving = true);
    try {
      await ref
          .read(shotServiceProvider)
          .updateCostumeOverrides(shotId: widget.shot.id, overrides: overrides);
      if (!mounted) return;
      setState(() {
        _selection = {for (final o in overrides) o.stableId: o.name};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(overrides.isEmpty ? '已清除服装覆盖' : '服装覆盖已保存')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final characters = _characters;
    if (characters.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('服装覆盖', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (_dirty)
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('保存'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final asset in characters) ...[
              DropdownButton<String>(
                value: _dropdownValue(asset),
                onChanged: (value) {
                  setState(() {
                    final name = value ?? '';
                    if (name.isEmpty) {
                      _selection.remove(asset.stableId);
                    } else {
                      _selection[asset.stableId] = name;
                    }
                  });
                },
                items: [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text('${asset.name}：沿用基础态'),
                  ),
                  for (final name in asset.costumeNames)
                    DropdownMenuItem<String>(
                      value: name,
                      child: Text('${asset.name}：$name'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }

  /// 下拉当前值：未覆盖时落回空串（沿用基础态），覆盖套名不在清单里时
  /// 也落回空串，避免 DropdownButton 因找不到 value 而断言失败。
  String _dropdownValue(Asset asset) {
    final name = _selection[asset.stableId];
    if (name == null || name.isEmpty) return '';
    return asset.costumeNames.contains(name) ? name : '';
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
                Text(
                  '帧 ${frame.seq} · ${frame.timeRange}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '${frame.shotSize} · ${frame.angle}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (frame.subject.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('主体：${frame.subject}'),
            ],
            if (frame.blocking.isNotEmpty)
              Text(
                '站位：${frame.blocking}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (frame.performance.isNotEmpty)
              Text(
                '表演：${frame.performance}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (frame.dialogue != null && frame.dialogue!.isNotEmpty)
              Text(
                '台词：${frame.dialogue}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// 分镜图历史版本面板（M17 T19.3）：读快照表 kind=image 的记录。
class _ShotImageHistoryPanel extends ConsumerWidget {
  const _ShotImageHistoryPanel({
    required this.shotId,
    required this.currentPath,
    required this.working,
    required this.onSelect,
    required this.onReplace,
  });

  final int shotId;
  final String? currentPath;
  final bool working;
  final ValueChanged<String> onSelect;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revisions =
        ref.watch(shotRevisionsProvider(shotId)).value ??
        const <ShotRevision>[];
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
