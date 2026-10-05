import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'generation_attempt_dao.g.dart';

/// 生成尝试的对象类型常量，避免各调用点散落字符串。
abstract final class AttemptSubjects {
  static const novelPlan = 'novel_plan';
  static const novelWrite = 'novel_write';
  static const novelReview = 'novel_review';
  static const novelSettle = 'novel_settle';
  static const scriptAdapt = 'script_adapt';
  static const skeletonExtract = 'skeleton_extract';
  static const shotDirection = 'shot_direction';
  static const shotImage = 'shot_image';
  static const shotVideo = 'shot_video';
  static const assetExtract = 'asset_extract';
  static const assetImage = 'asset_image';
}

/// 台账状态常量。
abstract final class AttemptStatuses {
  static const pending = 'pending';
  static const running = 'running';
  static const succeeded = 'succeeded';
  static const failed = 'failed';
  static const cancelled = 'cancelled';
}

/// 生成尝试台账数据访问对象（M14 T16.5.4）。
///
/// 台账在调用前写入提示词、参数、引用与授权快照；调用结束后只回写
/// `status` / `resultPath` / `errorMessage` 三列，提示词与参数不被后续编辑覆盖。
@DriftAccessor(tables: [GenerationAttempts])
class GenerationAttemptDao extends DatabaseAccessor<AppDatabase>
    with _$GenerationAttemptDaoMixin {
  GenerationAttemptDao(super.db);

  /// 本次为 [subjectType] + [subjectId] 的第几次尝试。
  Future<int> nextAttemptNo(String subjectType, int? subjectId) async {
    if (subjectId == null) return 1;
    final rows =
        await (select(generationAttempts)..where(
              (t) =>
                  t.subjectType.equals(subjectType) &
                  t.subjectId.equals(subjectId),
            ))
            .get();
    return rows.length + 1;
  }

  Future<int> insert(GenerationAttemptsCompanion entry) {
    return into(generationAttempts).insert(entry);
  }

  /// 回写执行结果，不触碰提示词 / 参数 / 引用 / 授权列。
  Future<void> finishAttempt({
    required int id,
    required String status,
    String? resultPath,
    String? errorMessage,
    int? subjectId,
    String? subjectLabel,
    int? projectId,
  }) {
    final companion = GenerationAttemptsCompanion(
      status: Value(status),
      resultPath: Value(resultPath),
      errorMessage: Value(errorMessage),
      // 只更新明确传入的列：Value(null) 在更新语义下是显式置 NULL，
      // 会把 subjectId 等字段清成空值。
      subjectId: subjectId == null ? const Value.absent() : Value(subjectId),
      subjectLabel: subjectLabel == null
          ? const Value.absent()
          : Value(subjectLabel),
      projectId: projectId == null ? const Value.absent() : Value(projectId),
    );
    return (update(
      generationAttempts,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  Future<List<GenerationAttempt>> listBySubject(
    String subjectType,
    int subjectId,
  ) {
    return (select(generationAttempts)
          ..where(
            (t) =>
                t.subjectType.equals(subjectType) &
                t.subjectId.equals(subjectId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  /// 生成尝试台账列表（新在前）。台账查看页的数据源。
  ///
  /// [status] / [projectId] 为 null 表示不过滤；状态取值见 [AttemptStatuses]。
  /// 返回上限 [limit] 条，避免历史过长时一次性拉满内存。
  Future<List<GenerationAttempt>> list({
    String? status,
    int? projectId,
    int limit = 500,
  }) {
    final query = select(generationAttempts);
    if (status != null) {
      query.where((t) => t.status.equals(status));
    }
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.id)]);
    query.limit(limit);
    return query.get();
  }

  Future<void> deleteByProject(int projectId) {
    return (delete(
      generationAttempts,
    )..where((t) => t.projectId.equals(projectId))).go();
  }

  /// 批量按 (类型, id 集合) 删除，供级联删除路径在同一事务内调用。
  Future<void> deleteBySubjectIds(String subjectType, List<int> ids) {
    if (ids.isEmpty) return Future.value();
    return (delete(generationAttempts)..where(
          (t) => t.subjectType.equals(subjectType) & t.subjectId.isIn(ids),
        ))
        .go();
  }

  Future<void> deleteBySubject(String subjectType, int subjectId) {
    return (delete(generationAttempts)..where(
          (t) =>
              t.subjectType.equals(subjectType) & t.subjectId.equals(subjectId),
        ))
        .go();
  }
}

/// 生成尝试登记助手。
///
/// 台账在调用前写入、结束后只回写 [AttemptStatuses] 三列，
/// 提示词与参数不被后续编辑覆盖，供事后查证「当时用的是什么」。
/// 写入与回写失败一律静默，辅助能力不得阻塞生成主流程。
class AttemptRecorder {
  const AttemptRecorder(this.dao);

  final GenerationAttemptDao dao;

  /// 授权指纹：数量 / 提示词 / 模式 / 引用顺序的摘要，供临执行复核比对。
  static String fingerprint(
    String subjectType,
    int? subjectId, {
    required String prompt,
    List<Map<String, dynamic>> refs = const [],
    int grantLimit = 1,
  }) {
    final sb = StringBuffer('$subjectType|${subjectId ?? '-'}|$grantLimit|');
    sb.write(refs.map((r) => '${r['assetId']}:${r['role']}').join(','));
    sb.write('|');
    sb.write(prompt.length > 300 ? prompt.substring(0, 300) : prompt);
    return Object.hashAll(sb.toString().codeUnits).toRadixString(16);
  }

  /// 登记一次生成尝试，返回台账 id；失败返回 null。
  Future<int?> start({
    required String subjectType,
    int? subjectId,
    String? subjectLabel,
    required String prompt,
    required String params,
    List<Map<String, dynamic>> refs = const [],
    Map<String, dynamic> before = const {},
    int grantLimit = 1,
    int? projectId,
  }) async {
    try {
      return await dao.insert(
        GenerationAttemptsCompanion.insert(
          projectId: Value(projectId),
          subjectType: subjectType,
          subjectId: Value(subjectId),
          subjectLabel: subjectLabel == null
              ? const Value.absent()
              : Value(subjectLabel),
          prompt: prompt,
          params: Value(params),
          refs: Value(jsonEncode(refs)),
          before: Value(jsonEncode(before)),
          attemptNo: Value(
            subjectId == null
                ? 1
                : await dao.nextAttemptNo(subjectType, subjectId),
          ),
          grantLimit: Value(grantLimit),
          grantFingerprint: Value(
            fingerprint(
              subjectType,
              subjectId,
              prompt: prompt,
              refs: refs,
              grantLimit: grantLimit,
            ),
          ),
          status: const Value(AttemptStatuses.running),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// 回写尝试结果：只更新状态三列；生成后才确定的对象 id 可一并补齐。
  Future<void> finish({
    int? id,
    required String status,
    String? resultPath,
    String? error,
    int? subjectId,
    String? subjectLabel,
    int? projectId,
  }) async {
    if (id == null) return;
    try {
      await dao.finishAttempt(
        id: id,
        status: status,
        resultPath: resultPath,
        errorMessage: error,
        subjectId: subjectId,
        subjectLabel: subjectLabel,
        projectId: projectId,
      );
    } catch (_) {
      // 台账回写失败不影响主流程。
    }
  }
}
