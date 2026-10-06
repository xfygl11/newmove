/// 角色画像的本地校验门（M23 T24.1/T24.2）。
///
/// 纯函数、不写库、只提示不阻塞。校验码（新增前先登记 AGENTS.md）：
///
/// - `tier_missing`（warn）角色未标分档——分档是写作前的规模约束，没有它
///   就无法判断主角组是否超员。存量角色升级后缺字段，按未分档提示一次，
///   不报错。
/// - `tier_cap`（warn）分档人数超上限：主角 >1 / 副角 >6 / 工具人 >10。
///   对齐 shuohao-skills `novel-outline` 的 G1a-G1c，超了只提示，
///   删角色不是本地校验该做的事。
/// - `evidence_unverified`（warn）角色引文未在章节正文命中，无法定位证据。
///   匹配复用 `ReviewIssue.verifyQuotes` 的三级降级（原文精确 → 忽略空白 →
///   前缀降级），不采信 LLM 自报位置；未命中的条目保留并提示，不删除。
library;

import '../../core/gate_issue.dart';
import 'novel_models.dart';

/// 角色画像门。
class CharacterGate {
  CharacterGate._();

  /// 三条门一起跑。[content] 是待核对引文的章节正文；为空时跳过引文门。
  static List<GateIssue> validate({
    required List<CharacterSpec> characters,
    String content = '',
  }) {
    return [
      ...tierMissing(characters),
      ...tierCap(characters),
      ...evidenceUnverified(characters, content),
    ];
  }

  /// 未标分档的角色。
  static List<GateIssue> tierMissing(List<CharacterSpec> characters) {
    return [
      for (final c in characters)
        if (!CharacterTiers.isKnown(c.tier))
          GateIssue(
            code: 'tier_missing',
            severity: GateSeverity.warn,
            locator: _locatorOf(c),
            message: '未标分档，无法校验主角组规模',
          ),
    ];
  }

  /// 分档人数超上限。未知分档不计入，由 `tier_missing` 单独提示。
  static List<GateIssue> tierCap(List<CharacterSpec> characters) {
    final counts = <String, int>{};
    for (final c in characters) {
      final tier = c.tier;
      if (!CharacterTiers.isKnown(tier)) continue;
      counts[tier] = (counts[tier] ?? 0) + 1;
    }

    return [
      for (final cap in CharacterTiers.caps.entries)
        if ((counts[cap.key] ?? 0) > cap.value)
          GateIssue(
            code: 'tier_cap',
            severity: GateSeverity.warn,
            locator: cap.key,
            message:
                '「${cap.key}」${counts[cap.key]} 人，超过上限 ${cap.value} 人',
          ),
    ];
  }

  /// 引文未在正文命中。[content] 去空白后为空时整门跳过——没有正文可核对，
  /// 按「缺数据照常通过」处理，不给刚写完第一章的用户刷一批假告警。
  static List<GateIssue> evidenceUnverified(
    List<CharacterSpec> characters,
    String content,
  ) {
    if (content.trim().isEmpty) return const [];

    final issues = <GateIssue>[];
    for (final c in characters) {
      for (final quote in quotesOf(c)) {
        if (!ReviewIssue.quoteInContent(quote, content)) {
          issues.add(
            GateIssue(
              code: 'evidence_unverified',
              severity: GateSeverity.warn,
              locator: _locatorOf(c),
              message: '引文未在正文命中：${_truncate(quote, 30)}',
            ),
          );
        }
      }
    }
    return issues;
  }

  /// 解析角色的引文清单，多条用「；」或 `;` 分隔。
  static List<String> quotesOf(CharacterSpec c) {
    return [
      for (final part in c.evidenceQuotes.split(RegExp(r'[；;]')))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static String _locatorOf(CharacterSpec c) =>
      c.name.trim().isEmpty ? '（未命名角色）' : c.name.trim();

  static String _truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…';
}
