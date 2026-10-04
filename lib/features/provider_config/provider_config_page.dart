import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/update_checker.dart';
import '../../core/settings/app_settings.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../project/project_providers.dart';
import 'agnes_presets.dart';
import 'provider_config_providers.dart';
import 'provider_edit_sheet.dart';
import 'provider_models.dart';

/// 设置页：通用设置 + 模型供应商配置 + 数据备份（M7 T8.1 / T9.3）。
class ProviderConfigPage extends ConsumerWidget {
  const ProviderConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(providerConfigListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _GeneralSection(),
          const _BackupSection(),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('模型供应商'),
          ),
          const _AgnesPresetRow(),
          listAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (providers) => Column(
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
            ),
          ),
        ],
      ),
    );
  }
}

/// 通用设置区块（借鉴 Toonflow general 面板：开关型偏好，本地有实效项）。
class _GeneralSection extends ConsumerWidget {
  const _GeneralSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('视频任务轮询间隔'),
            subtitle: const Text('任务中心自动刷新视频生成状态的频率'),
            trailing: SegmentedButton<int>(
              selected: {settings.pollIntervalSec},
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 10, label: Text('10s')),
                ButtonSegment(value: 30, label: Text('30s')),
                ButtonSegment(value: 60, label: Text('60s')),
              ],
              onSelectionChanged: (s) => ref
                  .read(appSettingsProvider.notifier)
                  .update(settings.copyWith(pollIntervalSec: s.first)),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.help_outline),
            title: const Text('生成前确认'),
            subtitle: const Text('提交图片/视频生成前弹出确认框'),
            value: settings.confirmBeforeGenerate,
            onChanged: (v) => ref
                .read(appSettingsProvider.notifier)
                .update(settings.copyWith(confirmBeforeGenerate: v)),
          ),
          const Divider(height: 1),
          const _UpdateCheckTile(),
        ],
      ),
    );
  }
}

/// 检查更新区块：拉取 GitHub 最新 release，有更新时提示跳转下载页。
class _UpdateCheckTile extends ConsumerWidget {
  const _UpdateCheckTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateCheckProvider);
    return ListTile(
      leading: const Icon(Icons.update),
      title: const Text('检查更新'),
      subtitle: state.when(
        data: (u) =>
            Text(u.hasUpdate ? '发现新版本 ${u.latestVersion}，点击前往下载' : '已是最新版本'),
        loading: () => const Text('检查中…'),
        error: (e, _) => Text('检查失败：$e'),
      ),
      enabled: _updateAvailable(state),
      onTap: () {
        final url = _releaseUrl(state);
        if (url == null) return;
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
    );
  }

  bool _updateAvailable(AsyncValue<UpdateCheck> state) {
    if (state is! AsyncData<UpdateCheck>) return false;
    return state.value.hasUpdate;
  }

  String? _releaseUrl(AsyncValue<UpdateCheck> state) {
    if (state is! AsyncData<UpdateCheck>) return null;
    return state.value.releaseUrl;
  }
}

final updateCheckProvider =
    AsyncNotifierProvider<UpdateCheckNotifier, UpdateCheck>(
      UpdateCheckNotifier.new,
    );

class UpdateCheckNotifier extends AsyncNotifier<UpdateCheck> {
  @override
  Future<UpdateCheck> build() async {
    final checker = UpdateChecker(dio: Dio());
    try {
      return await checker.checkLatest();
    } catch (_) {
      // 离线/无网时静默返回占位，避免界面报错。
      return const UpdateCheck(latestVersion: '0.0.0', hasUpdate: false);
    }
  }
}

/// 数据备份区块：导出当前项目 / 从 zip 恢复。
class _BackupSection extends ConsumerWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('导出项目备份'),
            subtitle: const Text('全部数据 + 图片/视频打包为 zip 分享出去'),
            onTap: () => _export(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('从备份恢复'),
            subtitle: const Text('选择 zip 备份包，导入为新项目'),
            onTap: () => _import(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final projects = await ref.read(projectDaoProvider).listAll();
    if (!context.mounted) return;
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('暂无项目可导出')));
      return;
    }
    final Project? target = projects.length == 1
        ? projects.first
        : await showDialog<Project>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: const Text('选择要导出的项目'),
              children: [
                for (final p in projects)
                  SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(p),
                    child: Text(p.name),
                  ),
              ],
            ),
          );
    if (target == null || !context.mounted) return;

    try {
      final path = await ref
          .read(backupServiceProvider)
          .exportProject(target.id);
      if (!context.mounted) return;
      // 导出后仅提示路径（无分享目标时也能拿到文件）。
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导出：${target.name}\n$path'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (picked.isEmpty || picked.single.path == null) return;
    try {
      final newId = await ref
          .read(backupServiceProvider)
          .importProject(picked.single.path!);
      ref.invalidate(projectListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导入成功，已创建新项目（id $newId）')));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    }
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
                onPressed: () => showProviderEditSheet(context, group: group),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        for (final p in providers) _ProviderCard(provider: p),
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
    final readme = provider.readme?.trim() ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(provider.label),
        subtitle: Text(
          '${provider.baseUrl}\n${provider.protocol} · ${models.length} 个模型'
          '${readme.isEmpty ? '' : '\n$readme'}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showProviderEditSheet(context, existing: provider),
      ),
    );
  }
}

/// 一键添加 Agnes AI 预设（LLM + 图片 + 视频 3 个供应商条目）。
class _AgnesPresetRow extends ConsumerWidget {
  const _AgnesPresetRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListTile(
        leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
        title: const Text('一键添加 Agnes 预设'),
        subtitle: const Text('Agnes LLM / 图片 / 视频 3 个供应商（中国服务）'),
        trailing: const Icon(Icons.add),
        onTap: () => _addAgnesPreset(context, ref),
      ),
    );
  }

  Future<void> _addAgnesPreset(BuildContext context, WidgetRef ref) async {
    final keyController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加 Agnes AI 预设'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '将创建 3 个供应商条目：\n'
              '  · Agnes LLM（agnes-2.5-flash）\n'
              '  · Agnes 图片（agnes-image-2.5-flash）\n'
              '  · Agnes 视频（agnes-video-2.5 + flash）\n\n'
              'Base URL：https://apihub.agnes-ai.cn/v1',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'API Key（存系统 Keystore，不进 DB）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, keyController.text.trim()),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    keyController.dispose();

    if (key == null || key.isEmpty) return;

    try {
      final dao = ref.read(providerDaoProvider);
      final keyStore = ref.read(secureKeyStoreProvider);
      await AgnesPresets.apply(
        dao: dao,
        keyWriter: keyStore.writeKey,
        apiKey: key,
      );
      ref.invalidate(providerConfigListProvider);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('已添加 Agnes AI 预设（3 个供应商）')),
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('添加失败：$e')));
      }
    }
  }
}
