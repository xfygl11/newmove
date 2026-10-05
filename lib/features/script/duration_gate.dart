/// 剧本与节拍的确定性时长估算（M19 T21.2 / T21.3）。
///
/// 纯函数、不写库。与 `SegmentBudget` 分工：那边负责「按目标时长切段与容量
/// 校验」，这里负责「写完就知道会超时多少」。补的是缺口，不是重复。
///
/// 门码（稳定机器码，不要改）：
/// - `line_too_long`（error）单句台词超过 [DurationGate.maxLineChars]，
///   一口气说不完，镜头生成不出来。
/// - `total_over_budget`（warn）节拍自然时长超过目标 15%。
/// - `total_under_budget`（warn）节拍自然时长低于目标 15%。
library;

import 'dart:convert';

import '../../core/gate_issue.dart';
import '../../core/json_values.dart';
import '../../data/app_database.dart';

abstract final class DurationGate {
  DurationGate._();

  /// 中文口语偏快档：每秒可念出的非空白字符数。
  static const double charsPerSecond = 4.5;

  /// 无台词节拍的回落估算时长（秒）。
  static const double actionSeconds = 2.5;

  /// 节拍自然时长与目标的容差。
  static const double totalTolerance = 0.15;

  /// 单句台词字数上限。
  static const int maxLineChars = 35;

  /// 台词计秒用的字符数：去空白，标点算时间（停顿也是时间）。
  static int lineChars(String? line) =>
      (line ?? '').replaceAll(RegExp(r'\s+'), '').length;

  /// 台词秒数，保留一位小数。
  static double lineSeconds(String? line) =>
      (lineChars(line) / charsPerSecond * 10).round() / 10;

  /// 解析 [Scene.dialogue] 的 JSON 数组为逐句台词文本，顺序不变。
  ///
  /// 场次 dialogue 是 AI 或人工写入的，坏 JSON 收敛成空列表，不抛异常。
  static List<String> dialogueLines(Scene scene) {
    final raw = scene.dialogue.trim();
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final result = <String>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final text = jsonString(item['text']);
        if (lineChars(text) > 0) result.add(text);
      }
      return result;
    } on FormatException {
      return const [];
    }
  }

  /// 单个节拍的自然时长估算（秒）。
  ///
  /// 对白按字符折算，不采信 LLM 估的 `estDurationMs`——长句粗估是超时的主因，
  /// 而且它是 LLM 自己填的，不可对账。非对白节拍取 `estDurationMs`，为 0 时
  /// 回落 [actionSeconds]。
  static double beatSeconds(Beat beat) {
    if (beat.type == '对白') return lineSeconds(beat.content);
    final ms = beat.estDurationMs;
    if (ms > 0) return (ms / 1000 * 10).round() / 10;
    return actionSeconds;
  }

  /// 全部节拍的自然时长估算（秒，保留一位小数）。
  static double beatsSeconds(List<Beat> beats) {
    var total = 0.0;
    for (final beat in beats) {
      total += beatSeconds(beat);
    }
    return (total * 10).round() / 10;
  }

  /// 单句台词超长校验，来源是场次的 dialogue 数组。
  static List<GateIssue> longLinesOfScenes(List<Scene> scenes) {
    final issues = <GateIssue>[];
    for (final scene in scenes) {
      final lines = dialogueLines(scene);
      for (var i = 0; i < lines.length; i++) {
        final chars = lineChars(lines[i]);
        if (chars > maxLineChars) {
          issues.add(
            GateIssue(
              code: 'line_too_long',
              severity: GateSeverity.error,
              locator: 'S${scene.seq}',
              message: '第 ${i + 1} 句台词 $chars 字，超过单句上限 $maxLineChars 字'
                  '（约 ${lineSeconds(lines[i])}s），一口说不完，镜头生成不出来',
            ),
          );
        }
      }
    }
    return issues;
  }

  /// 单句台词超长校验，来源是节拍（对白类）。与 [longLinesOfScenes] 共用判定。
  static List<GateIssue> longLinesOfBeats(List<Beat> beats) {
    final issues = <GateIssue>[];
    for (final beat in beats) {
      if (beat.type != '对白') continue;
      final chars = lineChars(beat.content);
      if (chars > maxLineChars) {
        issues.add(
          GateIssue(
            code: 'line_too_long',
            severity: GateSeverity.error,
            locator: beat.sourceRef.isEmpty ? 'S${beat.sceneId}' : beat.sourceRef,
            message: '台词 $chars 字，超过单句上限 $maxLineChars 字'
                '（约 ${lineSeconds(beat.content)}s），一口说不完，镜头生成不出来',
          ),
        );
      }
    }
    return issues;
  }

  /// 节拍自然时长与目标偏差校验。
  ///
  /// [targetDurationMs] 为 0 表示由内容自然节奏决定，跳过——此时报错会让
  /// 每一份未设目标的剧本都红。
  static List<GateIssue> totalBudgetOfBeats(
    List<Beat> beats,
    int targetDurationMs,
  ) {
    if (targetDurationMs <= 0) return const [];
    final totalMs = (beatsSeconds(beats) * 1000).round();
    final diffRatio = (totalMs - targetDurationMs).abs() / targetDurationMs;
    if (diffRatio <= totalTolerance) return const [];
    return [
      GateIssue(
        code: totalMs > targetDurationMs
            ? 'total_over_budget'
            : 'total_under_budget',
        severity: GateSeverity.warn,
        locator: '-',
        message: '节拍自然时长 ${(totalMs / 1000).toStringAsFixed(1)}s 与目标 '
            '${(targetDurationMs / 1000).toStringAsFixed(1)}s 偏差 '
            '${(diffRatio * 100).toStringAsFixed(1)}%（>15%）',
      ),
    ];
  }

  /// 全部时长校验（单句 + 总量）。
  static List<GateIssue> validate({
    required List<Beat> beats,
    required int targetDurationMs,
  }) {
    return [
      ...longLinesOfBeats(beats),
      ...totalBudgetOfBeats(beats, targetDurationMs),
    ];
  }

}
