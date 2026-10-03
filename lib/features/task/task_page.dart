import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';

/// 任务中心：跨剧本汇总进行中的图片生成任务（M5：资产 + 分镜）。
///
/// 状态映射（docs/02 第 6 节）：排队（待分镜图/待生成）→ 生成中 → 待验收；
/// 视频异步轮询与失败重试在 M6 接入。
class TaskPage extends ConsumerWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shotsAsync = ref.watch(shotDaoProvider).watchActive();
    final assetsAsync = ref.watch(assetDaoProvider).watchActive();

    return Scaffold(
      appBar: AppBar(title: const Text('任务中心')),
      body: StreamBuilder<List<Shot>>(
        stream: shotsAsync,
        builder: (context, shotSnap) {
          return StreamBuilder<List<Asset>>(
            stream: assetsAsync,
            builder: (context, assetSnap) {
              final shots = shotSnap.data ?? const <Shot>[];
              final assets = assetSnap.data ?? const <Asset>[];

              if (shotSnap.connectionState == ConnectionState.waiting &&
                  assetSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (shots.isEmpty && assets.isEmpty) {
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

/// 任务状态徽章：生成中转圈，待验收青色，排队灰色。
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
