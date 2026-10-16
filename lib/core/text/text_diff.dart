/// 章节版本对比的行级差异（借鉴 goink 的 Diff 预览）。
///
/// 审校 / 修订会把旧正文写进 `ChapterRevisions` 快照，但此前只在版本列表里
/// 平铺展示，用户看不出「AI 到底改了哪几段」，也无法回退。这里给出纯函数的
/// 行级 LCS 差异，供章节编辑器的版本对比使用——与质量门同属「能本地算的
/// 就不交给模型自觉」的边界。
library;

/// 一行差异的类型。
enum DiffOp {
  /// 两版都有的同一行。
  equal,

  /// 新版本新增的行。
  insert,

  /// 旧版本被删除的行。
  delete,
}

class DiffLine {
  const DiffLine(this.op, this.text);

  final DiffOp op;
  final String text;
}

abstract final class TextDiff {
  /// DP 单元上限：`行数A × 行数B` 超过它时退化为「整块替换」，
  /// 避免超长章节把 O(n*m) 的中间表撑爆内存（本机预算仅 358 MiB）。
  static const int maxCells = 1 << 20;

  /// 行级差异，以 '\n' 切行，按文本顺序返回。
  ///
  /// 规模超 [maxCells] 时不做 LCS，直接「旧块全删 + 新块全插」——结果仍正确，
  /// 只是不精细（ACT：超长章节的精细 diff 可后续换成 Myers 的 O(ND) 实现）。
  static List<DiffLine> lines(String oldText, String newText) {
    final a = _split(oldText);
    final b = _split(newText);
    final n = a.length;
    final m = b.length;
    if (n * m > maxCells) {
      return [
        for (final line in a) DiffLine(DiffOp.delete, line),
        for (final line in b) DiffLine(DiffOp.insert, line),
      ];
    }

    // dp[i][j] = a[i..] 与 b[j..] 的最长公共子序列长度。
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        dp[i][j] = a[i] == b[j]
            ? dp[i + 1][j + 1] + 1
            : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
      }
    }

    final out = <DiffLine>[];
    var i = 0;
    var j = 0;
    while (i < n && j < m) {
      if (a[i] == b[j]) {
        out.add(DiffLine(DiffOp.equal, a[i]));
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        out.add(DiffLine(DiffOp.delete, a[i]));
        i++;
      } else {
        out.add(DiffLine(DiffOp.insert, b[j]));
        j++;
      }
    }
    while (i < n) {
      out.add(DiffLine(DiffOp.delete, a[i]));
      i++;
    }
    while (j < m) {
      out.add(DiffLine(DiffOp.insert, b[j]));
      j++;
    }
    return out;
  }

  /// 差异里是否存在非 equal 行（决定要不要展示对比结果）。
  static bool hasChange(List<DiffLine> diff) =>
      diff.any((d) => d.op != DiffOp.equal);

  /// 切行：空文本按「零行」处理，而不是 `''.split('\n')` 得到的一行空串。
  /// 否则空章与有内容的章对比会多出一条看似相同、实为删除的空行差异。
  static List<String> _split(String text) =>
      text.isEmpty ? const <String>[] : text.split('\n');
}
