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

/// 角色分档闭集词表（M23 T24.1）。
///
/// 对齐 shuohao-skills `novel-outline` 的 G1a-G1c 分档约束：主角组只有 1 人，
/// 副角与工具人各有上限。不在词表内的值一律回落空串——写「未知」进库
/// 会让 UI 渲染出「分档：未知」这种没有信息的行。
abstract final class CharacterTiers {
  CharacterTiers._();

  static const lead = '主角';
  static const support = '副角';
  static const functional = '工具人';
  static const other = '其他';

  static const all = [lead, support, functional, other];

  /// 各档人数上限，超了由 `CharacterGate.tier_cap` 提示。
  static const caps = {lead: 1, support: 6, functional: 10};

  /// 未登记的分档视为未分档，参与 `tier_missing` 而不是 `tier_cap`。
  static bool isKnown(String? tier) => tier != null && all.contains(tier);
}

/// 角色设定。
///
/// 前五个字段是 M0 起的基础画像；后五个是 M23 T24.1 的画像补全，
/// 全部可选、默认空串，存量数据缺字段时不报错。
class CharacterSpec {
  const CharacterSpec({
    required this.name,
    required this.role,
    required this.goal,
    required this.state,
    required this.relations,
    this.tier = '',
    this.arc = '',
    this.evidenceQuotes = '',
    this.voiceDesign = '',
    this.performanceStyle = '',
  });

  final String name;
  final String role;
  final String goal;
  final String state;
  final String relations;

  /// 分档：主角 / 副角 / 工具人 / 其他（闭集，见 [CharacterTiers]）。
  final String tier;

  /// 人物弧光：起点 → 弧光 → 终点。
  final String arc;

  /// 原文逐字引文，多条用「；」分隔；供 `CharacterGate.evidence_unverified` 核对。
  final String evidenceQuotes;

  /// 音色设计提示词（音色 / 音高 / 语速 / 口音 / 情绪），TTS 输入，与图像提示词解耦。
  final String voiceDesign;

  /// 表演风格：动作习惯 / 反应节奏 / 情绪表达方式。
  final String performanceStyle;

