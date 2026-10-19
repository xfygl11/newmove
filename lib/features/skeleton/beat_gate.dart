/// 骨架爽点表门（M30）。
///
/// 纯函数、不写库、只提示不阻塞。校验码登记见 `AGENTS.md`：
///
/// - `beat_gap`（warn）相邻 major 爽点按 `E##` 节拍序号差度量，间隔超
///   [maxMajorGap] 报警，含开头真空与结尾真空。
/// - `major_early`（warn）首个 major 爽点落在最后一个分段内——全片高潮
///   不能压到结尾才给第一个爆点。
/// - `hook_orphan`（error）`hookBeatId` 引用的伏笔节拍 id 不存在。
///   `hookBeatId` 为空是常态，只有非空且引用悬空才报。
///
/// 三条门都读 `Beats.weight` / `Beats.hookBeatId`，爽点表接线见 M30：
/// `weight` 空回落 minor，`hookBeatId` 是兑现节拍指向伏笔埋设节拍的软引用。
library;

import 'dart:convert';

import '../../core/gate_issue.dart';
import '../../data/app_database.dart';

/// 骨架爽点表门。
class BeatGate {
  BeatGate._();

  /// 相邻 major 爽点最大间隔（节拍序号差）。经验默认值，函数参数可覆盖。
  /// shuohao `novel-outline` G4 是「≤3 集」，本项目骨架无集概念，按节拍粒度
  /// 映射：一集约 12 拍，超出一集量程还没给大爆点即节奏断档。
  static const int maxMajorGap = 12;

  /// 三条门一起跑。[beats] 按 `seq` 升序（`BeatDao.listByScript` 的顺序），
  /// [shots] 用于解析段归属（`major_early`）。
  static List<GateIssue> validate({
    required List<Beat> beats,
    required List<Shot> shots,
    int maxMajorGap = maxMajorGap,
  }) {
    return [
      ...beatGap(beats, maxMajorGap: maxMajorGap),
      ...majorEarly(beats, shots),
      ...hookOrphan(beats),
    ];
  }

  /// 相邻 major 爽点间隔（含首尾真空）。
  static List<GateIssue> beatGap(List<Beat> beats, {int maxMajorGap = maxMajorGap}) {
    final majors = _majors(beats);
    if (majors.isEmpty || beats.length < 2) return const [];

    final issues = <GateIssue>[];

    // 开头真空：首个 major 之前无爆点节拍数超阈值。
    if (majors.first.seq > maxMajorGap) {
      issues.add(
        GateIssue(
          code: 'beat_gap',
          severity: GateSeverity.warn,
          locator: majors.first.sourceRef,
          message: '开头 ${majors.first.seq - 1} 拍无大爆点（首个 major 在 '
              '${majors.first.sourceRef}），爽点开场真空',
        ),
      );
    }

    // 中间断档：相邻 major 序号差超阈值。
    for (var i = 1; i < majors.length; i++) {
      final gap = majors[i].seq - majors[i - 1].seq;
      if (gap > maxMajorGap) {
        issues.add(
          GateIssue(
            code: 'beat_gap',
            severity: GateSeverity.warn,
            locator: majors[i].sourceRef,
            message: '${majors[i - 1].sourceRef} → ${majors[i].sourceRef} '
                '间隔 $gap 拍，超过 $maxMajorGap 拍无大爆点',
          ),
        );
      }
    }

    // 结尾真空：最后一个 major 之后无爆点节拍数超阈值。
    final tail = beats.length - majors.last.seq;
    if (tail >= maxMajorGap) {
      issues.add(
        GateIssue(
          code: 'beat_gap',
          severity: GateSeverity.warn,
          locator: majors.last.sourceRef,
          message: '结尾 $tail 拍无大爆点（最后 major 在 '
              '${majors.last.sourceRef}），爽点结尾真空',
        ),
      );
    }

    return issues;
  }

  /// 首个 major 爽点落在最后一个分段内。
  static List<GateIssue> majorEarly(List<Beat> beats, List<Shot> shots) {
    final majors = _majors(beats);
    if (majors.isEmpty || shots.isEmpty) return const [];

    // 段归属：节拍 sourceRef(E##) → 段 globalSeq；未认领的 major 由 coverage
    // 门处理，这里跳过。
    final beatSeg = <String, String>{};
    for (final s in shots) {
      for (final ref in _decodeStringList(s.beatRefs)) {
        beatSeg.putIfAbsent(ref, () => s.globalSeq);
      }
    }
    final orderedSegs = <String>[];
    for (final s in shots) {
      if (!orderedSegs.contains(s.globalSeq)) orderedSegs.add(s.globalSeq);
    }
    orderedSegs.sort();
    if (orderedSegs.isEmpty) return const [];

    final lastSeg = orderedSegs.last;
    final firstMajor = majors.first;
    if (beatSeg[firstMajor.sourceRef] == lastSeg) {
      return [
        GateIssue(
          code: 'major_early',
          severity: GateSeverity.warn,
          locator: firstMajor.sourceRef,
          message: '首个大爆点 ${firstMajor.sourceRef} 落在末段 $lastSeg，'
              '全片高潮压到结尾才给第一个爆点',
        ),
      ];
    }
    return const [];
  }

  /// hookBeatId 引用的伏笔节拍 id 不存在。
  static List<GateIssue> hookOrphan(List<Beat> beats) {
    final ids = {for (final b in beats) b.id};
    return [
      for (final b in beats)
        if (b.hookBeatId != null && !ids.contains(b.hookBeatId))
          GateIssue(
            code: 'hook_orphan',
            severity: GateSeverity.error,
            locator: b.sourceRef,
            message: '${b.sourceRef} 的钩子兑现指向不存在的伏笔节拍 '
                '#${b.hookBeatId}',
          ),
    ];
  }

  /// 按 seq 升序提取 major 爽点。weight 空/null 回落 minor，不参与。
  static List<Beat> _majors(List<Beat> beats) {
    final result = [
      for (final b in beats)
        if ((b.weight ?? '').trim() == 'major') b,
    ];
    result.sort((a, b) => a.seq.compareTo(b.seq));
    return result;
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
