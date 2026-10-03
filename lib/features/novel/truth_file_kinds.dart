/// TruthFile 7 类 kind 标识与中文标签。
class TruthFileKind {
  TruthFileKind._();

  static const String worldFacts = 'world_facts';
  static const String characterMatrix = 'character_matrix';
  static const String resources = 'resources';
  static const String hooks = 'hooks';
  static const String chapterSummaries = 'chapter_summaries';
  static const String authorIntent = 'author_intent';
  static const String currentFocus = 'current_focus';

  static const List<String> all = [
    worldFacts,
    characterMatrix,
    resources,
    hooks,
    chapterSummaries,
    authorIntent,
    currentFocus,
  ];

  static String label(String kind) => switch (kind) {
    worldFacts => '世界事实',
    characterMatrix => '角色矩阵',
    resources => '资源与道具',
    hooks => '伏笔钩子',
    chapterSummaries => '章节摘要',
    authorIntent => '作者意图',
    currentFocus => '当前焦点',
    _ => kind,
  };
}
