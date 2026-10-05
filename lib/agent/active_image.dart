import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/protocols.dart';
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

  /// 本次生成实际发送的 `size`。
  ///
  /// 供应商声明了可选尺寸时按其声明取第一项（例如 Agnes 声明 `1K/2K/3K/4K`，
  /// 若继续发 `1024x1024` 就落在它声明的取值域之外）；未声明时回落到
  /// OpenAI 标准值。
  String get imageSize {
    final sizes = model.imageSizes;
    if (sizes != null && sizes.isNotEmpty) return sizes.first;
    return '1024x1024';
  }
}

final activeImageProvider = FutureProvider<ActiveImage?>((ref) async {
  final providers = await ref.watch(providerDaoProvider).listByGroup('image');
  for (final p in providers) {
    // 协议不在支持列表内的配置直接跳过，不让 protocol 变成死字段。
    if (!Protocols.isSupported('image', p.protocol)) continue;
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