  factory CharacterSpec.fromJson(Map<String, dynamic> json) {
    return CharacterSpec(
      name: jsonString(json['name']),
      role: jsonString(json['role']),
      goal: jsonString(json['goal']),
      state: jsonString(json['state']),
      relations: jsonString(json['relations']),
      tier: jsonString(json['tier']),
      arc: jsonString(json['arc']),
      evidenceQuotes: jsonString(json['evidenceQuotes']),
      voiceDesign: jsonString(json['voiceDesign']),
      performanceStyle: jsonString(json['performanceStyle']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'goal': goal,
    'state': state,
    'relations': relations,
    'tier': tier,
    'arc': arc,
    'evidenceQuotes': evidenceQuotes,
    'voiceDesign': voiceDesign,
    'performanceStyle': performanceStyle,
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
    this.code = '',
    this.quote = '',
    this.handling = '',
    this.quoteOffset,
    this.paragraphIndex,
  });

  final ReviewIssueType type;
  final String location;
  final String problem;
  final String evidence;
  final String impact;
  final String fix;
  final String scope;

  /// 稳定机器码（如 `OOC-03`），便于跨轮审校对齐同一条问题。
  final String code;

  /// 正文原样引用的连续文字（≤40 字），用于本地裁切证据；不直接采信 LLM 自报位置。
  final String quote;

  /// 建议处置：revise 定点修 / rewrite 重写 / accept 保留 / ignore 忽略。
  final String handling;

  /// 本地校验命中时的字符起始偏移；null 表示未验证。
  final int? quoteOffset;

  /// 本地校验命中时所在段落号（从 0 起）；null 表示未验证。
  final int? paragraphIndex;

  /// 引文是否在正文中命中（三级降级匹配）。供质量门复用同一套规则。
  static bool quoteInContent(String quote, String content) =>
      _locateQuote(content, quote) != null;

  bool get isStructural => scope == 'structural';

  /// 需要更大范围判断才能定位：UI 单独 Chip，且不允许走定点修订。
  bool get isUnknownScope => scope == 'unknown';

  /// 证据是否已由本地正文命中校验。
  bool get quoteVerified => quoteOffset != null;

  /// 建议处置标签，未知值原样返回。
  String get handlingLabel =>
      {
        'revise': '定点修',
        'rewrite': '重写',
        'accept': '保留',
        'ignore': '忽略',
      }[handling] ??
      (handling.isEmpty ? '未建议' : handling);

  ReviewIssue copyWith({int? quoteOffset, int? paragraphIndex}) => ReviewIssue(
    type: type,
    location: location,
    problem: problem,
    evidence: evidence,
    impact: impact,
    fix: fix,
    scope: scope,
    code: code,
    quote: quote,
    handling: handling,
    quoteOffset: quoteOffset ?? this.quoteOffset,
    paragraphIndex: paragraphIndex ?? this.paragraphIndex,
  );

  factory ReviewIssue.fromJson(Map<String, dynamic> json) {
    return ReviewIssue(
      type: ReviewIssueType.fromValue(jsonStringOrNull(json['type'])),
      location: jsonString(json['location']),
      problem: jsonString(json['problem']),
      evidence: jsonString(json['evidence']),
      impact: jsonString(json['impact']),
      fix: jsonString(json['fix']),
      scope: jsonString(json['scope'], 'local'),
      code: jsonString(json['code']),
      quote: jsonString(json['quote']),
      handling: jsonString(json['handling']),
    );
  }

  /// 用本地正文校验全部条目的证据引用。
  ///
  /// LLM 自报的 `location` 与 `evidence` 可能是伪造引用，因此以正文明文
  /// 为准重新裁切：命中则记录字符偏移与段落号，未命中保留原条目并标记
  /// 未验证——不删除、不阻塞其它问题的呈现。
  static List<ReviewIssue> verifyQuotes(
    List<ReviewIssue> issues,
    String content,
  ) {
    return [
      for (final issue in issues)
        _withQuoteLocation(issue, _locateQuote(content, issue.quote)),
    ];
  }

  static ReviewIssue _withQuoteLocation(
    ReviewIssue issue,
    ({int offset, int paragraph})? location,
  ) {
    if (location == null) return issue;
    return issue.copyWith(
      quoteOffset: location.offset,
      paragraphIndex: location.paragraph,
    );
  }
}

/// 在正文中定位证据引用，返回字符起始偏移与所在段落号；未命中返回 null。
///
/// 匹配分三级降级：原文精确匹配 → 忽略空白匹配（LLM 可能在引文中换行）→
/// 逐步缩短前缀（容忍 LLM 对引文末尾的改写）。任一级命中即返回。
({int offset, int paragraph})? _locateQuote(String content, String quote) {
  final q = quote.trim();
  if (q.length < 4) return null;

  final exact = content.indexOf(q);
  if (exact >= 0) {
    return (offset: exact, paragraph: _paragraphIndexAt(content, exact));
  }

  final collapsed = _collapseWhitespace(q);
  if (collapsed.length >= 4) {
    final offset = _indexOfIgnoringWhitespace(content, collapsed);
    if (offset >= 0) {
      return (offset: offset, paragraph: _paragraphIndexAt(content, offset));
    }
  }

  for (var length = q.length - 1; length >= 4; length--) {
    final offset = content.indexOf(q.substring(0, length));
    if (offset >= 0) {
      return (offset: offset, paragraph: _paragraphIndexAt(content, offset));
    }
  }
  return null;
}

/// 字符偏移所在的段落号（按换行切分，从 0 起）。
int _paragraphIndexAt(String content, int offset) {
  var index = 0;
  for (var i = 0; i < offset && i < content.length; i++) {
    if (content.codeUnitAt(i) == 10) index++;
  }
  return index;
}

String _collapseWhitespace(String input) =>
    input.replaceAll(RegExp(r'[\s\u3000]+'), '');

/// 忽略空白后查找，返回命中首字符在原文中的偏移；未命中返回 -1。
int _indexOfIgnoringWhitespace(String content, String needle) {
  final target = needle.length;
  var matched = 0;
  for (var i = 0; i < content.length; i++) {
    final c = content.codeUnitAt(i);
    if (c == 32 || c == 9 || c == 10 || c == 13 || c == 0x3000) continue;
    if (c == needle.codeUnitAt(matched)) {
      matched++;
      if (matched == target) return i - (target - 1);
    } else {
      matched = c == needle.codeUnitAt(0) ? 1 : 0;
    }
  }
  return -1;
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
    this.relationOps = const [],
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

  /// 本章确立或改变的角色关系，落 CharacterRelations 追加历史。
  final List<Map<String, dynamic>> relationOps;

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
      relationOps: [for (final r in jsonList(json['relationOps'])) jsonMap(r)],
      chapterSummary: json['chapterSummary'] is Map
          ? jsonMap(json['chapterSummary'])
          : null,
      authorIntent: jsonString(json['authorIntent']),
      currentFocus: jsonString(json['currentFocus']),
    );
  }
}
