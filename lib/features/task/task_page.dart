import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../shot/shot_providers.dart';
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

class _TaskPageState extends ConsumerState<TaskPage> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // 断点续跑：进入任务中心即拉起周期轮询（10s 一次，页面退出即停）。
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pollAllActive(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// 轮询所有活跃视频任务一次（逐个 try，单个失败不影响其余）。
  Future<void> _pollAllActive() async {
    final dao = ref.read(videoTaskDaoProvider);
    final active = await dao.listActive();
    for (final task in active) {
      try {
        await ref.read(shotServiceProvider).pollVideoTask(task.id);
      } catch (_) {
        // 单任务轮询异常忽略，下个周期重试。
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shotsAsync = ref.watch(shotDaoProvider).watchActive();
    final assetsAsync = ref.watch(assetDaoProvider).watchActive();
    final videoTasksAsync = ref.watch(activeVideoTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('任务中心')),
      body: videoTasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (videoTasks) {
          return StreamBuilder<List<Shot>>(
            stream: shotsAsync,
            builder: (context, shotSnap) {
              return StreamBuilder<List<Asset>>(
                stream: assetsAsync,
                builder: (context, assetSnap) {
                  final shots = shotSnap.data ?? const <Shot>[];
                  final assets = assetSnap.data ?? const <Asset>[];

                  if (shotSnap.connectionState == ConnectionState.waiting &&
                      assetSnap.connectionState == ConnectionState.waiting &&
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
                        Text('视频任务（${videoTasks.length}）',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final t in videoTasks)
                          _VideoTaskTile(task: t, onPoll: _pollAllActive),
                        const SizedBox(height: 16),
                      ],
                      if (shots.isNotEmpty) ...[
                        Text('分镜任务（${shots.length}）',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final shot in shots) _ShotTaskTile(shot: shot),
                        const SizedBox(height: 16),
                      ],
                      if (assets.isNotEmpty) ...[
                        Text('资产任务（${assets.length}）',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final asset in assets) _AssetTaskTile(asset: asset),
                      ],
                    ],
                  );
                },
              );
            },
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
        title: Text('视频 ${params.durationSec}s · ${params.ratio} · ${params.resolution}'),
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
        trailing: _TaskBadge(status: task.status),
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

/// 资产任务行。
class _AssetTaskTile extends StatelessWidget {
  const _AssetTaskTile({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
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
        trailing: _TaskBadge(status: asset.status),
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
        trailing: _TaskBadge(status: shot.status),
        onTap: () async {
          final route = await _shotRoute(ref, shot);
          if (route != null && context.mounted) context.push(route);
        },
      ),
    );
  }
}

/// 任务状态徽章：生成中转圈，待验收青色，成功绿，失败红，排队灰。
class _TaskBadge extends StatelessWidget {
  const _TaskBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Widget child;
    switch (status) {
      case '生成中':
        color = Colors.blue;
        child = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case '待验收':
        color = Colors.teal;
        child = Icon(Icons.check_circle_outline, color: color, size: 20);
      case '成功':
        color = Colors.green;
        child = Icon(Icons.check_circle_outline, color: color, size: 20);
      case '失败':
        color = Colors.red;
        child = Icon(Icons.error_outline, color: color, size: 20);
      default:
        color = Colors.grey;
        child = Icon(Icons.schedule, color: color, size: 20);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 6),
        Text(status, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
