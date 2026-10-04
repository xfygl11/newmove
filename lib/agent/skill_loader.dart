import 'package:flutter/services.dart' show rootBundle;

/// 从 assets 加载内置 Skill（Markdown 提示词方法论）。
///
/// 技能是打进 APK 的只读资源，同一路径首次加载后缓存到 [_cache]，
/// 高频调用不再重复触发 `rootBundle` IO。
class SkillLoader {
  const SkillLoader._();

  static final Map<String, String> _cache = {};

  /// 技能内容是否在 [_cache] 中（供测试与自检）。
  static bool isCached(String relativePath) =>
      _cache.containsKey('assets/skills/$relativePath');

  static Future<String> load(String relativePath) async {
    final key = 'assets/skills/$relativePath';
    final cached = _cache[key];
    if (cached != null) return cached;
    final text = await rootBundle.loadString(key);
    _cache[key] = text;
    return text;
  }
}
