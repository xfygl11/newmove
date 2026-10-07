import 'package:dio/dio.dart';
import 'package:newmove/core/network/dio_factory.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/update_checker.dart';
import '../../core/settings/app_settings.dart';
import '../../core/storage/providers.dart';
import '../../core/theme/app_themes.dart';
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
          const _ThemeSection(),
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

/// 外观主题区块：横向主题卡，点选即切换并持久化（见 AppThemeCatalog）。
class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(appSettingsProvider).themeId;
    final current = AppThemeCatalog.resolve(themeId);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('外观主题'),
            subtitle: Text('${current.name} · ${current.description}'),
          ),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: AppThemeCatalog.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final theme = AppThemeCatalog.all[index];
                return _ThemeSwatch(
                  theme: theme,
                  selected: theme.id == current.id,
                  onTap: () => ref
                      .read(appSettingsProvider.notifier)
                      .update(
                        ref
                            .read(appSettingsProvider)
                            .copyWith(themeId: theme.id),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 单张主题预览卡：用主题自身配色渲染缩略图，选中加描边与对勾。
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final AppTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Border.all(color: theme.primary, width: 2)
        : Border.all(color: Theme.of(context).colorScheme.outlineVariant);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 136,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _dot(theme.primary),
                const SizedBox(width: 6),
                _dot(theme.secondary),
                const SizedBox(width: 6),
                _dot(theme.tertiary),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle, size: 16, color: theme.primary),
              ],
            ),
            const SizedBox(height: 10),
            _bar(theme.surfaceContainerHigh, double.infinity),
            const SizedBox(height: 6),
            _bar(theme.secondary, 56),
            const Spacer(),
            Text(
              theme.name,
              style: TextStyle(
                color: theme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _bar(Color color, double width) => Container(
    width: width,
    height: 6,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
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

/// 检查更新区块。
///
/// **默认不自动拉取**：旧实现用 `AsyncNotifier.build` 挂 `ref.watch`，设置页
/// 一打开就静默向 `api.github.com` 发请求，用户无法关闭。现在改成点击后
/// 才拉取，离线/无网时给出可读提示而不是静默吞掉。
class _UpdateCheckTile extends ConsumerWidget {
  const _UpdateCheckTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updateCheckProvider);
    switch (status) {
      case UpdateCheckLoading():
        return const ListTile(
          leading: Icon(Icons.update),
          title: Text('检查更新'),
          trailing: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case UpdateCheckDone(:final check):
        return ListTile(
          leading: const Icon(Icons.update),
          title: const Text('检查更新'),
          subtitle: check.hasUpdate
              ? Text('发现新版本 ${check.latestVersion}，点击前往下载')
              : Text('已是最新版本（${check.latestVersion}）'),
          enabled: check.hasUpdate,
          onTap: () {
            final url = check.releaseUrl;
            if (url != null && url.isNotEmpty) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
          },
        );
      case UpdateCheckUnavailable(:final message):
        return ListTile(
          leading: const Icon(Icons.update),
          title: const Text('检查更新'),
          subtitle: Text(message),
          onTap: () => _check(ref),
        );
      case UpdateCheckIdle():
        return ListTile(
          leading: const Icon(Icons.update),
          title: const Text('检查更新'),
          subtitle: const Text('点击检查 GitHub 最新 release'),
          onTap: () => _check(ref),
        );
    }
  }

  void _check(WidgetRef ref) {
    ref.read(updateCheckProvider.notifier).checkNow();
  }
}

/// 检查更新状态。
///
/// 不用 `AsyncValue` 是为了让 build 阶段不产生网络请求——`AsyncNotifier` 的
/// build 在首次 watch 时必然执行，会把「自动拉取」写死进依赖图。
sealed class UpdateCheckStatus {
  const UpdateCheckStatus();
}

/// 尚未检查（默认态，设置页首次打开时）。
class UpdateCheckIdle extends UpdateCheckStatus {
  const UpdateCheckIdle();
}

/// 检查进行中。
class UpdateCheckLoading extends UpdateCheckStatus {
  const UpdateCheckLoading();
}

/// 检查成功。
class UpdateCheckDone extends UpdateCheckStatus {
  const UpdateCheckDone(this.check);

  final UpdateCheck check;
}

/// 检查失败，附可读原因。
class UpdateCheckUnavailable extends UpdateCheckStatus {
  const UpdateCheckUnavailable({required this.message});

  final String message;
}

final updateCheckProvider =
    NotifierProvider<UpdateCheckNotifier, UpdateCheckStatus>(
      UpdateCheckNotifier.new,
    );

class UpdateCheckNotifier extends Notifier<UpdateCheckStatus> {
  @override
  UpdateCheckStatus build() => const UpdateCheckIdle();

  /// 手动触发检查。离线/无网返回 [UpdateCheckUnavailable]，
  /// 不再静默返回占位版本号冒充「已是最新」。
  Future<void> checkNow() async {
    state = const UpdateCheckLoading();
    final checker = UpdateChecker(dio: createDio());
    try {
      state = UpdateCheckDone(await checker.checkLatest());
    } on DioException catch (e) {
      state = UpdateCheckUnavailable(message: '网络不可用：${_briefDioError(e)}');
    } on StateError catch (e) {
      state = UpdateCheckUnavailable(message: e.message);
    } on Object catch (e) {
      state = UpdateCheckUnavailable(message: '检查失败：$e');
    }
  }
}

String _briefDioError(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout => '请求超时',
    DioExceptionType.receiveTimeout => '响应超时',
    DioExceptionType.connectionError => '无法连接 GitHub',
    DioExceptionType.badResponse =>
      'GitHub 返回 ${e.response?.statusCode ?? '未知'}',
    _ => '网络错误',
  };
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
        leading: Icon(
          Icons.cloud_upload_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('一键添加 Agnes 预设'),
        subtitle: const Text('Agnes LLM / 图片 / 视频 3 个供应商（中国服务）'),
        trailing: const Icon(Icons.add),
        onTap: () => _addAgnesPreset(context, ref),
      ),
    );
  }

  Future<void> _addAgnesPreset(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => const _AgnesPresetDialog(),
    );

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

/// Agnes 预设输入框对话框。
///
/// controller 由本 State 持有并在 [dispose] 释放——只有退出动画彻底结束、
/// 元素真正 unmount 后才调用，避免「controller 已释放但 TextField 仍要重建」
/// 引发的 `TextEditingController used after being disposed` 与
/// `_dependents.isEmpty` 断言（framework.dart:6281）。
class _AgnesPresetDialog extends StatefulWidget {
  const _AgnesPresetDialog();

  @override
  State<_AgnesPresetDialog> createState() => _AgnesPresetDialogState();
}

class _AgnesPresetDialogState extends State<_AgnesPresetDialog> {
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加 Agnes AI 预设'),
      // 内容可滚动：3.47 的 Dialog 会把键盘 inset 加到外边距上，
      // 可用高度变小后非滚动内容会直接溢出（底部斜纹水印）。
      content: SingleChildScrollView(
        child: Column(
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
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'API Key（存系统 Keystore，不进 DB）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _keyController.text.trim()),
          child: const Text('确认'),
        ),
      ],
    );
  }
}
