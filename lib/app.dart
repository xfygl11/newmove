import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/asset/asset_detail_page.dart';
import 'features/asset/asset_gallery_page.dart';
import 'features/novel/character_manager_page.dart';
import 'features/novel/outline_editor_page.dart';
import 'features/novel/chapter_editor_page.dart';
import 'features/novel/novel_shelf_page.dart';
import 'features/novel/setting_workshop_page.dart';
import 'features/project/project_page.dart';
import 'features/provider_config/provider_config_page.dart';
import 'features/script/scene_edit_page.dart';
import 'features/script/script_detail_page.dart';
import 'features/script/script_page.dart';
import 'features/script/script_versions_page.dart';
import 'features/shot/shot_detail_page.dart';
import 'features/shot/shot_list_page.dart';
import 'features/skeleton/skeleton_page.dart';
import 'features/task/task_page.dart';

/// 根路由：三 Tab（项目 / 任务 / 设置），分支各自维护导航栈。
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
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
    // 小说模块：进入后全屏覆盖底部 TabBar（对齐 docs/05 3.2 流程即导航）。
    GoRoute(
      path: '/novel/:projectId',
      builder: (_, state) => NovelShelfPage(
        projectId: int.parse(state.pathParameters['projectId']!),
      ),
    ),
    GoRoute(
      path: '/novel/:projectId/chapter/:chapterId',
      builder: (_, state) => ChapterEditorPage(
        chapterId: int.parse(state.pathParameters['chapterId']!),
      ),
    ),
    GoRoute(
      path: '/novel/:projectId/settings',
      builder: (_, state) => SettingWorkshopPage(
        projectId: int.parse(state.pathParameters['projectId']!),
      ),
    ),
    GoRoute(
      path: '/novel/:projectId/outline',
      builder: (_, state) => OutlineEditorPage(
        projectId: int.parse(state.pathParameters['projectId']!),
      ),
    ),
    GoRoute(
      path: '/novel/:projectId/characters',
      builder: (_, state) => CharacterManagerPage(
        projectId: int.parse(state.pathParameters['projectId']!),
      ),
    ),
    // 剧本模块：小说改编为分场剧本（对齐 docs/05 4.4 流程即导航）。
    GoRoute(
      path: '/script/:projectId',
      builder: (_, state) =>
          ScriptPage(projectId: int.parse(state.pathParameters['projectId']!)),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId',
      builder: (_, state) => ScriptDetailPage(
        projectId: int.parse(state.pathParameters['projectId']!),
        scriptId: int.parse(state.pathParameters['scriptId']!),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/versions',
      builder: (_, state) => ScriptVersionsPage(
        projectId: int.parse(state.pathParameters['projectId']!),
        scriptId: int.parse(state.pathParameters['scriptId']!),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/scene/:sceneId',
      builder: (_, state) => SceneEditPage(
        projectId: int.parse(state.pathParameters['projectId']!),
        sceneId: int.parse(state.pathParameters['sceneId']!),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/skeleton',
      builder: (_, state) => SkeletonPage(
        projectId: int.parse(state.pathParameters['projectId']!),
        scriptId: int.parse(state.pathParameters['scriptId']!),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/assets',
      builder: (_, state) => AssetGalleryPage(
        projectId: int.parse(state.pathParameters['projectId']!),
        scriptId: int.parse(state.pathParameters['scriptId']!),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/asset/:assetId',
      builder: (_, state) => AssetDetailPage(
        projectId: int.parse(state.pathParameters['projectId']!),
        scriptId: int.parse(state.pathParameters['scriptId']!),
        assetId: int.parse(state.pathParameters['assetId']!),
      ),
    ),
    // 镜头模块：分镜图列表 + 详情（M5）。
    GoRoute(
      path: '/script/:projectId/script/:scriptId/shots',
      builder: (_, state) => ShotListPage(
        projectId: int.parse(state.pathParameters['projectId']!),
        scriptId: int.parse(state.pathParameters['scriptId']!),
      ),
    ),
    GoRoute(
      path: '/script/:projectId/script/:scriptId/shot/:shotId',
      builder: (_, state) => ShotDetailPage(
        projectId: int.parse(state.pathParameters['projectId']!),
        scriptId: int.parse(state.pathParameters['scriptId']!),
        shotId: int.parse(state.pathParameters['shotId']!),
      ),
    ),
  ],
);

/// 应用根 Widget：深色主题 + 底部导航壳。
class NewmoveApp extends StatelessWidget {
  const NewmoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF5B6CFF);
    return MaterialApp.router(
      title: '小说动漫工坊',
      debugShowCheckedModeBanner: false,
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
