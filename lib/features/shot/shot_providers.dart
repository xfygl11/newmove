import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'shot_agents.dart';
import 'shot_models.dart';
import 'shot_service.dart';

final shotAgentsProvider = Provider<ShotAgents>(
  (ref) => ShotAgents(adapter: ref.watch(llmProviderAdapterProvider)),
);

final shotServiceProvider = Provider<ShotService>(
  (ref) => ShotService(
    scriptDao: ref.watch(scriptDaoProvider),
    sceneDao: ref.watch(sceneDaoProvider),
    beatDao: ref.watch(beatDaoProvider),
    shotDao: ref.watch(shotDaoProvider),
    shotFrameDao: ref.watch(shotFrameDaoProvider),
    assetRefDao: ref.watch(assetRefDaoProvider),
    assetDao: ref.watch(assetDaoProvider),
    agents: ref.watch(shotAgentsProvider),
    imageAdapter: ref.watch(imageProviderAdapterProvider),
    fileStore: ref.watch(shotFileStoreProvider),
  ),
);

/// 某剧本的镜头列表（G 序号升序）。
final shotListByScriptProvider = StreamProvider.family<List<Shot>, int>(
  (ref, scriptId) => ref.watch(shotDaoProvider).watchByScript(scriptId),
);

/// 单个镜头实时监听。
final shotProvider = StreamProvider.family<Shot?, int>(
  (ref, shotId) => ref.watch(shotDaoProvider).watch(shotId),
);

/// 单个镜头的分帧列表。
final shotFramesProvider = StreamProvider.family<List<ShotFrame>, int>(
  (ref, shotId) => ref.watch(shotFrameDaoProvider).watchByShot(shotId),
);

/// 单个镜头的参考绑定列表。
final shotRefsProvider = StreamProvider.family<List<AssetRef>, int>(
  (ref, shotId) => ref.watch(assetRefDaoProvider).watchByShot(shotId),
);

/// 某剧本的 A7 段间衔接校验结果。
final shotTransitionIssuesProvider =
    FutureProvider.family<List<ShotTransitionIssue>, int>(
  (ref, scriptId) =>
      ref.watch(shotServiceProvider).listTransitionIssues(scriptId),
);
