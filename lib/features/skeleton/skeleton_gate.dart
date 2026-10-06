/// 剧本骨架认领覆盖门（M22 T23.2）。
///
/// 纯函数、不写库、只提示不阻塞。校验码登记见 `docs/04` §8.ee.1：
/// `coverage`（唯一一条码，locator 区分对象）。认领关系是
/// `Beats.sourceRef`（E##）被 `Shots.beatRefs` 引用，
/// 错一处会让下游时长预算、对白门槛与提示词引用同时失真。
///
/// 四项子检查共用一个门码，因为修法是同一个动作（改段落的 beatRefs），
/// 拆成四个码只会在 UI 上多四行同类提示。
library;

import 'dart:convert';

import '../../core/gate_issue.dart';
import '../../data/app_database.dart';

abstract final class SkeletonGate {
  SkeletonGate._();

  /// 执行认领覆盖检查。
  ///
  /// [beats] 需按 [beatOrder] 排序；[shots] 的读取顺序不影响结果。
  static List<GateIssue> coverage({
    required List<Beat> beats,
    required List<Shot> shots,
  }) {
    final refsInOrder = [for (final b in beats) b.sourceRef];
    final known = {for (final b in beats) b.sourceRef};

    final issues = <GateIssue>[];

    // 1. 唯一性：sourceRef 重复会让后续按引用解析全部指向第一个。
    final seen = <String>{};
    for (final b in beats) {
      if (!seen.add(b.sourceRef)) {
        issues.add(
          GateIssue(
            code: 'coverage',
            severity: GateSeverity.error,
            locator: b.sourceRef,
            message: '节拍编号 ${b.sourceRef} 重复，按引用解析会全部指向第一个',
          ),
        );
      }
    }

    // 2. 认领次数与 3. 引用合法性。
    final claimCount = <String, int>{};
    final claimShots = <String, List<Shot>>{};
    for (final shot in shots) {
      for (final ref in _decodeStringList(shot.beatRefs)) {
        claimCount[ref] = (claimCount[ref] ?? 0) + 1;
        claimShots.putIfAbsent(ref, () => <Shot>[]).add(shot);
        if (!known.contains(ref)) {
          issues.add(
            GateIssue(
              code: 'coverage',
              severity: GateSeverity.error,
              locator: shot.globalSeq,
              message: '${shot.globalSeq} 引用了不存在的节拍 $ref',
            ),
          );
        }
      }
    }
    for (final entry in claimCount.entries) {
      if (entry.value > 1) {
        issues.add(
          GateIssue(
            code: 'coverage',
            severity: GateSeverity.warn,
            locator: entry.key,
            message: '节拍 ${entry.key} 被 '
                '${claimShots[entry.key]!.map((s) => s.globalSeq).join('、')} '
                '认领 ${entry.value} 次，应恰好一次',
          ),
        );
      }
    }

    // 4. 段内顺序倒流：beatRefs 应按 beats 的全局顺序出现。
    for (final shot in shots) {
      final refs = _decodeStringList(shot.beatRefs);
      var last = -1;
      for (final ref in refs) {
        final index = refsInOrder.indexOf(ref);
        if (index < 0) continue;
        if (index < last) {
          issues.add(
            GateIssue(
              code: 'coverage',
              severity: GateSeverity.warn,
              locator: shot.globalSeq,
              message: '${shot.globalSeq} 的节拍引用顺序倒流（$ref 排在 '
                  '更靠后的节拍之后），提示词按引用顺序拼装会读到旧内容',
            ),
          );
          break;
        }
        last = index;
      }
    }

    // 5. 未认领节拍。
    for (final b in beats) {
      if ((claimCount[b.sourceRef] ?? 0) == 0) {
        issues.add(
          GateIssue(
            code: 'coverage',
            severity: GateSeverity.warn,
            locator: b.sourceRef,
            message: '节拍 ${b.sourceRef} 未被任何段认领，这段剧情不会进入成片',
          ),
        );
      }
    }

    return issues;
  }

  /// 节拍全局顺序：按 `E##` 编号数字升序，编号无法解析的排在按编号排序的结果之后。
  ///
  /// 保留全部条目（含重复编号）：重号本身是 [coverage] 要报的问题，
  /// 排序不能先把它们压掉。
  static List<Beat> beatOrder(List<Beat> beats) {
    final rest = <Beat>[];
    final numbered = <Beat>[];
    for (final b in beats) {
      final number = _beatNumber(b.sourceRef);
      if (number == null) {
        rest.add(b);
      } else {
        numbered.add(b);
      }
    }
    numbered.sort((a, b) => _beatNumber(a.sourceRef)!
        .compareTo(_beatNumber(b.sourceRef)!));
    return [
      ...numbered,
      ...rest,
    ];
  }

  /// `E##` 编号解析；不符合格式返回 null。
  static int? _beatNumber(String ref) {
    final match = RegExp(r'^E(\d+)$').firstMatch(ref.trim());
    return match == null ? null : int.parse(match.group(1)!);
  }

  static List<String> _decodeStringList(String value) {
    Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      return const [];
    }
    if (decoded is List) return [for (final v in decoded) v.toString()];
    return const [];
  }
}
