import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'asset_agents.dart';
import 'asset_service.dart';

final assetAgentsProvider = Provider<AssetAgents>(
  (ref) => AssetAgents(
    adapter: ref.watch(llmProviderAdapterProvider),
    resolver: ref.watch(promptResolverProvider),
  ),
);

final assetServiceProvider = Provider<AssetService>(
  (ref) => AssetService(
    assetDao: ref.watch(assetDaoProvider),
    beatDao: ref.watch(beatDaoProvider),
    shotDao: ref.watch(shotDaoProvider),
    scriptDao: ref.watch(scriptDaoProvider),
    agents: ref.watch(assetAgentsProvider),
    imageAdapter: ref.watch(imageProviderAdapterProvider),
    fileStore: ref.watch(assetFileStoreProvider),
    revisionDao: ref.watch(revisionDaoProvider),
    attemptDao: ref.watch(generationAttemptDaoProvider),
  ),
);

/// 全部进行中/待验收的资产（任务中心用）。
///
/// 用 StreamProvider 持有 Stream 实例：在 build 里直接 `.watch()` 每次都会新建
/// Stream，StreamBuilder 会反复取消重订阅并闪烁。
final activeAssetsProvider = StreamProvider<List<Asset>>(
  (ref) => ref.watch(assetDaoProvider).watchActive(),
);

/// 某剧本的资产列表（类型升序、id 升序）。
final assetsByScriptProvider = StreamProvider.family<List<Asset>, int>(
  (ref, scriptId) => ref.watch(assetDaoProvider).watchByScript(scriptId),
);

/// 单个资产的产物版本快照（最新在前）。
final assetRevisionsProvider = FutureProvider.family<List<AssetRevision>, int>(
  (ref, assetId) => ref.watch(revisionDaoProvider).listAssets(assetId),
);

/// 单个资产实时监听。
final assetProvider = StreamProvider.family<Asset?, int>(
  (ref, assetId) => ref.watch(assetDaoProvider).watch(assetId),
);
