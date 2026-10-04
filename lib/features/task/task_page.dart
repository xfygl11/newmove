import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/active_video.dart';
import '../../core/settings/app_settings.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../../widgets/status_badge.dart';
import '../asset/asset_providers.dart';
import '../shot/shot_providers.dart';
import '../shot/shot_service.dart';
import '../shot/video_prompt.dart';

/// 任务中心：跨剧本汇总进行中的生成任务（M5 图片链路 + M6 视频链路）。
///
/// 分镜/资产行来自 Shot/Asset 状态派生；视频行来自 VideoTasks 活跃任务
/// （排队/生成中），并可手动/自动触发一次轮询回填（docs/02 §6 前台轮询）。
class TaskPage extends ConsumerStatefulWidget {
  const TaskPage({super.key});

  @override
  ConsumerState<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends ConsumerState<TaskPage>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 断点续跑：进入任务中心立即补一轮 + 周期轮询（间隔可配，页面退出即停）。
    _pollAllActive();
    _rescheduleTimer();
    // 设置变化时重排定时器（pollIntervalSec 变更后下一周期生效）。
    ref.listenManual(appSettingsProvider, (prev, next) {
      if (prev?.pollIntervalSec != next.pollIntervalSec) {
        _rescheduleTimer();
      }
    }, fireImmediately: false);
  }

  /// 按设置里的轮询间隔（重）建周期定时器。
  void _rescheduleTimer() {
    _pollTimer?.cancel();
    final interval = ref.read(appSettingsProvider).pollIntervalSec;
    _pollTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) => _pollAllActive(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 回前台立即补一轮轮询（后台期间错过的状态在此追回）。
    if (state == AppLifecycleState.resumed) {
      _pollAllActive();
    }
  }

  /// 批量重试所有失败的视频任务。
  Future<void> _retryAllFailed(
    BuildContext context,
    WidgetRef ref,
    List<VideoTask> tasks,
  ) async {
    final video = await ref.read(activeVideoProvider.future);
    if (video == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('请先在「设置」配置可用的视频供应商')));
      }
      return;
    }
    final failed = [
      for (final t in tasks)
        if (t.status == '失败') t,
    ];
    var ok = 0;
    var fail = 0;
    for (final task in failed) {
      try {
        await ref
            .read(shotServiceProvider)
            .retryVideo(videoTaskId: task.id, video: video);
        ok++;
      } catch (_) {
        fail++;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('批量重试完成：成功 $ok，失败 $fail')));
      _pollAllActive();
    }
  }

  /// 轮询所有活跃视频任务一次：并发发起，单任务异常不影响其余，
  /// 并发发起，单任务异常不影响其余；整轮时长受服务层单任务上限约束。
  Future<void> _pollAllActive() async {
    // 防重入：上一轮未结束时不再叠加。
    if (_polling) return;
    _polling = true;
    try {
      final dao = ref.read(videoTaskDaoProvider);
      final active = await dao.listActive();
      final service = ref.read(shotServiceProvider);
      await Future.wait<void>([
        for (final task in active) _pollOne(service, task),
      ]);
    } finally {
      _polling = false;
    }
  }

  Future<void> _pollOne(ShotService service, VideoTask task) async {
    try {
      await service.pollVideoTask(task.id);
    } catch (_) {
      // 单任务轮询异常忽略，下个周期重试。
    }
  }

  @override
  Widget build(BuildContext context) {
    final shotsAsync = ref.watch(activeShotsProvider);
    final assetsAsync = ref.watch(activeAssetsProvider);
    final videoTasksAsync = ref.watch(activeVideoTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('任务中心')),
      body: videoTasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (videoTasks) {
          final shots = shotsAsync.value ?? const <Shot>[];
          final assets = assetsAsync.value ?? const <Asset>[];

          if (shotsAsync.isLoading &&
              assetsAsync.isLoading &&
              videoTasksAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shots.isEmpty && assets.isEmpty && videoTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  const Text('暂无任务'),
                  const SizedBox(height: 4),
                  Text(
                    '图片 / 视频生成任务将在这里展示',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (videoTasks.isNotEmpty) ...[
                Text(
                  '视频任务（${videoTasks.length}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                _RetryFailedVideoRow(
                  tasks: videoTasks,
                  onRetryAll: () => _retryAllFailed(context, ref, videoTasks),
                ),
                const SizedBox(height: 8),
                for (final t in videoTasks)
                  _VideoTaskTile(task: t, onPoll: _pollAllActive),
                const SizedBox(height: 16),
              ],
              if (shots.isNotEmpty) ...[
                Text(
                  '分镜任务（${shots.length}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final shot in shots) _ShotTaskTile(shot: shot),
                const SizedBox(height: 16),
              ],
              if (assets.isNotEmpty) ...[
                Text(
                  '资产任务（${assets.length}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final asset in assets) _AssetTaskTile(asset: asset),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 找到镜头所属剧本→书→项目链，拼出可跳转路由；失败返回 null 不跳转。
Future<String?> _shotRoute(WidgetRef ref, Shot shot) async {
  final script = await ref.watch(scriptDaoProvider).find(shot.scriptId);
  final book = script == null
      ? null
      : await ref.watch(novelDaoProvider).findBook(script.bookId);
  if (script == null || book == null) return null;
  return '/script/${book.projectId}/script/${script.id}/shot/${shot.id}';
}

/// 视频任务行：参数摘要 + 状态徽章 + 重试。
class _VideoTaskTile extends ConsumerWidget {
  const _VideoTaskTile({required this.task, required this.onPoll});

  final VideoTask task;
  final VoidCallback onPoll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = VideoGenParams.decode(task.paramsJson);
    final failed = task.status == '失败';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.movie_outlined,
          color: failed ? Theme.of(context).colorScheme.error : null,
        ),
        title: Text(
          '视频 ${params.durationSec}s · ${params.ratio} · ${params.resolution}',
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
        trailing: StatusBadge(status: task.status),
        onTap: () async {
          final route = await _shotRouteByShotId(ref, task.shotId);
          if (route != null && context.mounted) context.push(route);
        },
      ),
    );
  }
}

/// 视频任务按 shotId 拼跳转路由。
Future<String?> _shotRouteByShotId(WidgetRef ref, int shotId) async {
  final shot = await ref.watch(shotDaoProvider).find(shotId);
  if (shot == null) return null;
  return _shotRoute(ref, shot);
}

/// 找到资产所属剧本→书→项目链，拼出资产详情路由；失败返回 null 不跳转。
Future<String?> _assetRoute(WidgetRef ref, Asset asset) async {
  final script = await ref.watch(scriptDaoProvider).find(asset.scriptId);
  final book = script == null
      ? null
      : await ref.watch(novelDaoProvider).findBook(script.bookId);
  if (script == null || book == null) return null;
  return '/script/${book.projectId}/script/${script.id}/asset/${asset.id}';
}

/// 资产任务行：点击跳转资产详情。
class _AssetTaskTile extends ConsumerWidget {
  const _AssetTaskTile({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage =
        asset.imagePath != null && File(asset.imagePath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: hasImage
                ? Image.file(File(asset.imagePath!), fit: BoxFit.cover)
                : const Icon(Icons.image_outlined),
          ),
        ),
        title: Text(asset.name),
        subtitle: Text('${asset.type} · ${asset.status}'),
        trailing: StatusBadge(status: asset.status),
        onTap: () async {
          final route = await _assetRoute(ref, asset);
          if (route != null && context.mounted) context.push(route);
        },
      ),
    );
  }
}

/// 分镜任务行。
class _ShotTaskTile extends ConsumerWidget {
  const _ShotTaskTile({required this.shot});

  final Shot shot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage =
        shot.outputPath != null && File(shot.outputPath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: hasImage
                ? Image.file(File(shot.outputPath!), fit: BoxFit.cover)
                : const Icon(Icons.movie_outlined),
          ),
        ),
        title: Text('${shot.globalSeq} 分镜图'),
        subtitle: Text('${shot.globalTimeRange} · ${shot.status}'),
        trailing: StatusBadge(status: shot.status),
        onTap: () async {
          final route = await _shotRoute(ref, shot);
          if (route != null && context.mounted) context.push(route);
        },
      ),
    );
  }
}

/// 失败视频任务「全部重试」按钮行。
class _RetryFailedVideoRow extends StatelessWidget {
  const _RetryFailedVideoRow({required this.tasks, required this.onRetryAll});

  final List<VideoTask> tasks;
  final VoidCallback onRetryAll;

  @override
  Widget build(BuildContext context) {
    final failedCount = tasks.where((t) => t.status == '失败').length;
    if (failedCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '有 $failedCount 个视频任务失败',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton.icon(
            onPressed: onRetryAll,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('全部重试'),
          ),
        ],
      ),
    );
  }
}
