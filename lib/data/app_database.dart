import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/status_constants.dart';
import 'daos/asset_dao.dart';
import 'daos/asset_ref_dao.dart';
import 'daos/beat_dao.dart';
import 'daos/cascade_dao.dart';
import 'daos/generation_attempt_dao.dart';
import 'daos/revision_dao.dart';
import 'daos/chapter_revision_dao.dart';
import 'daos/novel_dao.dart';
import 'daos/project_dao.dart';
import 'daos/provider_dao.dart';
import 'daos/scene_dao.dart';
import 'daos/script_dao.dart';
import 'daos/script_revision_dao.dart';
import 'daos/shot_dao.dart';
import 'daos/shot_frame_dao.dart';
import 'daos/truth_file_dao.dart';
import 'daos/video_task_dao.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

/// 应用数据库：集中定义全部表与 DAO。
@DriftDatabase(
  tables: [
    Projects,
    NovelBooks,
    Chapters,
    ChapterRevisions,
    TruthFiles,
    Scripts,
    ScriptRevisions,
    Scenes,
    Beats,
    Assets,
    Shots,
    ShotFrames,
    AssetRefs,
    VideoTasks,
    ProviderConfigs,
    ShotRevisions,
    AssetRevisions,
    GenerationAttempts,
  ],
  daos: [
    ProjectDao,
    NovelDao,
    CascadeDao,
    ChapterRevisionDao,
    TruthFileDao,
    ScriptDao,
    SceneDao,
    ScriptRevisionDao,
    BeatDao,
    AssetDao,
    AssetRefDao,
    ShotDao,
    ShotFrameDao,
    VideoTaskDao,
    ProviderDao,
    RevisionDao,
    GenerationAttemptDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 供测试注入内存数据库。
  AppDatabase(super.e);

  /// 生产连接：应用私有目录下的 newmove.sqlite。
  AppDatabase.open() : super(driftDatabase(name: 'newmove'));

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // M2：场次补充对白与声音，新增剧本版本快照表。
        await m.addColumn(scenes, scenes.dialogue);
        await m.addColumn(scenes, scenes.sound);
        await m.createTable(scriptRevisions);
      }
      if (from < 3) {
        // M3：片段补充节拍引用与资产出镜状态。
        await m.addColumn(shots, shots.beatRefs);
        await m.addColumn(shots, shots.assetStates);
      }
      if (from < 4) {
        // M6：视频生成任务表（断点续跑）。
        await m.createTable(videoTasks);
      }
      if (from < 5) {
        // M7 追加轮：视频任务产物路径（媒体历史）、供应商说明。
        await m.addColumn(videoTasks, videoTasks.outputPath);
        await m.addColumn(providerConfigs, providerConfigs.readme);
      }
      if (from < 6) {
        // P3-15：小说书表新增 workType 字段（长篇/短篇/剧本/影游）。
        await m.addColumn(novelBooks, novelBooks.workType);
      }
      if (from < 7) {
        // M14：镜头 / 资产产物版本快照 + 生成尝试台账。
        await m.createTable(shotRevisions);
        await m.createTable(assetRevisions);
        await m.createTable(generationAttempts);
      }
      if (from < 8) {
        // M14 T16.9.4：清理剧本表上的死字段。aspectRatio 从未传入图片或视频
        // 生成（合成固定 1280x720），language 无读取方；两列均无外键引用，
        // 直接删除比保留默认值更不易误导。aspectRatio 支持需按供应商能力表
        // 映射 size 参数，另行规划。
        await m.dropColumn(scripts, 'aspect_ratio');
        await m.dropColumn(scripts, 'language');
      }
      if (from < 9) {
        // M16：一集 = 剧本表一行。集元数据不新增表，剧本行承载集序号、
        // 目标总时长与目标模型版本；单段时长上限仍由选中视频模型能力推导。
        await m.addColumn(scripts, scripts.episodeNo);
        await m.addColumn(scripts, scripts.targetDurationMs);
        await m.addColumn(scripts, scripts.modelVersion);
      }
      if (from < 10) {
        // M17 T19.5：作品级每章目标字数。此前定稿字数校验在 UI 里硬编码
        // 2000，与作品实际体感无关；改为作品行可配置，0 表示不设门槛。
        await m.addColumn(novelBooks, novelBooks.targetWords);
      }
    },
    beforeOpen: (details) async {
      // SQLite 默认关闭外键，这里显式开启以约束 1:N 引用。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
