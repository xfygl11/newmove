import 'dart:convert';

import '../../agent/active_llm.dart';
import '../../agent/skill_loader.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'novel_models.dart';

/// AI 写小说各阶段 Agent：组合 skill 提示词 + LLM 调用 + 结构化解析。
class NovelAgents {
  NovelAgents({required this.adapter});

  final LlmProviderAdapter adapter;

  static const _planning = 'novel/planning.md';
  static const _writing = 'novel/writing.md';
  static const _review = 'novel/review.md';
  static const _settling = 'novel/settling.md';

  // ---- 设定生成（Planner + Architect） ----

  Future<SetupResult> generateSetup({
    required String idea,
    required String genre,
    required ActiveLlm llm,
  }) async {
    final system = await SkillLoader.load(_planning);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: system),
        (
          role: ChatRole.user,
          content: '【创意】$idea\n【题材】$genre\n请按规则产出设定 JSON。',
        ),
      ],
      temperature: 0.7,
    );
    return SetupResult.fromJson(_extractJson(reply));
  }

  // ---- 章节写作（Writer，流式） ----

  Stream<String> writeChapter({
    required String prompt,
    required ActiveLlm llm,
  }) async* {
    final system = await SkillLoader.load(_writing);
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
  }) async {
    final system = await SkillLoader.load(_review);
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
    final map = _extractJson(reply);
    final issues = map['issues'] as List<dynamic>? ?? const [];
    return [
      for (final i in issues) ReviewIssue.fromJson((i as Map).cast<String, dynamic>()),
    ];
  }

  // ---- 修订（Writer spot-fix/polish/rewrite） ----

  Future<String> revise({
    required String prompt,
    required ActiveLlm llm,
  }) async {
    final system = await SkillLoader.load(_writing);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: '$system\n\n当前是修订任务：只输出修订后的完整正文，不输出解释。'),
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
  }) async {
    final system = await SkillLoader.load(_settling);
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
    return SettleDelta.fromJson(_extractJson(reply));
  }

  // ---- 内部辅助 ----

  /// 从 LLM 回复中提取 JSON 对象（容忍 markdown 代码块包裹）。
  Map<String, dynamic> _extractJson(String reply) {
    var text = reply.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final m = fence.firstMatch(text);
    if (m != null) text = m.group(1)!.trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      text = text.substring(start, end + 1);
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }
}
