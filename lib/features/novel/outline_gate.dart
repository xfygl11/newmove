/// 大纲结构化的本地校验门（M29b T29.10）。
///
/// 纯函数、不写库、只提示不阻塞。校验码（新增前先登记 AGENTS.md）：
///
/// - `scene_cap`（warn）主场景数超上限。上限随集数动态：`4 + ⌈集数/10⌉`，
///   夹在 5–15（对齐 shuohao-skills `novel-outline` 第 4 道门）。集数由调用方
///   传入（小说章节数或剧本集数都支持），为 0 时无法算公式，整门跳过。
/// - `once_scene`（warn）一次性场景没有规避方案。只查「有出现清单且恰好一个
///   出现点」的场景——规避方案是复用哪个环境资产或换什么时段天气，由
///   `onceAvoidance` 字段承载，为空即报警。
/// - `prop_cap`（warn）叙事道具数超上限（8 件）。对齐 shuohao `novel-art`
///   边界「道具只收叙事道具，通常 3–8 件」，场景陈设归场景锚点、一次性手部
///   道具用镜头级提示词解决，故只数 `isNarrative == true` 的道具。
///
/// 三条门读的是 `outline_structure` TruthFile 的结构化场景/道具清单，不是
/// 大纲 Markdown 正文；清单为空时整门跳过，按「缺数据照常通过」处理。
library;

import '../../core/gate_issue.dart';
import 'novel_models.dart';

/// 大纲结构门。
class OutlineGate {
  OutlineGate._();

  /// 叙事道具数量上限（shuohao novel-art「通常 3–8 件」）。
  static const int maxNarrativeProps = 8;

  /// 四条门一起跑。[episodeCount] 是章节/集总数，为 0 时跳过场景上限门。
  static List<GateIssue> validate({
    required List<OutlineScene> scenes,
    required List<OutlineProp> props,
    int episodeCount = 0,
  }) {
    return [
      ...sceneCap(scenes, episodeCount),
      ...onceScene(scenes),
      ...propCap(props),
      ...crowdPlan(scenes),
      ...noDialogue(scenes),
      ...riskFlag(scenes),
    ];
  }

  /// 主场景数超上限。[episodeCount] 为 0 或场景清单为空时跳过。
  static List<GateIssue> sceneCap(List<OutlineScene> scenes, int episodeCount) {
    if (episodeCount <= 0 || scenes.isEmpty) return const [];
    final primary = scenes.where((s) => s.isPrimary).toList();
    final cap = maxScenes(episodeCount);
    if (primary.length <= cap) return const [];
    return [
      GateIssue(
        code: 'scene_cap',
        severity: GateSeverity.warn,
        locator: '-',
        message: '主场景 ${primary.length} 个，超过上限 $cap（$episodeCount 集）',
      ),
    ];
  }

  /// 场景上限公式：`4 + ⌈集数/10⌉`，夹在 5–15。
  static int maxScenes(int episodeCount) {
    final raw = 4 + (episodeCount + 9) ~/ 10;
    return raw.clamp(5, 15);
  }

  /// 一次性场景无规避方案。只查恰好一个出现点的场景。
  static List<GateIssue> onceScene(List<OutlineScene> scenes) {
    return [
      for (final s in scenes)
        if (s.occurrences.length == 1 && s.onceAvoidance.trim().isEmpty)
          GateIssue(
            code: 'once_scene',
            severity: GateSeverity.warn,
            locator: s.name.trim().isEmpty ? '（未命名场景）' : s.name.trim(),
            message: '只出现一次且无规避方案，建议复用环境资产或换时段天气',
          ),
    ];
  }

  /// 叙事道具数超上限。只数 `isNarrative == true` 的道具。
  static List<GateIssue> propCap(List<OutlineProp> props) {
    if (props.isEmpty) return const [];
    final narrative = props.where((p) => p.isNarrative).toList();
    if (narrative.length <= maxNarrativeProps) return const [];
    return [
      GateIssue(
        code: 'prop_cap',
        severity: GateSeverity.warn,
        locator: '-',
        message: '叙事道具 ${narrative.length} 件，超过上限 $maxNarrativeProps',
      ),
    ];
  }

  /// 三人以上同框场景必须标拆解方案（crowd-plan）。
  ///
  /// 场景梗概 description 中出现「三人以上」「多人」「一群人」等关键词时，
  /// 必须在 description 或 onceAvoidance 中标明「拆解」方案。
  static List<GateIssue> crowdPlan(List<OutlineScene> scenes) {
    const crowdKeywords = ['三人', '四人', '五人', '多人', '一群人', '一群'];
    const splitKeywords = ['拆解', '拆分', '分镜'];
    final issues = <GateIssue>[];
    for (final s in scenes) {
      final desc = s.description;
      if (desc.trim().isEmpty) continue;
      final hasCrowd = crowdKeywords.any((k) => desc.contains(k));
      if (!hasCrowd) continue;
      final hasSplit = splitKeywords.any((k) => desc.contains(k) || s.onceAvoidance.contains(k));
      if (!hasSplit) {
        issues.add(
          GateIssue(
            code: 'crowd_plan',
            severity: GateSeverity.warn,
            locator: s.name.trim().isEmpty ? '（未命名场景）' : s.name.trim(),
            message: '多人同框场景（含「${crowdKeywords.firstWhere((k) => desc.contains(k))}」）未标拆解方案',
          ),
        );
      }
    }
    return issues;
  }

  /// 场景梗概必须用叙述体，禁止直接写台词（no-dialogue）。
  ///
  /// description 中出现对话引号「」或英文引号 "" 时报警——台词应进剧本对话字段。
  static List<GateIssue> noDialogue(List<OutlineScene> scenes) {
    final issues = <GateIssue>[];
    for (final s in scenes) {
      final desc = s.description;
      if (desc.trim().isEmpty) continue;
      final hasQuotes = desc.contains('「') || desc.contains('」') || desc.contains('"') || desc.contains('"') || desc.contains('"');
      if (hasQuotes) {
        issues.add(
          GateIssue(
            code: 'no_dialogue',
            severity: GateSeverity.warn,
            locator: s.name.trim().isEmpty ? '（未命名场景）' : s.name.trim(),
            message: '场景梗概含台词引号，应改用叙述体描述',
          ),
        );
      }
    }
    return issues;
  }

  /// 风险关键词扫描：预览生成难点（risk-flag）。
  ///
  /// description 中出现高风险视觉元素（裸体、血腥、暴力、复杂特效等）时提示。
  static List<GateIssue> riskFlag(List<OutlineScene> scenes) {
    const riskKeywords = [
      '裸体', '裸露', '性爱', '亲密',
      '血腥', '死亡', '杀戮', '暴力',
      '爆炸', '火焰', '特效',
      '魔法', '变身', '飞行',
    ];
    final issues = <GateIssue>[];
    for (final s in scenes) {
      final desc = s.description;
      if (desc.trim().isEmpty) continue;
      final matched = riskKeywords.where((k) => desc.contains(k)).toList();
      if (matched.isNotEmpty) {
        issues.add(
          GateIssue(
            code: 'risk_flag',
            severity: GateSeverity.warn,
            locator: s.name.trim().isEmpty ? '（未命名场景）' : s.name.trim(),
            message: '含高风险视觉元素：${matched.join('、')}，AI 生成可能不稳定',
          ),
        );
      }
    }
    return issues;
  }
}
