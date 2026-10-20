/// 视频提示词结构对账门（M45）。
///
/// 纯函数、不写库、只提示不阻塞。校验码登记见 `docs/04` §8.v：
///
/// - `timeline_empty`（warn）Timeline 块为空。无时间轴描述的视频提示词
///   会让模型不知如何切分画面，只能自由发挥。
/// - `duration_mismatch`（warn）声明时长与目标时长不一致。提示词里写的
///   Target duration 与镜头实际时长对不上，模型会按错误的节奏生成。
/// - `reference_empty`（warn）无参考图绑定。视频生成没有参考图，人物一致性
///   全靠模型自由发挥。
/// - `missing_dialogue`（warn）认领节拍有台词但 Timeline 未包含。节拍对白
///   必须在视频提示词里出现，否则口型与台词对不上。
library;

import 'dart:convert';

import '../../core/gate_issue.dart';
import '../../data/app_database.dart';

abstract final class VideoPromptGate {
  VideoPromptGate._();

  /// 执行全部视频提示词门。
  static List<GateIssue> validate({
    required Shot shot,
    required String prompt,
    required List<Beat> beats,
  }) {
    return [
      ...timelineEmpty(shot, prompt),
      ...durationMismatch(shot, prompt),
      ...referenceEmpty(shot),
      ...missingDialogue(shot, beats, prompt),
    ];
  }

  /// Timeline 为空门。
  static List<GateIssue> timelineEmpty(Shot shot, String prompt) {
    if (!prompt.contains('Timeline:')) {
      return [
        GateIssue(
          code: 'timeline_empty',
          severity: GateSeverity.warn,
          locator: shotLocator(shot),
          message: '视频提示词缺少 Timeline 块，模型不知如何切分画面',
        ),
      ];
    }
    final idx = prompt.indexOf('Timeline:');
    final after = prompt.substring(idx + 'Timeline:'.length).trimLeft();
    if (after.isEmpty || after.startsWith('\n\n')) {
      return [
        GateIssue(
          code: 'timeline_empty',
          severity: GateSeverity.warn,
          locator: shotLocator(shot),
          message: 'Timeline 块为空，无时间轴描述',
        ),
      ];
    }
    return [];
  }

  /// 时长不一致门。
  static List<GateIssue> durationMismatch(Shot shot, String prompt) {
    if (shot.durationMs <= 0) return [];

    final targetSec = shot.durationMs ~/ 1000;
    final m = RegExp(r'Target duration:\s*(\d+)\s*s').firstMatch(prompt);
    if (m == null) return [];

    final declared = int.tryParse(m.group(1) ?? '') ?? 0;
    if (declared != targetSec) {
      return [
        GateIssue(
          code: 'duration_mismatch',
          severity: GateSeverity.warn,
          locator: shotLocator(shot),
          message: '提示词声明时长 ${declared}s 与镜头实际 ${targetSec}s 不一致',
        ),
      ];
    }
    return [];
  }

  /// 无参考图门。
  static List<GateIssue> referenceEmpty(Shot shot) {
    final refs = _decodeList(shot.assetStates);
    if (refs.isNotEmpty) return [];
    return [
      GateIssue(
        code: 'reference_empty',
        severity: GateSeverity.warn,
        locator: shotLocator(shot),
        message: '无参考图绑定，人物一致性靠模型自由发挥',
      ),
    ];
  }

  /// 台词缺失门：认领节拍有台词但 Timeline 未包含。
  static List<GateIssue> missingDialogue(
    Shot shot,
    List<Beat> beats,
    String prompt,
  ) {
    final issues = <GateIssue>[];
    final beatMap = <String, Beat>{for (final b in beats) b.sourceRef: b};
    final refs = _decodeList(shot.beatRefs);

    for (final ref in refs) {
      final beat = beatMap[ref];
      if (beat == null) continue;

      final dialogue = beat.content.trim();
      if (dialogue.isEmpty) continue;

      final normalizedDialogue = dialogue.replaceAll(RegExp(r'\s+'), '');
      final timelineStart = prompt.indexOf('Timeline:');
      if (timelineStart < 0) continue;

      final timelineSection = prompt.substring(timelineStart);
      final normalizedTimeline = timelineSection.replaceAll(RegExp(r'\s+'), '');

      final checkLen = normalizedDialogue.length > 20
          ? 20
          : normalizedDialogue.length;
      final prefix = normalizedDialogue.substring(0, checkLen);

      if (!normalizedTimeline.contains(prefix)) {
        issues.add(
          GateIssue(
            code: 'missing_dialogue',
            severity: GateSeverity.warn,
            locator: shotLocator(shot),
            message: '节拍 ${beat.sourceRef} 的台词未在 Timeline 中出现',
          ),
        );
      }
    }
    return issues;
  }

  /// 镜头定位串。
  static String shotLocator(Shot shot) =>
      '${shot.id} · ${shot.globalSeq}';

  static List<String> _decodeList(String raw) {
    if (raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final v in decoded) v.toString()];
    } on FormatException {
      return const [];
    }
  }
}
