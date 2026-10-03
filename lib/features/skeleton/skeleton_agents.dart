import 'dart:convert';

import '../../agent/active_llm.dart';
import '../../agent/skill_loader.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'skeleton_models.dart';

/// 剧本→骨架 Director Agent：节拍解析 + 分段 + 资产出镜状态。
class SkeletonAgents {
  SkeletonAgents({required this.adapter});

  final LlmProviderAdapter adapter;

  static const _beatParsing = 'skeleton/beat_parsing.md';
  static const _assetStates = 'skeleton/asset_states.md';

  Future<SkeletonResult> extract({
    required String prompt,
    required ActiveLlm llm,
  }) async {
    final beats = await SkillLoader.load(_beatParsing);
    final assets = await SkillLoader.load(_assetStates);
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
    return SkeletonResult.fromJson(_extractJson(reply));
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
