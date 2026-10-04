import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/asset_dao.dart';
import 'daos/asset_ref_dao.dart';
import 'daos/beat_dao.dart';
import 'daos/cascade_dao.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 供测试注入内存数据库。
  AppDatabase(super.e);

  /// 生产连接：应用私有目录下的 newmove.sqlite。
  AppDatabase.open() : super(driftDatabase(name: 'newmove'));

  @override
  int get schemaVersion => 6;

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
    },
    beforeOpen: (details) async {
      // SQLite 默认关闭外键，这里显式开启以约束 1:N 引用。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
