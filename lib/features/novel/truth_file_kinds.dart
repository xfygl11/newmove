/// TruthFile 9 类 kind 标识与中文标签。
class TruthFileKind {
  TruthFileKind._();

  static const String worldFacts = 'world_facts';
  static const String characterMatrix = 'character_matrix';
  static const String resources = 'resources';
  static const String hooks = 'hooks';
  static const String chapterSummaries = 'chapter_summaries';
  static const String authorIntent = 'author_intent';
  static const String currentFocus = 'current_focus';
  static const String chapterPlan = 'chapter_plan';
  static const String readerKnowledge = 'reader_knowledge';
  static const String outlineStructure = 'outline_structure';

  static const List<String> all = [
    worldFacts,
    characterMatrix,
    resources,
    hooks,
    chapterSummaries,
    authorIntent,
    currentFocus,
    chapterPlan,
    readerKnowledge,
    outlineStructure,
  ];

  static String label(String kind) => switch (kind) {
    worldFacts => '世界事实',
    characterMatrix => '角色矩阵',
    resources => '资源与道具',
    hooks => '伏笔钩子',
    chapterSummaries => '章节摘要',
    authorIntent => '作者意图',
    currentFocus => '当前焦点',
    chapterPlan => '章节计划',
    readerKnowledge => '读者认知',
    outlineStructure => '大纲结构',
    _ => kind,
  };
}
