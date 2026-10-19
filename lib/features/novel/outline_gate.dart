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

  /// 三条门一起跑。[episodeCount] 是章节/集总数，为 0 时跳过场景上限门。
  static List<GateIssue> validate({
    required List<OutlineScene> scenes,
    required List<OutlineProp> props,
    int episodeCount = 0,
  }) {
    return [
      ...sceneCap(scenes, episodeCount),
      ...onceScene(scenes),
      ...propCap(props),
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
}
