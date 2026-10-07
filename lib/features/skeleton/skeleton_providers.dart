import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gate_issue.dart';
import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'skeleton_agents.dart';
import 'skeleton_service.dart';

final skeletonAgentsProvider = Provider<SkeletonAgents>(
  (ref) => SkeletonAgents(
    adapter: ref.watch(llmProviderAdapterProvider),
    resolver: ref.watch(promptResolverProvider),
  ),
);

final skeletonServiceProvider = Provider<SkeletonService>(
  (ref) => SkeletonService(
    db: ref.watch(databaseProvider),
    scriptDao: ref.watch(scriptDaoProvider),
    sceneDao: ref.watch(sceneDaoProvider),
    beatDao: ref.watch(beatDaoProvider),
    shotDao: ref.watch(shotDaoProvider),
    cascadeDao: ref.watch(cascadeDaoProvider),
    agents: ref.watch(skeletonAgentsProvider),
    revisionDao: ref.watch(revisionDaoProvider),
    attemptDao: ref.watch(generationAttemptDaoProvider),
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

/// 某剧本的源剧情账本 E## 认领覆盖体检结果。
final skeletonCoverageProvider =
    FutureProvider.family<List<GateIssue>, int>(
  (ref, scriptId) => ref.watch(skeletonServiceProvider).listCoverageIssues(scriptId),
);
