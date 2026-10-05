/// 章节目标字数门槛（M17 T19.5）。
///
/// 纯函数、不写库。目标是防止「写了 1200 字当 2000 字交差」或「写成 8000 字的
/// 流水账还当一章交」这两类必然踩到的偏差。
///
/// 门槛是提示不是阻塞：定稿前不达标弹确认，用户可放行——字数偏差属于创作
/// 判断，App 不替用户决定。
abstract final class ChapterWordGate {
  ChapterWordGate._();

  /// 实际字数不得低于目标的下限比例。
  static const double minRatio = 0.8;

  /// 实际字数不得高于目标的上限比例。
  static const double maxRatio = 1.3;

  /// 实际字数与目标的比值；目标为 0 时返回 0。
  static double ratio(int wordCount, int targetWords) =>
      targetWords <= 0 ? 0 : wordCount / targetWords;

  /// 返回不达标原因；`null` 表示通过或跳过校验。
  ///
  /// [targetWords] 为 0 或负数时跳过——表示该作品未设目标字数。
  static WordGateResult? issue(int wordCount, int targetWords) {
    if (targetWords <= 0) return null;
    final r = ratio(wordCount, targetWords);
    if (r < minRatio || r > maxRatio) {
      return WordGateResult(wordCount, targetWords, r);
    }
    return null;
  }
}

/// 一次字数校验的不达标结果，供 UI 展示与判定高低方向。
class WordGateResult {
  const WordGateResult(this.wordCount, this.targetWords, this.ratio);

  final int wordCount;
  final int targetWords;
  final double ratio;

  bool get low => ratio < ChapterWordGate.minRatio;

  bool get high => ratio > ChapterWordGate.maxRatio;

  int get ratioPercent => (ratio * 100).round();

  /// 提示文案：不达标方向 + 达标率，定稿确认框直接用。
  String get message => low
      ? '当前 $wordCount 字，低于目标 $targetWords 字下限'
            '（${(ChapterWordGate.minRatio * 100).round()}%），'
            '达标率 $ratioPercent%。建议续写补足。'
      : '当前 $wordCount 字，高于目标 $targetWords 字上限'
            '（${(ChapterWordGate.maxRatio * 100).round()}%），'
            '达标率 $ratioPercent%。建议拆分或删减。';
}
