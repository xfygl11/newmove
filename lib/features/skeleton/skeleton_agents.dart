import '../../agent/active_llm.dart';
import '../../agent/prompt_resolver.dart';
import '../../core/json_values.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'skeleton_models.dart';

/// 剧本→骨架 Director Agent：节拍解析 + 分段 + 资产出镜状态。
class SkeletonAgents {
  SkeletonAgents({required this.adapter, required this.resolver});

  final LlmProviderAdapter adapter;
  final PromptResolver resolver;

  static const _beatParsing = 'skeleton/beat_parsing.md';
  static const _assetStates = 'skeleton/asset_states.md';

  Future<SkeletonResult> extract({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) async {
    final beats = await resolver.resolveByBook(_beatParsing, bookId: bookId);
    final assets = await resolver.resolveByBook(_assetStates, bookId: bookId);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: '$beats\n\n$assets'),
        (role: ChatRole.user, content: prompt),
      ],
      temperature: 0.3,
    );
    return SkeletonResult.fromJson(extractJsonObject(reply));
  }
}
