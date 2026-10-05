import '../../agent/active_llm.dart';
import '../../agent/prompt_resolver.dart';
import '../../core/json_values.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'script_models.dart';

/// 小说→剧本改编 Agent：组合原典正典 + 视听化改编 skill。
class ScriptAgents {
  ScriptAgents({required this.adapter, required this.resolver});

  final LlmProviderAdapter adapter;
  final PromptResolver resolver;

  static const _sourceAndScript = 'adaptation/source_and_script.md';
  static const _screenAdaptation = 'adaptation/screen_adaptation.md';

  Future<AdaptationResult> adapt({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) async {
    final methodology =
        await resolver.resolveByBook(_sourceAndScript, bookId: bookId);
    final adaptation =
        await resolver.resolveByBook(_screenAdaptation, bookId: bookId);
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
    return AdaptationResult.fromJson(extractJsonObject(reply));
  }
}
