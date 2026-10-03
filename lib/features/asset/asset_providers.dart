import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'asset_agents.dart';
import 'asset_service.dart';

final assetAgentsProvider = Provider<AssetAgents>(
  (ref) => AssetAgents(adapter: ref.watch(llmProviderAdapterProvider)),
);

final assetServiceProvider = Provider<AssetService>(
  (ref) => AssetService(
    assetDao: ref.watch(assetDaoProvider),
    beatDao: ref.watch(beatDaoProvider),
    shotDao: ref.watch(shotDaoProvider),
    agents: ref.watch(assetAgentsProvider),
    imageAdapter: ref.watch(imageProviderAdapterProvider),
    fileStore: ref.watch(assetFileStoreProvider),
  ),
);

/// 某剧本的资产列表（类型升序、id 升序）。
final assetsByScriptProvider = StreamProvider.family<List<Asset>, int>(
  (ref, scriptId) => ref.watch(assetDaoProvider).watchByScript(scriptId),
);

/// 单个资产实时监听。
final assetProvider = StreamProvider.family<Asset?, int>(
  (ref, assetId) => ref.watch(assetDaoProvider).watch(assetId),
);
