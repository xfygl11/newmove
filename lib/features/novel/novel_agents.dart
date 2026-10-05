import '../../agent/active_llm.dart';
import '../../agent/prompt_resolver.dart';
import '../../core/json_values.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'novel_models.dart';

/// AI 写小说各阶段 Agent：组合 skill 提示词 + LLM 调用 + 结构化解析。
class NovelAgents {
  NovelAgents({required this.adapter, required this.resolver});

  final LlmProviderAdapter adapter;
  final PromptResolver resolver;

  static const _planning = 'novel/planning.md';
  static const _chapterPlanning = 'novel/chapter_planning.md';
  static const _writing = 'novel/writing.md';
  static const _review = 'novel/review.md';
  static const _settling = 'novel/settling.md';

  // ---- 设定生成（Planner + Architect） ----

  Future<SetupResult> generateSetup({
    required String idea,
    required String genre,
    required ActiveLlm llm,
    required int bookId,
    String workType = '长篇',
  }) async {
    final system = await resolver.resolveByBook(_planning, bookId: bookId);
    final typeNote = workType != '长篇' ? '\n【作品类型】$workType' : '';
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: system),
        (
          role: ChatRole.user,
          content: '【创意】$idea\n【题材】$genre$typeNote\n请按规则产出设定 JSON。',
        ),
      ],
      temperature: 0.7,
    );
    return SetupResult.fromJson(extractJsonObject(reply));
  }

  // ---- 章节规划（Planner，P3-13） ----

  /// 为指定章节生成写作规划（目标/关键事件/结尾变化/伏笔操作）。
  Future<Map<String, dynamic>> planChapter({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) async {
    final system = await resolver.resolveByBook(_chapterPlanning, bookId: bookId);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: system),
        (role: ChatRole.user, content: prompt),
      ],
      temperature: 0.5,
    );
    return extractJsonObject(reply);
  }

  // ---- 章节写作（Writer，流式） ----

  Stream<String> writeChapter({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) async* {
    final system = await resolver.resolveByBook(_writing, bookId: bookId);
    yield* adapter.chatStream(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: system),
        (role: ChatRole.user, content: prompt),
      ],
      temperature: 0.8,
    );
  }

  // ---- 审校（Reviewer） ----

  Future<List<ReviewIssue>> review({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) async {
    final system = await resolver.resolveByBook(_review, bookId: bookId);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: system),
        (role: ChatRole.user, content: prompt),
      ],
      temperature: 0.3,
    );
    final map = extractJsonObject(reply);
    final issues = jsonList(map['issues']);
    return [for (final i in issues) ReviewIssue.fromJson(jsonMap(i))];
  }

  // ---- 修订（Writer spot-fix/polish/rewrite） ----

  Future<String> revise({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) async {
    final system = await resolver.resolveByBook(_writing, bookId: bookId);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (
          role: ChatRole.system,
          content: '$system\n\n当前是修订任务：只输出修订后的完整正文，不输出解释。',
        ),
        (role: ChatRole.user, content: prompt),
      ],
      temperature: 0.6,
    );
    return reply;
  }

  // ---- 状态固化（Settler） ----

  Future<SettleDelta> settle({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) async {
    final system = await resolver.resolveByBook(_settling, bookId: bookId);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: system),
        (role: ChatRole.user, content: prompt),
      ],
      temperature: 0.2,
    );
    return SettleDelta.fromJson(extractJsonObject(reply));
  }
}
