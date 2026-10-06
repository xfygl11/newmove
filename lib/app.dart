import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:go_router/go_router.dart';

import 'features/asset/asset_detail_page.dart';
import 'features/asset/asset_gallery_page.dart';
import 'features/novel/character_manager_page.dart';
import 'features/novel/hook_manager_page.dart';
import 'features/novel/outline_editor_page.dart';
import 'features/novel/chapter_editor_page.dart';
import 'features/novel/novel_shelf_page.dart';
import 'features/novel/novel_setup_page.dart';
import 'features/novel/setting_workshop_page.dart';
import 'features/project/project_page.dart';
import 'features/provider_config/provider_config_page.dart';
import 'features/provider_config/prompt_override_page.dart';
import 'features/script/scene_edit_page.dart';
import 'features/script/script_detail_page.dart';
import 'features/script/script_page.dart';
import 'features/script/script_versions_page.dart';
import 'features/shot/shot_detail_page.dart';
import 'features/shot/shot_list_page.dart';
import 'features/skeleton/skeleton_page.dart';
import 'features/task/attempt_log_page.dart';
import 'features/task/task_page.dart';

/// 根 Navigator key：供需要脱离页面 context 弹 Toast 的地方使用
/// （如长耗时任务回调里 `context` 可能已卸载，直接 `ScaffoldMessenger.of(context)`
/// 会抛 deactivated ancestor）。
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey();

/// 取根 ScaffoldMessenger；页面卸载后仍可安全提示。
ScaffoldMessengerState get rootMessenger {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) {
    throw StateError('根 Navigator 尚未构建');
  }
  return ScaffoldMessenger.of(ctx);
}

