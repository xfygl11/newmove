import 'dart:convert';

import '../../agent/active_llm.dart';
import '../../agent/skill_loader.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'script_models.dart';

/// 小说→剧本改编 Agent：组合原典正典 + 视听化改编 skill。
class ScriptAgents {
  ScriptAgents({required this.adapter});

  final LlmProviderAdapter adapter;

  static const _sourceAndScript = 'adaptation/source_and_script.md';
  static const _screenAdaptation = 'adaptation/screen_adaptation.md';

  Future<AdaptationResult> adapt({
    required String prompt,
    required ActiveLlm llm,
  }) async {
    final methodology = await SkillLoader.load(_sourceAndScript);
    final adaptation = await SkillLoader.load(_screenAdaptation);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: '$methodology\n\n$adaptation'),
        (role: ChatRole.user, content: prompt),
      ],
      temperature: 0.4,
    );
    return AdaptationResult.fromJson(_extractJson(reply));
  }

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
