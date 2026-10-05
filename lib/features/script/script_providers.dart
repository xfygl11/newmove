import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'script_agents.dart';
import 'script_service.dart';

final scriptAgentsProvider = Provider<ScriptAgents>(
  (ref) => ScriptAgents(
    adapter: ref.watch(llmProviderAdapterProvider),
    resolver: ref.watch(promptResolverProvider),
  ),
);

final scriptServiceProvider = Provider<ScriptService>(
  (ref) => ScriptService(
    db: ref.watch(databaseProvider),
    scriptDao: ref.watch(scriptDaoProvider),
    sceneDao: ref.watch(sceneDaoProvider),
    revisionDao: ref.watch(scriptRevisionDaoProvider),
    novelDao: ref.watch(novelDaoProvider),
    truthDao: ref.watch(truthFileDaoProvider),
    cascadeDao: ref.watch(cascadeDaoProvider),
    agents: ref.watch(scriptAgentsProvider),
    assetDao: ref.watch(assetDaoProvider),
    shotDao: ref.watch(shotDaoProvider),
    attemptDao: ref.watch(generationAttemptDaoProvider),
  ),
);

/// 某本书的剧本列表（版本降序）。
final scriptsByBookProvider = StreamProvider.family<List<Script>, int>(
  (ref, bookId) => ref.watch(scriptDaoProvider).watchByBook(bookId),
);

/// 单个剧本实时监听。
final scriptProvider = StreamProvider.family<Script?, int>(
  (ref, scriptId) => ref.watch(scriptDaoProvider).watch(scriptId),
);

/// 某剧本的场次列表（序号升序）。
final scenesByScriptProvider = StreamProvider.family<List<Scene>, int>(
  (ref, scriptId) => ref.watch(sceneDaoProvider).watchByScript(scriptId),
);

/// 单个场次实时监听。
final sceneProvider = StreamProvider.family<Scene?, int>(
  (ref, sceneId) => ref.watch(sceneDaoProvider).watch(sceneId),
);

/// 剧本版本快照（版本降序）。
final scriptVersionsProvider = FutureProvider.family<List<ScriptRevision>, int>(
  (ref, scriptId) => ref.watch(scriptServiceProvider).listVersions(scriptId),
);
