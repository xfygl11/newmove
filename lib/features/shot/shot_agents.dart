import '../../agent/active_llm.dart';
import '../../agent/prompt_resolver.dart';
import '../../core/json_values.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'shot_models.dart';

/// 剧本→分镜 ShotDirector Agent：分镜提示词 + 帧拆分 + 参考绑定。
class ShotAgents {
  ShotAgents({required this.adapter, required this.resolver});

  final LlmProviderAdapter adapter;
  final PromptResolver resolver;

  static const _storyboard = 'shot/storyboard.md';
  static const _continuity = 'shot/continuity.md';

  /// 生成分镜草案 JSON。
  Future<ShotDirectionResult> direct({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) async {
    final storyboard =
        await resolver.resolveByBook(_storyboard, bookId: bookId);
    final continuity =
        await resolver.resolveByBook(_continuity, bookId: bookId);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: '$storyboard\n\n$continuity'),
        (role: ChatRole.user, content: prompt),
      ],
      temperature: 0.3,
    );
    return ShotDirectionResult.fromJson(extractJsonObject(reply));
  }
}
