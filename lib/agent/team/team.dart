/// 团队 Agent 基类：将多个 Agent 组合为可复用的团队。
///
/// 借鉴 Toonflow `packages/teams/storyboardTeam/` 的 members/knowledge/skills 三件套，
/// 本项目简化为「成员列表 + 共享知识」，具体团队子类定义成员与协作方法。
abstract class AgentTeam {
  /// 团队成员名称列表，用于展示与日志。
  List<String> get members;

  /// 团队共享的领域知识（注入给所有成员的提示词上下文）。
  String get knowledge;
}
