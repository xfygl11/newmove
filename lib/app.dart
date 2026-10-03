import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/project/project_page.dart';
import 'features/provider_config/provider_config_page.dart';
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
          routes: [
            GoRoute(path: '/', builder: (_, _) => const ProjectPage()),
          ],
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
