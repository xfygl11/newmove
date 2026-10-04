/// AI 写小说模块的领域模型（AI 产物，与 Drift 表模型分层）。
library;

import 'package:newmove/core/json_values.dart';

/// 设定生成结果（Planner + Architect 产出）。
class SetupResult {
  const SetupResult({
    required this.premise,
    required this.world,
    required this.characters,
    required this.styleGuide,
    required this.outline,
    required this.proposals,
  });

  final String premise;
  final String world;
  final List<CharacterSpec> characters;
  final String styleGuide;
  final String outline;
  final List<String> proposals;

  factory SetupResult.fromJson(Map<String, dynamic> json) {
    return SetupResult(
      premise: jsonString(json['premise']),
      world: jsonString(json['world']),
      characters: [
        for (final c in jsonList(json['characters']))
          CharacterSpec.fromJson(jsonMap(c)),
      ],
      styleGuide: jsonString(json['styleGuide']),
      outline: jsonString(json['outline']),
      proposals: [for (final p in jsonList(json['proposals'])) p.toString()],
    );
  }
}

/// 角色设定。
class CharacterSpec {
  const CharacterSpec({
    required this.name,
    required this.role,
    required this.goal,
    required this.state,
    required this.relations,
  });

  final String name;
  final String role;
  final String goal;
  final String state;
  final String relations;

  factory CharacterSpec.fromJson(Map<String, dynamic> json) {
    return CharacterSpec(
      name: jsonString(json['name']),
      role: jsonString(json['role']),
      goal: jsonString(json['goal']),
      state: jsonString(json['state']),
      relations: jsonString(json['relations']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'goal': goal,
    'state': state,
    'relations': relations,
  };
}

/// 审校问题类型。
enum ReviewIssueType {
  ooc,
  timeline,
  hook,
  resource,
  style,
  conflict;

  static ReviewIssueType fromValue(String? value) {
    return ReviewIssueType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ReviewIssueType.ooc,
    );
  }

  String get label => switch (this) {
    ReviewIssueType.ooc => 'OOC',
    ReviewIssueType.timeline => '时间线',
    ReviewIssueType.hook => '伏笔',
    ReviewIssueType.resource => '道具',
    ReviewIssueType.style => '文风',
    ReviewIssueType.conflict => '设定冲突',
  };
}

/// 审校问题（Reviewer 产出）。
class ReviewIssue {
  const ReviewIssue({
    required this.type,
    required this.location,
    required this.problem,
    required this.evidence,
    required this.impact,
    required this.fix,
    required this.scope,
  });

  final ReviewIssueType type;
  final String location;
  final String problem;
  final String evidence;
  final String impact;
  final String fix;
  final String scope;

  bool get isStructural => scope == 'structural';

  factory ReviewIssue.fromJson(Map<String, dynamic> json) {
    return ReviewIssue(
      type: ReviewIssueType.fromValue(jsonStringOrNull(json['type'])),
      location: jsonString(json['location']),
      problem: jsonString(json['problem']),
      evidence: jsonString(json['evidence']),
      impact: jsonString(json['impact']),
      fix: jsonString(json['fix']),
      scope: jsonString(json['scope'], 'local'),
    );
  }
}

/// 修订模式。
enum RevisionMode {
  spotFix('定点修'),
  polish('润色'),
  rewrite('重写');

  const RevisionMode(this.label);

  final String label;
}

/// 固化 delta（Settler 产出）。
class SettleDelta {
  const SettleDelta({
    required this.factUpsert,
    required this.factExpire,
    required this.characters,
    required this.resources,
    required this.hookUpsert,
    required this.hookResolve,
    required this.chapterSummary,
    required this.authorIntent,
    required this.currentFocus,
  });

  final List<Map<String, dynamic>> factUpsert;
  final List<Map<String, dynamic>> factExpire;
  final List<CharacterSpec> characters;
  final List<Map<String, dynamic>> resources;
  final List<Map<String, dynamic>> hookUpsert;
  final List<String> hookResolve;
  final Map<String, dynamic>? chapterSummary;
  final String authorIntent;
  final String currentFocus;

  factory SettleDelta.fromJson(Map<String, dynamic> json) {
    final factOps = jsonMap(json['factOps']);
    final hookOps = jsonMap(json['hookOps']);
    return SettleDelta(
      factUpsert: [for (final f in jsonList(factOps['upsert'])) jsonMap(f)],
      factExpire: [for (final f in jsonList(factOps['expire'])) jsonMap(f)],
      characters: [
        for (final c in jsonList(json['characterOps']))
          CharacterSpec.fromJson(jsonMap(c)),
      ],
      resources: [for (final r in jsonList(json['resourceOps'])) jsonMap(r)],
      hookUpsert: [for (final h in jsonList(hookOps['upsert'])) jsonMap(h)],
      hookResolve: [for (final h in jsonList(hookOps['resolve'])) h.toString()],
      chapterSummary: json['chapterSummary'] is Map
          ? jsonMap(json['chapterSummary'])
          : null,
      authorIntent: jsonString(json['authorIntent']),
      currentFocus: jsonString(json['currentFocus']),
    );
  }
}