/// 根路由：三 Tab（项目 / 任务 / 设置），分支各自维护导航栈。
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  // 非法/损坏的深链（如参数非数字）不白屏，显示可返回的错误页。
  errorBuilder: (context, state) => const BadRoutePage(reason: '路径无法识别'),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const ProjectPage())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/tasks', builder: (_, _) => const TaskPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const ProviderConfigPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/bad-route', builder: (_, _) => const BadRoutePage()),
    // 提示词三级覆盖编辑器（M19 T21.11）。
    GoRoute(
      path: '/settings/prompts/:projectId',
      redirect: (_, state) => requireIntParams(state, ['projectId']),
      builder: (_, state) =>
          PromptOverridePage(projectId: pathId(state, 'projectId')),
    ),
    // 生成台账：任务中心入口，只读展示历次生成尝试（M17 T19.4）。
    GoRoute(path: '/tasks/attempts', builder: (_, _) => const AttemptLogPage()),
    // 小说模块：进入后全屏覆盖底部 TabBar（对齐 docs/05 3.2 流程即导航）。
    GoRoute(
      path: '/novel/:projectId',
      redirect: (_, state) => requireIntParams(state, ['projectId']),
      builder: (_, state) =>
          NovelShelfPage(projectId: pathId(state, 'projectId')),
    ),
    GoRoute(
      path: '/novel/:projectId/chapter/:chapterId',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'chapterId']),
      builder: (_, state) =>
          ChapterEditorPage(chapterId: pathId(state, 'chapterId')),
    ),
    GoRoute(
      path: '/novel/:projectId/setup',
      redirect: (_, state) => requireIntParams(state, ['projectId']),
      builder: (_, state) =>
          NovelSetupPage(projectId: pathId(state, 'projectId')),
    ),
    GoRoute(
      path: '/novel/:projectId/settings',
      redirect: (_, state) => requireIntParams(state, ['projectId']),
      builder: (_, state) =>
          SettingWorkshopPage(projectId: pathId(state, 'projectId')),
    ),
    GoRoute(
      path: '/novel/:projectId/outline',
      redirect: (_, state) => requireIntParams(state, ['projectId']),
      builder: (_, state) =>
          OutlineEditorPage(projectId: pathId(state, 'projectId')),
    ),
    GoRoute(
      path: '/novel/:projectId/characters',
      redirect: (_, state) => requireIntParams(state, ['projectId']),
      builder: (_, state) =>
          CharacterManagerPage(projectId: pathId(state, 'projectId')),
    ),
    GoRoute(
      path: '/novel/:projectId/hooks',
      redirect: (_, state) => requireIntParams(state, ['projectId']),
      builder: (_, state) =>
          HookManagerPage(projectId: pathId(state, 'projectId')),
    ),
    // 剧本模块：小说改编为分场剧本（对齐 docs/05 4.4 流程即导航）。
    GoRoute(
      path: '/script/:projectId',
      redirect: (_, state) => requireIntParams(state, ['projectId']),
      builder: (_, state) => ScriptPage(projectId: pathId(state, 'projectId')),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'scriptId']),
      builder: (_, state) => ScriptDetailPage(
        projectId: pathId(state, 'projectId'),
        scriptId: pathId(state, 'scriptId'),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/versions',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'scriptId']),
      builder: (_, state) => ScriptVersionsPage(
        projectId: pathId(state, 'projectId'),
        scriptId: pathId(state, 'scriptId'),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/scene/:sceneId',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'scriptId', 'sceneId']),
      builder: (_, state) => SceneEditPage(
        projectId: pathId(state, 'projectId'),
        sceneId: pathId(state, 'sceneId'),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/skeleton',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'scriptId']),
      builder: (_, state) => SkeletonPage(
        projectId: pathId(state, 'projectId'),
        scriptId: pathId(state, 'scriptId'),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/assets',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'scriptId']),
      builder: (_, state) => AssetGalleryPage(
        projectId: pathId(state, 'projectId'),
        scriptId: pathId(state, 'scriptId'),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/asset/:assetId',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'scriptId', 'assetId']),
      builder: (_, state) => AssetDetailPage(
        projectId: pathId(state, 'projectId'),
        scriptId: pathId(state, 'scriptId'),
        assetId: pathId(state, 'assetId'),
      ),
    ),
    // 镜头模块：分镜图列表 + 详情（M5）。
    GoRoute(
      path: '/script/:projectId/script/:scriptId/shots',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'scriptId']),
      builder: (_, state) => ShotListPage(
        projectId: pathId(state, 'projectId'),
        scriptId: pathId(state, 'scriptId'),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/shot/:shotId',
      redirect: (_, state) =>
          requireIntParams(state, ['projectId', 'scriptId', 'shotId']),
      builder: (_, state) => ShotDetailPage(
        projectId: pathId(state, 'projectId'),
        scriptId: pathId(state, 'scriptId'),
        shotId: pathId(state, 'shotId'),
      ),
    ),
  ],
);

/// 校验路径参数均为整数；有非法项时返回错误页路径，交由路由跳转。
String? requireIntParams(GoRouterState state, List<String> keys) {
  for (final key in keys) {
    if (int.tryParse(state.pathParameters[key] ?? '') == null) {
      return '/bad-route';
    }
  }
  return null;
}

/// 解析路径参数为整数。[requireIntParams] 已拦截非法值，这里不再抛异常。
int pathId(GoRouterState state, String key) {
  return int.tryParse(state.pathParameters[key] ?? '') ?? 0;
}

/// 深链参数非法时的兜底页。
class BadRoutePage extends StatelessWidget {
  const BadRoutePage({super.key, this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面无法打开')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                reason ?? '链接中的参数无效，可能已被删除或不是本应用支持的格式。',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 应用根 Widget：深色主题 + 底部导航壳。
class NewmoveApp extends StatelessWidget {
  const NewmoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF5B6CFF);
    return MaterialApp.router(
      title: '小说动漫工坊',
      debugShowCheckedModeBanner: false,
      // flutter_quill 工具栏按钮的 tooltip 依赖 FlutterQuillLocalizations，
      // 未注册 delegate 时 QuillSimpleToolbar 构建即抛 MissingFlutterQuillLocalizationException。
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}

/// 底部导航壳，承载三个分支。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: '项目',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: '任务',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
