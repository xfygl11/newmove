import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'prompt_override_dao.g.dart';

/// 提示词覆盖作用域常量。
abstract final class PromptOverrideScopes {
  /// 全局级：所有项目生效。
  static const global = 'global';

  /// 项目级：仅指定项目生效，优先级高于全局级。
  static const project = 'project';
}

/// 用户可编辑的提示词覆盖（M19 T21.11）。
///
/// 内置 skill 是打进 APK 的只读资源，用户改不了提示词。这张表提供
/// 项目级 > 全局级 > 代码默认 的三级覆盖。写入走 upsert：同一
/// (scope, projectId, slotKey) 只保留一条，重复保存覆盖旧值。
///
/// M23 T24.4 起，每次改动正文之前先把旧正文写进 PromptOverrideVersions，
/// 覆盖改坏了可以回退。
@DriftAccessor(
  tables: [
    PromptOverrides,
    PromptOverrideVersions,
    NovelBooks,
    Projects,
  ],
)
class PromptOverrideDao extends DatabaseAccessor<AppDatabase>
    with _$PromptOverrideDaoMixin {
  PromptOverrideDao(super.db);

  /// 作用域内的覆盖列表，按 key 升序。
  Future<List<PromptOverride>> list({
    String scope = PromptOverrideScopes.global,
    int? projectId,
  }) async {
    final query = select(promptOverrides)
      ..where((t) => t.scope.equals(scope));
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.slotKey)]);
    return query.get();
  }

  /// 全局级覆盖（所有项目的公共提示词）。
  Future<List<PromptOverride>> listGlobal() => list();

  /// 某项目的覆盖。
  Future<List<PromptOverride>> listForProject(int projectId) =>
      list(scope: PromptOverrideScopes.project, projectId: projectId);

  /// 取单个覆盖；不存在返回 null。
  Future<PromptOverride?> find(
    String scope,
    String key, {
    int? projectId,
  }) async {
    final query = select(promptOverrides)
      ..where((t) => t.scope.equals(scope) & t.slotKey.equals(key));
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    return query.getSingleOrNull();
  }

  /// 覆盖 upsert：同 (scope, projectId, slotKey) 只保留一条，重复保存覆盖旧值。
  ///
  /// 改动正文之前先把旧正文写进版本历史。新建覆盖不存版本（没有旧值），
  /// 文本与旧值相同时也不存（无变化不制造版本）。
  Future<int> upsert({
    required String scope,
    required String key,
    required String text,
    int? projectId,
  }) {
    return attachedDatabase.transaction(() async {
      final row = await find(scope, key, projectId: projectId);
      if (row == null) {
        return into(promptOverrides).insert(
          PromptOverridesCompanion.insert(
            scope: scope,
            slotKey: key,
            body: text,
            projectId: Value(projectId),
          ),
        );
      }
      if (row.body != text) {
        await into(promptOverrideVersions).insert(
          PromptOverrideVersionsCompanion.insert(
            scope: scope,
            slotKey: key,
            body: row.body,
            projectId: Value(projectId),
          ),
        );
      }
      await (update(promptOverrides)
            ..where((t) => t.id.equals(row.id)))
          .write(
            PromptOverridesCompanion(
              body: Value(text),
              updatedAt: Value(DateTime.now()),
            ),
          );
      return row.id;
    });
  }

  /// 某插槽的版本历史，最新在前。
  Future<List<PromptOverrideVersion>> listVersions(
    String scope,
    String key, {
    int? projectId,
  }) async {
    final query = select(promptOverrideVersions)
      ..where((t) => t.scope.equals(scope) & t.slotKey.equals(key));
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.id)]);
    return query.get();
  }

  /// 回退到某历史版本：把该版本的正文当作一次新的 upsert 写回。
  ///
  /// 回退本身又产生一条新版本（当前正文被存档），历史链不回溯删除——
  /// 回退到 v2 后想回到 v3，v3 仍在链上。
  Future<int> restoreVersion(int versionId) async {
    final version = await (select(promptOverrideVersions)
          ..where((t) => t.id.equals(versionId)))
        .getSingleOrNull();
    if (version == null) {
      throw ArgumentError('提示词版本不存在：$versionId');
    }
    return upsert(
      scope: version.scope,
      key: version.slotKey,
      text: version.body,
      projectId: version.projectId,
    );
  }

  /// 项目删除时一并清理其项目级的覆盖历史。
  Future<void> deleteVersionsByProject(int projectId) {
    return (delete(promptOverrideVersions)
          ..where((t) => t.projectId.equals(projectId)))
        .go();
  }

  /// 删除覆盖，恢复使用内置 skill 原文。
  Future<void> deleteRow(String scope, String key, {int? projectId}) {
    final query = delete(promptOverrides)
      ..where((t) => t.scope.equals(scope) & t.slotKey.equals(key));
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    return query.go();
  }

  /// 项目删除时清理其项目级覆盖。
  Future<void> deleteByProject(int projectId) {
    return (delete(promptOverrides)
          ..where(
            (t) =>
                t.scope.equals(PromptOverrideScopes.project) &
                t.projectId.equals(projectId),
          ))
        .go();
  }

  /// 作品所属项目 id（作品 → 项目）。作品不存在返回 null。
  ///
  /// 提示词覆盖的项目归属统一从作品表解析，调用点不自拼 bookId → projectId。
  Future<int?> projectOfBook(int bookId) async {
    final book =
        await (select(novelBooks)..where((t) => t.id.equals(bookId)))
            .getSingleOrNull();
    return book?.projectId;
  }

  /// 项目是否启用项目级提示词覆盖。
  ///
  /// `null`（存量项目，列新增前的数据）等价于启用——升级不能把用户已经
  /// 写好的项目级覆盖静默关掉。
  Future<bool> projectPromptsEnabled(int projectId) async {
    final project =
        await (select(projects)..where((t) => t.id.equals(projectId)))
            .getSingleOrNull();
    return project?.useProjectPrompts != 0;
  }

  /// 设置项目级提示词覆盖开关，写 0 或 1。
  Future<void> setProjectPromptsEnabled(int projectId, bool enabled) {
    return (update(projects)..where((t) => t.id.equals(projectId)))
        .write(ProjectsCompanion(useProjectPrompts: Value(enabled ? 1 : 0)));
  }
}
