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
@DriftAccessor(tables: [PromptOverrides])
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
  Future<int> upsert({
    required String scope,
    required String key,
    required String text,
    int? projectId,
  }) {
    final existing = find(scope, key, projectId: projectId);
    return existing.then((row) async {
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
}
