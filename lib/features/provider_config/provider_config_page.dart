import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import 'provider_config_providers.dart';
import 'provider_edit_sheet.dart';
import 'provider_models.dart';

/// 模型供应商配置页：按 LLM / 图片 / 视频 三组增删改查。
class ProviderConfigPage extends ConsumerWidget {
  const ProviderConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(providerConfigListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('模型供应商')),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (providers) {
          if (providers.isEmpty) {
            return const _EmptyView();
          }
          return ListView(
            children: [
              for (final group in ProviderGroup.values) ...[
                _GroupSection(
                  group: group,
                  providers: providers
                      .where((p) => p.group == group.name)
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('还没有配置任何模型供应商'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => showProviderEditSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('添加供应商'),
          ),
        ],
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.providers});

  final ProviderGroup group;
  final List<ProviderConfig> providers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(group.label, style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                tooltip: '添加${group.label}供应商',
                onPressed: () =>
                    showProviderEditSheet(context, group: group),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        for (final p in providers)
          _ProviderCard(provider: p),
        if (providers.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('暂无', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  const _ProviderCard({required this.provider});

  final ProviderConfig provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ProviderModelCodec.decode(provider.models);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(provider.label),
        subtitle: Text(
          '${provider.baseUrl}\n${provider.protocol} · ${models.length} 个模型',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showProviderEditSheet(context, existing: provider),
      ),
    );
  }
}
