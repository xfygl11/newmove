import '../../features/novel/novel_agents.dart';
import '../../features/novel/novel_models.dart';
import '../../features/shot/shot_agents.dart';
import '../../features/shot/shot_models.dart';
import '../../features/script/script_agents.dart';
import '../../features/script/script_models.dart';
import '../active_llm.dart';
import 'team.dart';

/// 分镜团队：导演（ShotDirector）+ 写手（ScriptWriter）+ 审校（ScriptReviewer）。
///
/// 借鉴 Toonflow `packages/teams/storyboardTeam/members/` 的三成员组合，
/// 提供「剧本改编 → 分镜导演 → 质量审校」的完整流水线。
class StoryboardTeam extends AgentTeam {
  StoryboardTeam({
    required this._director,
    required this._writer,
    required this._reviewer,
  });

  final ShotAgents _director;
  final ScriptAgents _writer;
  final NovelAgents _reviewer;

  @override
  List<String> get members => const ['director', 'writer', 'reviewer'];

  @override
  String get knowledge =>
      '剧本改编、分镜导演、质量审校的协作流水线。'
      '导演负责将剧本拆解为分镜段落与帧，写手负责剧本创作与改写，'
      '审校负责检查分镜连贯性与质量。';

  /// 导演：生成分镜草案。
  Future<ShotDirectionResult> direct({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) {
    return _director.direct(
      prompt: prompt,
      llm: llm,
      bookId: bookId,
    );
  }

  /// 写手：改编章节为剧本。
  Future<AdaptationResult> adapt({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) {
    return _writer.adapt(
      prompt: prompt,
      llm: llm,
      bookId: bookId,
    );
  }

  /// 审校：检查剧本/分镜质量。
  Future<List<ReviewIssue>> review({
    required String prompt,
    required ActiveLlm llm,
    required int bookId,
  }) {
    return _reviewer.review(
      prompt: prompt,
      llm: llm,
      bookId: bookId,
    );
  }
}
