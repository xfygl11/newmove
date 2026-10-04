import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'shot_agents.dart';
import 'shot_compose_service.dart';
import 'shot_models.dart';
import 'shot_service.dart';

final shotAgentsProvider = Provider<ShotAgents>(
  (ref) => ShotAgents(adapter: ref.watch(llmProviderAdapterProvider)),
);

final shotServiceProvider = Provider<ShotService>((ref) {
  final service = ShotService(
    db: ref.watch(databaseProvider),
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
    videoAdapter: ref.watch(videoProviderAdapterProvider),
    videoFileStore: ref.watch(videoFileStoreProvider),
    videoTaskDao: ref.watch(videoTaskDaoProvider),
    providerDao: ref.watch(providerDaoProvider),
  );
  // 轮询恢复时从安全存储读 Key。
  final keyStore = ref.watch(secureKeyStoreProvider);
  service.readProviderKey = keyStore.readKey;
  return service;
});

/// 成片合成服务（M8：FFmpeg 拼接，借鉴 Toonflow）。
final shotComposeServiceProvider = Provider<ShotComposeService>(
  (ref) => ShotComposeService(appDatabase: ref.watch(databaseProvider)),
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

/// 某镜头的视频任务列表（最新在前）。
final videoTasksByShotProvider = StreamProvider.family<List<VideoTask>, int>(
  (ref, shotId) => ref.watch(videoTaskDaoProvider).watchByShot(shotId),
);

/// 全部进行中/待验收的镜头（任务中心用）。
///
/// 用 StreamProvider 持有 Stream 实例：在 build 里直接 `.watch()` 每次都会新建
/// Stream，StreamBuilder 会反复取消重订阅并闪烁。
final activeShotsProvider = StreamProvider<List<Shot>>(
  (ref) => ref.watch(shotDaoProvider).watchActive(),
);

/// 全部进行中的视频任务（任务中心用）。
final activeVideoTasksProvider = StreamProvider<List<VideoTask>>(
  (ref) => ref.watch(videoTaskDaoProvider).watchActive(),
);
