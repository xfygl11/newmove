import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'image_provider_adapter.dart';
import 'llm_provider_adapter.dart';
import 'video_provider_adapter.dart';

/// LLM 适配器单例。
final llmProviderAdapterProvider = Provider<LlmProviderAdapter>(
  (ref) => LlmProviderAdapter(),
);

/// 图片适配器单例。
final imageProviderAdapterProvider = Provider<ImageProviderAdapter>(
  (ref) => ImageProviderAdapter(),
);

/// 视频适配器单例。
final videoProviderAdapterProvider = Provider<VideoProviderAdapter>(
  (ref) => VideoProviderAdapter(),
);
