import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'agent_binding_dao.g.dart';

/// 项目 × Agent 绑定 DAO（M34）。
///
/// 支持「项目 X 用 Agent A 出图 + Agent B 出视频」——
/// `projectId + category` 唯一，按 projectId 覆盖全局 ActiveX。
@DriftAccessor(tables: [AgentBindings])
class AgentBindingDao extends DatabaseAccessor<AppDatabase>
    with _$AgentBindingDaoMixin {
  AgentBindingDao(super.db);

  /// 某项目的全部绑定。
  Future<List<AgentBinding>> listByProject(int projectId) {
    return (select(agentBindings)..where((t) => t.projectId.equals(projectId)))
        .get();
  }

  /// 某项目某类别的绑定；不存在返回 null。
  Future<AgentBinding?> findByProjectAndCategory(
    int projectId,
    String category,
  ) {
    return (select(agentBindings)
          ..where((t) => t.projectId.equals(projectId) & t.category.equals(category)))
        .getSingleOrNull();
  }

  /// 创建绑定。
  Future<int> insertBinding({
    required int projectId,
    required String category,
    required String agentId,
  }) {
    return into(agentBindings).insert(
      AgentBindingsCompanion.insert(
        projectId: projectId,
        category: category,
        agentId: agentId,
      ),
    );
  }

  /// 更新绑定的 agentId。
  Future<void> updateBinding(int id, String agentId) {
    return (update(agentBindings)..where((t) => t.id.equals(id))).write(
      AgentBindingsCompanion(agentId: Value(agentId)),
    );
  }

  /// 删除绑定。
  Future<void> deleteBinding(int id) {
    return (delete(agentBindings)..where((t) => t.id.equals(id))).go();
  }

  /// 删除项目的所有绑定。
  Future<void> deleteByProject(int projectId) {
    return (delete(agentBindings)..where((t) => t.projectId.equals(projectId)))
        .go();
  }
}
