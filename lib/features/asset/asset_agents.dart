import 'dart:convert';

import '../../agent/active_llm.dart';
import '../../agent/skill_loader.dart';
import '../../core/network/llm_provider_adapter.dart';
import 'asset_models.dart';

/// 骨架→资产清单 AssetDesigner Agent：去重合并、复用/新建/变体判定、Prompt 构造。
class AssetAgents {
  AssetAgents({required this.adapter});

  final LlmProviderAdapter adapter;

  static const _assetDesign = 'asset/asset_design.md';

  /// 从骨架上下文提取资产清单草案。
  Future<AssetExtractionResult> extract({
    required String skeletonContext,
    required ActiveLlm llm,
  }) async {
    final skill = await SkillLoader.load(_assetDesign);
    final reply = await adapter.chat(
      baseUrl: llm.baseUrl,
      apiKey: llm.apiKey,
      model: llm.modelId,
      messages: [
        (role: ChatRole.system, content: skill),
        (role: ChatRole.user, content: skeletonContext),
      ],
      temperature: 0.3,
    );
    return AssetExtractionResult.fromJson(_extractJson(reply));
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
