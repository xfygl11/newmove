import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'video_task_dao.g.dart';

/// 视频生成任务数据访问对象（M6 断点续跑）。
@DriftAccessor(tables: [VideoTasks])
class VideoTaskDao extends DatabaseAccessor<AppDatabase>
    with _$VideoTaskDaoMixin {
  VideoTaskDao(super.db);

  /// 某镜头的任务列表（最新在前）。
  Future<List<VideoTask>> listByShot(int shotId) {
    return (select(videoTasks)
          ..where((t) => t.shotId.equals(shotId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  /// 某镜头的任务实时监听。
  Stream<List<VideoTask>> watchByShot(int shotId) {
    return (select(videoTasks)
          ..where((t) => t.shotId.equals(shotId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  /// 全部未完成任务（排队/生成中），任务中心与前台恢复轮询用。
  Stream<List<VideoTask>> watchActive() {
    return (select(videoTasks)
          ..where((t) => t.status.isIn(['排队', '生成中']))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  /// 一次性查询未完成任务（定时轮询用）。
  Future<List<VideoTask>> listActive() {
    return (select(videoTasks)
          ..where((t) => t.status.isIn(['排队', '生成中']))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  Future<VideoTask?> find(int id) {
    return (select(videoTasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insert(VideoTasksCompanion entry) {
    return into(videoTasks).insert(entry);
  }

  Future<int> updateById(int id, VideoTasksCompanion entry) {
    return (update(videoTasks)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> deleteById(int id) {
    return (delete(videoTasks)..where((t) => t.id.equals(id))).go();
  }
}
