import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'skeleton_agents.dart';
import 'skeleton_models.dart';
import 'skeleton_service.dart';

final skeletonAgentsProvider = Provider<SkeletonAgents>(
  (ref) => SkeletonAgents(adapter: ref.watch(llmProviderAdapterProvider)),
);

final skeletonServiceProvider = Provider<SkeletonService>(
  (ref) => SkeletonService(
    scriptDao: ref.watch(scriptDaoProvider),
    sceneDao: ref.watch(sceneDaoProvider),
    beatDao: ref.watch(beatDaoProvider),
    shotDao: ref.watch(shotDaoProvider),
    agents: ref.watch(skeletonAgentsProvider),
  ),
);

/// 某剧本的节拍列表（全局序号升序）。
final beatsByScriptProvider = StreamProvider.family<List<Beat>, int>(
  (ref, scriptId) => ref.watch(beatDaoProvider).watchByScript(scriptId),
);

/// 某剧本的分段列表（G 序号升序）。
final shotsByScriptProvider = StreamProvider.family<List<Shot>, int>(
  (ref, scriptId) => ref.watch(shotDaoProvider).watchByScript(scriptId),
);

/// 某剧本的源剧情账本 E## 映射校验结果。
final skeletonIssuesProvider = FutureProvider.family<List<SkeletonIssue>, int>(
  (ref, scriptId) => ref.watch(skeletonServiceProvider).listIssues(scriptId),
);
