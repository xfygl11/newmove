/// 分段时长预算与容量校验的唯一入口（M16，docs/02 §6.12）。
///
/// 纯函数、不写库。时长与容量的判定只走这里，别的服务不自算。
library;

import 'dart:convert';

import '../../core/json_values.dart';
import '../../data/app_database.dart';
import '../../features/provider_config/provider_models.dart';

/// 校验项严重度。
enum SegmentBudgetSeverity { error, warn }

/// 一条时长/容量校验结果。
class SegmentBudgetIssue {
  const SegmentBudgetIssue({
    required this.seq,
    required this.code,
    required this.severity,
    required this.message,
  });

  final String seq;

  /// over_limit / dialogue_overflow / total_mismatch / too_few_segments / batch_too_large。
  final String code;
  final SegmentBudgetSeverity severity;
  final String message;

  bool get isError => severity == SegmentBudgetSeverity.error;

  /// 写入 ConfirmSheet note 的紧凑一行。
  String get noteLine =>
      '[${severity == SegmentBudgetSeverity.error ? 'error' : 'warn'}] $seq $message';
}

/// 分段预算服务：解析时长上限、批次容量，并输出校验项。
class SegmentBudget {
  const SegmentBudget({
    required this.script,
    required this.segments,
    required this.beats,
    this.videoModel,
  });

  final Script script;
  final List<Shot> segments;
  final List<Beat> beats;

  /// 当前选中的视频模型；null 表示未配置或不可知，直接走 modelVersion 回落。
  final ProviderModel? videoModel;

  /// 最保守档位：Seedance 2.0 单段 15s。
  static const int defaultMaxSegmentMs = 15000;
  static const int version20MaxSegmentMs = 15000;
  static const int version25MaxSegmentMs = 30000;
  static const int version20MaxBatchSegments = 6;
  static const int version25MaxBatchSegments = 3;

  /// 呼吸余量：段预算在节拍求和基础上乘 1.1，避免自然朗读时间被压缩。
  static const double breathingMargin = 1.1;

  /// 总量偏差容忍度。
  static const double totalTolerance = 0.1;

  String get modelVersion => script.modelVersion?.trim() ?? '';

  int get targetDurationMs => script.targetDurationMs;

  /// 单段时长上限，三级回落：模型能力 → 剧本 modelVersion → 通用默认。
  int get maxSegmentMs {
    final durations = videoModel?.supportedDurations ?? const <int>[];
    if (durations.isNotEmpty) return durations.last * 1000;
    return switch (modelVersion) {
      '2.5' => version25MaxSegmentMs,
      '2.0' => version20MaxSegmentMs,
      _ => defaultMaxSegmentMs,
    };
  }

  /// 合段预算：单段上限扣除 10% 呼吸余量后的实际合并上限。
  ///
  /// 提取分段时按此值合并节拍，保证合并后的自然朗读时间不压缩台词语速。
  /// 硬上限仍是 [maxSegmentMs]，两者不同：前者约束「合并到什么程度停下」，
  /// 后者约束「生成时长不可超过」。
  int get mergeBudgetMs =>
      maxSegmentMs - (maxSegmentMs * (breathingMargin - 1)).round();

  /// 批次容量上限：单批最多输出多少段。
  int get maxBatchSegments => modelVersion == '2.5'
      ? version25MaxBatchSegments
      : version20MaxBatchSegments;

  /// 理论最少段数 `⌈目标时长 / 单段上限⌉`，只作下限提示。
  int theoreticalMinSegments(int targetMs) {
    if (targetMs <= 0) return 1;
    return (targetMs / maxSegmentMs).ceil();
  }

  /// 执行全部校验，返回按段序排列的校验项。
  List<SegmentBudgetIssue> validate() {
    final issues = <SegmentBudgetIssue>[];

    var totalMs = 0;
    for (final seg in segments) {
      totalMs += seg.durationMs;

      if (seg.durationMs > maxSegmentMs) {
        issues.add(
          SegmentBudgetIssue(
            seq: seg.globalSeq,
            code: 'over_limit',
            severity: SegmentBudgetSeverity.error,
            message: '时长 ${_fmt(seg.durationMs)} 超出单段上限 ${_fmt(maxSegmentMs)}',
          ),
        );
      }

      var dialogueMs = 0;
      for (final beat in _referencedBeats(seg)) {
        dialogueMs += beat.estDurationMs;
      }
      if (dialogueMs > seg.durationMs) {
        issues.add(
          SegmentBudgetIssue(
            seq: seg.globalSeq,
            code: 'dialogue_overflow',
            severity: SegmentBudgetSeverity.error,
            message:
                '引用节拍最低时长 ${_fmt(dialogueMs)} 超过段时长 ${_fmt(seg.durationMs)}，'
                '按对白硬门槛不得压缩台词（A3.2）',
          ),
        );
      }
    }

    if (targetDurationMs > 0) {
      final diffRatio = ((totalMs - targetDurationMs).abs()) / targetDurationMs;
      if (diffRatio > totalTolerance) {
        issues.add(
          SegmentBudgetIssue(
            seq: '-',
            code: 'total_mismatch',
            severity: SegmentBudgetSeverity.warn,
            message:
                '全片时长 ${_fmt(totalMs)} 与目标 ${_fmt(targetDurationMs)} '
                '偏差 ${(diffRatio * 100).toStringAsFixed(1)}%（>10%）',
          ),
        );
      }

      final minSegments = theoreticalMinSegments(targetDurationMs);
      if (segments.length < minSegments) {
        issues.add(
          SegmentBudgetIssue(
            seq: '-',
            code: 'too_few_segments',
            severity: SegmentBudgetSeverity.warn,
            message: '当前 ${segments.length} 段，低于理论最少 $minSegments 段，可分更多段',
          ),
        );
      }
    }

    final byBatch = <int, int>{};
    for (final seg in segments) {
      byBatch[seg.batch] = (byBatch[seg.batch] ?? 0) + 1;
    }
    for (final entry in byBatch.entries) {
      if (entry.value > maxBatchSegments) {
        issues.add(
          SegmentBudgetIssue(
            seq: 'batch ${entry.key}',
            code: 'batch_too_large',
            severity: SegmentBudgetSeverity.warn,
            message:
                '本批 ${entry.value} 段，超出 ${modelVersion.isEmpty ? '默认' : modelVersion} 版本 '
                '单批上限 $maxBatchSegments 段',
          ),
        );
      }
    }

    return issues;
  }

  List<Beat> _referencedBeats(Shot seg) {
    final map = <String, Beat>{for (final b in beats) b.sourceRef: b};
    final result = <Beat>[];
    for (final ref in _decodeStringList(seg.beatRefs)) {
      final beat = map[ref];
      if (beat != null) result.add(beat);
    }
    return result;
  }

  List<String> _decodeStringList(String value) {
    try {
      final decoded = jsonDecode(value);
      return [for (final v in jsonList(decoded)) v.toString()];
    } on FormatException {
      return const [];
    }
  }

  static String _fmt(int ms) =>
      '${(ms / 1000).toStringAsFixed(ms % 1000 == 0 ? 0 : 1)}s';
}
