import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'script_providers.dart';

/// 剧本版本历史：展示每次重改编前的旧版本快照。
class ScriptVersionsPage extends ConsumerWidget {
  const ScriptVersionsPage({
    super.key,
    required this.projectId,
    required this.scriptId,
  });

  final int projectId;
  final int scriptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scriptAsync = ref.watch(scriptProvider(scriptId));
    final versionsAsync = ref.watch(scriptVersionsProvider(scriptId));

    return Scaffold(
      appBar: AppBar(title: Text('${scriptAsync.value?.title ?? '剧本'} · 版本历史')),
      body: versionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (versions) {
          if (versions.isEmpty) {
            return const Center(child: Text('暂无历史版本'));
          }
          return ListView.builder(
            itemCount: versions.length,
            itemBuilder: (context, i) {
              final v = versions[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.history)),
                title: Text('v${v.version}'),
                subtitle: Text('${v.createdAt.toLocal()}'),
                onTap: () => _showContent(context, v.version, v.content ?? ''),
              );
            },
          );
        },
      ),
    );
  }

  void _showContent(BuildContext context, int version, String content) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('v$version 内容'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Text(content)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
