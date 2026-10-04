import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/protocols.dart';
import '../core/storage/providers.dart';
import '../data/app_database.dart';
import '../features/novel/context_budget.dart';
import '../features/provider_config/provider_models.dart';

/// 当前激活的 LLM 供应商配置（取第一个已配置且 Key/模型齐全的 llm 组）。
class ActiveLlm {
  const ActiveLlm({
    required this.provider,
    required this.apiKey,
    required this.model,
  });

  final ProviderConfig provider;
  final String apiKey;
  final ProviderModel model;

  String get baseUrl => provider.baseUrl;
  String get modelId => model.id;
  String get protocol => provider.protocol;

  /// 模型上下文窗口；未配置时取保守默认（对齐 `ContextBudget.defaultMaxTokens`）。
  int get contextTokens =>
      (model.contextWindow ?? ContextBudget.defaultMaxTokens).clamp(
        2048,
        1 << 20,
      );

  /// 可用输入预算 = 窗口 - 输出上限 - 安全余量。
  ///
  /// 供 `ContextBudget` 装配提示词前预占输出与系统提示词的余量。
  int get budgetTokens {
    final output = model.maxOutputTokens ?? ContextBudget.defaultHeadroom;
    return (contextTokens - output - ContextBudget.safety).clamp(
      2048,
      contextTokens,
    );
  }
}

final activeLlmProvider = FutureProvider<ActiveLlm?>((ref) async {
  final providers = await ref.watch(providerDaoProvider).listByGroup('llm');
  for (final p in providers) {
    // 协议不在支持列表内的配置直接跳过，不让 protocol 变成死字段。
    if (!Protocols.isSupported('llm', p.protocol)) continue;
    final key = await ref.watch(secureKeyStoreProvider).readKey(p.id);
    // 只使用勾选启用的模型（docs/02 §4.1.2）。
    final models = ProviderModelCodec.decode(p.models)
        .where((m) => m.enabled)
        .toList();
    if (key != null && key.isNotEmpty && models.isNotEmpty) {
      return ActiveLlm(provider: p, apiKey: key, model: models.first);
    }
  }
  return null;
});
