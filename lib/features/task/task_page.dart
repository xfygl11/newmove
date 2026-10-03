import 'package:flutter/material.dart';

/// 任务中心：生成任务队列（M5/M6 填充，M0 提供空态）。
class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务中心')),
      body: Center(
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
      ),
    );
  }
}
