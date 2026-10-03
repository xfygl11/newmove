import 'package:flutter/services.dart' show rootBundle;

/// 从 assets 加载内置 Skill（Markdown 提示词方法论）。
class SkillLoader {
  const SkillLoader._();

  static Future<String> load(String relativePath) {
    return rootBundle.loadString('assets/skills/$relativePath');
  }
}
