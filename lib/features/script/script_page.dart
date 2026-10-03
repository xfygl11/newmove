import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../novel/novel_providers.dart';
import 'script_adapt_sheet.dart';
import 'script_providers.dart';

/// 剧本模块首页：某作品的剧本列表 + 新建改编入口。
class ScriptPage extends ConsumerWidget {
  const ScriptPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(novelBookByProjectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('剧本改编')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('请先在「AI 写小说」创建小说书'));
          }
          return _ScriptList(book: book);
        },
      ),
    );
  }
}

class _ScriptList extends ConsumerWidget {
  const _ScriptList({required this.book});

  final NovelBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scriptsAsync = ref.watch(scriptsByBookProvider(book.id));

    return Column(
      children: [
        ListTile(
          title: Text(book.title),
          subtitle: Text('选择原文片段，AI 改编为分场剧本'),
        ),
        Expanded(
          child: scriptsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (scripts) {
              if (scripts.isEmpty) {
                return const Center(child: Text('还没有剧本，点击下方「新建改编」开始'));
              }
              return ListView.builder(
                itemCount: scripts.length,
                itemBuilder: (context, i) => _ScriptTile(
                  projectId: book.projectId,
                  script: scripts[i],
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _showAdaptSheet(context, book),
              icon: const Icon(Icons.movie_creation_outlined),
              label: const Text('新建改编'),
            ),
          ),
        ),
      ],
    );
  }

  void _showAdaptSheet(BuildContext context, NovelBook book) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AdaptSheet(book: book),
    );
  }
}

class _ScriptTile extends ConsumerWidget {
  const _ScriptTile({required this.projectId, required this.script});

  final int projectId;
  final Script script;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenesAsync = ref.watch(scenesByScriptProvider(script.id));
    final sceneCount = scenesAsync.value?.length ?? 0;
    final statusColor = script.status == '定稿' ? Colors.green : Colors.amber;

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.movie_outlined)),
      title: Text(script.title),
      subtitle: Text('v${script.version} · $sceneCount 场 · ${script.fidelityMode}'),
      trailing: Text(script.status, style: TextStyle(color: statusColor)),
      onTap: () => context.push('/script/$projectId/script/${script.id}'),
    );
  }
}

