import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/prompt_resolver.dart';
import '../../data/app_database.dart';
import '../../data/daos/asset_dao.dart';
import '../../data/daos/asset_ref_dao.dart';
import '../../data/daos/beat_dao.dart';
import '../../data/daos/character_relation_dao.dart';
import '../../data/daos/cascade_dao.dart';
import '../../data/daos/chapter_revision_dao.dart';
import '../../data/daos/gate_log_dao.dart';
import '../../data/daos/novel_dao.dart';
import '../../data/daos/project_dao.dart';
import '../../data/daos/provider_dao.dart';
import '../../data/daos/prompt_override_dao.dart';
import '../../data/daos/revision_dao.dart';
import '../../data/daos/generation_attempt_dao.dart';
import '../../data/daos/scene_dao.dart';
import '../../data/daos/script_dao.dart';
import '../../data/daos/script_revision_dao.dart';
import '../../data/daos/shot_dao.dart';
import '../../data/daos/shot_frame_dao.dart';
import '../../data/daos/truth_file_dao.dart';
import '../../data/daos/video_task_dao.dart';
import 'asset_file_store.dart';
import 'backup_service.dart';
import 'secure_key_store.dart';
import 'shot_file_store.dart';
import 'video_file_store.dart';

/// 数据库单例（应用生命周期内复用）。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final projectDaoProvider = Provider<ProjectDao>(
  (ref) => ref.watch(databaseProvider).projectDao,
);

final cascadeDaoProvider = Provider<CascadeDao>(
  (ref) => ref.watch(databaseProvider).cascadeDao,
);

final providerDaoProvider = Provider<ProviderDao>(
  (ref) => ref.watch(databaseProvider).providerDao,
);

final novelDaoProvider = Provider<NovelDao>(
  (ref) => ref.watch(databaseProvider).novelDao,
);

final truthFileDaoProvider = Provider<TruthFileDao>(
  (ref) => ref.watch(databaseProvider).truthFileDao,
);

final chapterRevisionDaoProvider = Provider<ChapterRevisionDao>(
  (ref) => ref.watch(databaseProvider).chapterRevisionDao,
);

final scriptDaoProvider = Provider<ScriptDao>(
  (ref) => ref.watch(databaseProvider).scriptDao,
);

final sceneDaoProvider = Provider<SceneDao>(
  (ref) => ref.watch(databaseProvider).sceneDao,
);

final scriptRevisionDaoProvider = Provider<ScriptRevisionDao>(
  (ref) => ref.watch(databaseProvider).scriptRevisionDao,
);

final beatDaoProvider = Provider<BeatDao>(
  (ref) => ref.watch(databaseProvider).beatDao,
);

final assetDaoProvider = Provider<AssetDao>(
  (ref) => ref.watch(databaseProvider).assetDao,
);

final assetRefDaoProvider = Provider<AssetRefDao>(
  (ref) => ref.watch(databaseProvider).assetRefDao,
);

final shotDaoProvider = Provider<ShotDao>(
  (ref) => ref.watch(databaseProvider).shotDao,
);

final shotFrameDaoProvider = Provider<ShotFrameDao>(
  (ref) => ref.watch(databaseProvider).shotFrameDao,
);

final videoTaskDaoProvider = Provider<VideoTaskDao>(
  (ref) => ref.watch(databaseProvider).videoTaskDao,
);

final revisionDaoProvider = Provider<RevisionDao>(
  (ref) => ref.watch(databaseProvider).revisionDao,
);

final generationAttemptDaoProvider = Provider<GenerationAttemptDao>(
  (ref) => ref.watch(databaseProvider).generationAttemptDao,
);

/// 生成尝试与本地质量门校验的统一登记助手。
final attemptRecorderProvider = Provider<AttemptRecorder>(
  (ref) => AttemptRecorder(ref.watch(generationAttemptDaoProvider)),
);

final promptOverrideDaoProvider = Provider<PromptOverrideDao>(
  (ref) => ref.watch(databaseProvider).promptOverrideDao,
);

final promptResolverProvider = Provider<PromptResolver>(
  (ref) => PromptResolver(ref.watch(promptOverrideDaoProvider)),
);

final characterRelationDaoProvider = Provider<CharacterRelationDao>(
  (ref) => ref.watch(databaseProvider).characterRelationDao,
);

final gateLogDaoProvider = Provider<GateLogDao>(
  (ref) => ref.watch(databaseProvider).gateLogDao,
);

final secureKeyStoreProvider = Provider<SecureKeyStore>(
  (ref) => SecureKeyStore(),
);

final assetFileStoreProvider = Provider<AssetFileStore>(
  (ref) => AssetFileStore(),
);

final shotFileStoreProvider = Provider<ShotFileStore>((ref) => ShotFileStore());

final videoFileStoreProvider = Provider<VideoFileStore>(
  (ref) => VideoFileStore(),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(db: ref.watch(databaseProvider)),
);
