import '../../agent/active_llm.dart';
import '../../agent/skill_loader.dart';
import '../../core/json_values.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'shot_models.dart';

/// 剧本→分镜 ShotDirector Agent：分镜提示词 + 帧拆分 + 参考绑定。
class ShotAgents {
  ShotAgents({required this.adapter});

  final LlmProviderAdapter adapter;

  static const _storyboard = 'shot/storyboard.md';
  static const _continuity = 'shot/continuity.md';

  /// 生成分镜草案 JSON。
  Future<ShotDirectionResult> direct({
    required String prompt,
    required ActiveLlm llm,
  }) async {
    final storyboard = await SkillLoader.load(_storyboard);
    final continuity = await SkillLoader.load(_continuity);
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
