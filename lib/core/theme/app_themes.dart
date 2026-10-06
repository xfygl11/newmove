import 'package:flutter/material.dart';

/// 一款可切换的外观主题。
///
/// 只存「短名 + 一组关键色」，完整 `ThemeData` 由 [build] 按 Material 3
/// 规则现算，避免在每处 UI 里散落颜色字面量。新增主题只改本文件。
///
/// 全部为深色主题（本项目深色优先，见 docs/05 §9）。`onX` / 容器色由
/// 关键色与 `surface` 现算，保证对比度，不用手填两套值。
class AppTheme {
  const AppTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.seed,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
  });

  /// 稳定机器码，持久化到设置里，**改了等于换主题**。
  final String id;

  /// 中文短名，用于展示。
  final String name;

  /// 一句话风格描述。
  final String description;

  /// 种子色，兜底填充未被显式覆盖的 `ColorScheme` 角色。
  final Color seed;

  /// 主强调色（按钮、选中态）。
  final Color primary;

  /// 次强调色（霓虹点缀）。
  final Color secondary;

  /// 第三强调色。
  final Color tertiary;

  /// 页面底色（最深）。
  final Color surface;

  /// 卡片 / 面板底色。
  final Color surfaceContainer;

  /// 更高的面板 / 对话框底色。
  final Color surfaceContainerHigh;

  /// 底色上的正文前景色，供主题预览等直接取用。
  Color get onSurface => _on(surface);

  /// 生成 Material 3 深色 `ThemeData`。
  ThemeData build() {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    final primaryContainer = _tint(primary);
    final secondaryContainer = _tint(secondary);
    final scheme = base.copyWith(
      primary: primary,
      onPrimary: _on(primary),
      primaryContainer: primaryContainer,
      onPrimaryContainer: _on(primaryContainer),
      secondary: secondary,
      onSecondary: _on(secondary),
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: _on(secondaryContainer),
      tertiary: tertiary,
      onTertiary: _on(tertiary),
      surface: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHigh,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }

  /// 把强调色压暗后混进底色，作为容器色，保持深色面板基调。
  Color _tint(Color accent) =>
      Color.alphaBlend(accent.withValues(alpha: 0.24), surface);

  /// 依亮度选前景色，保证文字/图标可读。
  static Color _on(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

/// 主题词表：单一来源。新增主题只在此登记，设置页与主题构建自动获得。
class AppThemeCatalog {
  const AppThemeCatalog._();

  /// 默认主题 id（首次安装 / 未设置时使用）。
  static const String defaultId = 'neon_blue';

  static const List<AppTheme> all = <AppTheme>[
    AppTheme(
      id: 'neon_blue',
      name: '霓虹蓝',
      description: '深空蓝底 · 青蓝荧光，默认科技主题',
      seed: Color(0xFF2E6BFF),
      primary: Color(0xFF4DA3FF),
      secondary: Color(0xFF39E6FF),
      tertiary: Color(0xFF8B7BFF),
      surface: Color(0xFF070B18),
      surfaceContainer: Color(0xFF0E1530),
      surfaceContainerHigh: Color(0xFF16203F),
    ),
    AppTheme(
      id: 'cyber_purple',
      name: '赛博紫',
      description: '暗紫夜幕 · 霓虹粉紫，赛博朋克风',
      seed: Color(0xFF7C3AED),
      primary: Color(0xFFA66BFF),
      secondary: Color(0xFFFF4FD8),
      tertiary: Color(0xFF4DE1FF),
      surface: Color(0xFF0B0714),
      surfaceContainer: Color(0xFF170F2B),
      surfaceContainerHigh: Color(0xFF23163F),
    ),
    AppTheme(
      id: 'terminal_green',
      name: '终端绿',
      description: '近黑底色 · 荧光绿，极客终端风',
      seed: Color(0xFF00B36B),
      primary: Color(0xFF35E08D),
      secondary: Color(0xFF7CFFB2),
      tertiary: Color(0xFF00D4C8),
      surface: Color(0xFF04120B),
      surfaceContainer: Color(0xFF0A2118),
      surfaceContainerHigh: Color(0xFF123328),
    ),
    AppTheme(
      id: 'molten_amber',
      name: '熔金橙',
      description: '炭黑底色 · 熔岩琥珀，工业热浪风',
      seed: Color(0xFFFF8A00),
      primary: Color(0xFFFFA93B),
      secondary: Color(0xFFFF5E3A),
      tertiary: Color(0xFFFFD166),
      surface: Color(0xFF140C04),
      surfaceContainer: Color(0xFF241407),
      surfaceContainerHigh: Color(0xFF35200D),
    ),
    AppTheme(
      id: 'crimson_alert',
      name: '赤红警戒',
      description: '墨黑底色 · 猩红警示，军事作战风',
      seed: Color(0xFFE5484D),
      primary: Color(0xFFFF5C63),
      secondary: Color(0xFFFF8A4C),
      tertiary: Color(0xFFFF3D9A),
      surface: Color(0xFF140609),
      surfaceContainer: Color(0xFF260B10),
      surfaceContainerHigh: Color(0xFF381016),
    ),
    AppTheme(
      id: 'aurora',
      name: '极光',
      description: '冷青底色 · 蓝紫流光，极地极光风',
      seed: Color(0xFF00C2A8),
      primary: Color(0xFF2BE6C8),
      secondary: Color(0xFF6C8BFF),
      tertiary: Color(0xFFB15CFF),
      surface: Color(0xFF041215),
      surfaceContainer: Color(0xFF0A2328),
      surfaceContainerHigh: Color(0xFF10343B),
    ),
  ];

  /// 按 id 解析主题；未知 id 回落默认主题，不抛错（存量配置不白屏）。
  static AppTheme resolve(String? id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  /// 默认主题对象。
  static AppTheme get defaultTheme => all.first;

  /// id 是否已登记。
  static bool contains(String id) => all.any((t) => t.id == id);
}
