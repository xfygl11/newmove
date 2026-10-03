import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/project_dao.dart';
import 'daos/provider_dao.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

/// 应用数据库：集中定义全部表与 DAO。
@DriftDatabase(
  tables: [
    Projects,
    NovelBooks,
    Chapters,
    TruthFiles,
    Scripts,
    Scenes,
    Beats,
    Assets,
    Shots,
    ShotFrames,
    AssetRefs,
    ProviderConfigs,
  ],
  daos: [ProjectDao, ProviderDao],
)
class AppDatabase extends _$AppDatabase {
  /// 供测试注入内存数据库。
  AppDatabase(super.e);

  /// 生产连接：应用私有目录下的 newmove.sqlite。
  AppDatabase.open() : super(driftDatabase(name: 'newmove'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      // SQLite 默认关闭外键，这里显式开启以约束 1:N 引用。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
