import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'llm_provider_adapter.dart';

/// LLM 适配器单例。
final llmProviderAdapterProvider = Provider<LlmProviderAdapter>(
  (ref) => LlmProviderAdapter(),
);
