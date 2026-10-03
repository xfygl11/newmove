import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';

/// 供应商列表（DB 实时监听）。
final providerConfigListProvider = StreamProvider<List<ProviderConfig>>(
  (ref) => ref.watch(providerDaoProvider).watchAll(),
);

/// 读取指定供应商的 API Key（来自安全存储）。
final providerApiKeyProvider = FutureProvider.family<String?, String>(
  (ref, providerId) async {
    return ref.watch(secureKeyStoreProvider).readKey(providerId);
  },
);
