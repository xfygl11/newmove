/// AI 写小说模块的领域模型（AI 产物，与 Drift 表模型分层）。
library;

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
      premise: json['premise'] as String? ?? '',
      world: json['world'] as String? ?? '',
      characters: [
        for (final c in (json['characters'] as List<dynamic>? ?? const []))
          CharacterSpec.fromJson(c as Map<String, dynamic>),
      ],
      styleGuide: json['styleGuide'] as String? ?? '',
      outline: json['outline'] as String? ?? '',
      proposals: [
        for (final p in (json['proposals'] as List<dynamic>? ?? const []))
          p.toString(),
      ],
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
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      state: json['state'] as String? ?? '',
      relations: json['relations'] as String? ?? '',
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
      type: ReviewIssueType.fromValue(json['type'] as String?),
      location: json['location'] as String? ?? '',
      problem: json['problem'] as String? ?? '',
      evidence: json['evidence'] as String? ?? '',
      impact: json['impact'] as String? ?? '',
      fix: json['fix'] as String? ?? '',
      scope: json['scope'] as String? ?? 'local',
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
    final factOps = json['factOps'] as Map<String, dynamic>? ?? const {};
    final hookOps = json['hookOps'] as Map<String, dynamic>? ?? const {};
    return SettleDelta(
      factUpsert: [
        for (final f in (factOps['upsert'] as List<dynamic>? ?? const []))
          (f as Map).cast<String, dynamic>(),
      ],
      factExpire: [
        for (final f in (factOps['expire'] as List<dynamic>? ?? const []))
          (f as Map).cast<String, dynamic>(),
      ],
      characters: [
        for (final c in (json['characterOps'] as List<dynamic>? ?? const []))
          CharacterSpec.fromJson((c as Map).cast<String, dynamic>()),
      ],
      resources: [
        for (final r in (json['resourceOps'] as List<dynamic>? ?? const []))
          (r as Map).cast<String, dynamic>(),
      ],
      hookUpsert: [
        for (final h in (hookOps['upsert'] as List<dynamic>? ?? const []))
          (h as Map).cast<String, dynamic>(),
      ],
      hookResolve: [
        for (final h in (hookOps['resolve'] as List<dynamic>? ?? const []))
          h.toString(),
      ],
      chapterSummary: json['chapterSummary'] is Map
          ? (json['chapterSummary'] as Map).cast<String, dynamic>()
          : null,
      authorIntent: json['authorIntent'] as String? ?? '',
      currentFocus: json['currentFocus'] as String? ?? '',
    );
  }
}
