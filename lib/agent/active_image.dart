import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/providers.dart';
import '../data/app_database.dart';
import '../features/provider_config/provider_models.dart';

/// 当前激活的图片供应商配置（取第一个已配置且 Key/模型齐全的 image 组）。
class ActiveImage {
  const ActiveImage({
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
}

final activeImageProvider = FutureProvider<ActiveImage?>((ref) async {
  final providers = await ref.watch(providerDaoProvider).listByGroup('image');
  for (final p in providers) {
    final key = await ref.watch(secureKeyStoreProvider).readKey(p.id);
    // 只使用勾选启用的模型（docs/02 §4.1.2）。
    final models = ProviderModelCodec.decode(p.models)
        .where((m) => m.enabled)
        .toList();
    if (key != null && key.isNotEmpty && models.isNotEmpty) {
      return ActiveImage(provider: p, apiKey: key, model: models.first);
    }
  }
  return null;
});
