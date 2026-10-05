/// 章节维护提醒（M19 T21.15）。
///
/// 纯函数、不写库、只提示不阻塞。AI 一次写出较长正文时，人物状态、场景状态、
/// 伏笔进展、道具状态这四类「真相文件」内容都可能被静默改动——定稿前必须有人
/// 核对一遍，App 无法自动判断改动是否符合用户意图。
library;

import '../asset/prompt_gate.dart';

/// 触发阈值：AI 生成正文超过 500 字才弹维护清单。
/// 短章节的状态改动量有限，核对成本高收益低。
const int maintainWordThreshold = 500;

/// 四项目维护清单，顺序固定（与 TruthFile 四类状态对应）。
const List<String> maintainChecklist = [
  '角色状态',
  '场景状态',
  '伏笔进展',
  '道具状态',
];

/// 相似度低于该阈值时追加「建议全量重写」提示（0-1，1 表示完全相同）。
/// 依据：`PromptGate.jaccard` 的词元集合同尺度上，续写内容与既有正文
/// 完全无关时接近 0，正常延续在 0.3 以上。
const double maintainRewriteSimilarity = 0.35;

/// 章节维护提醒结果。
class ChapterMaintainIssue {
  const ChapterMaintainIssue({
    required this.wordCount,
    required this.rewriteSuggested,
  });

  /// 触发时的正文字数。
  final int wordCount;

  /// 是否需要追加「建议全量重写」提示。
  final bool rewriteSuggested;
}

/// 章节维护提醒的唯一判定入口。
abstract final class ChapterMaintainGate {
  ChapterMaintainGate._();

  /// [wordCount] 当前正文字数；[aiGenerated] 是否由 AI 生成；
  /// [similarity] 续写场景下新写内容与既有正文的相似度，无既有内容时传 null。
  ///
  /// 非 AI 生成或字数未过阈值时返回 null（不提示）；相似度缺失时只做清单提示，
  /// 跳过重写建议——没有基线文本时判定不了是否跑偏。
  static ChapterMaintainIssue? issue({
    required int wordCount,
    required bool aiGenerated,
    double? similarity,
  }) {
    if (!aiGenerated || wordCount <= maintainWordThreshold) return null;
    return ChapterMaintainIssue(
      wordCount: wordCount,
      rewriteSuggested:
          similarity != null && similarity < maintainRewriteSimilarity,
    );
  }

  /// 文本相似度：复用 [PromptGate.jaccard] 的词元切分（CJK 逐字）。
  /// 任一侧词元数不足时返回 null——那是「测不了」，不是「测出来为 0」。
  static double? similarity(String a, String b) {
    if (a.trim().isEmpty || b.trim().isEmpty) return null;
    if (PromptGate.tokens(a).length < PromptGate.minTokens ||
        PromptGate.tokens(b).length < PromptGate.minTokens) {
      return null;
    }
    return PromptGate.jaccard(a, b);
  }
}
