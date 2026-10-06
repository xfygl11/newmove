/// 镜头侧本地质量门（M22 T23.2）。
///
/// 纯函数、不写库、只提示不阻塞。校验码登记见 `docs/04` §8.ee.1：
///
/// - `crowd_check`（warn）同框角色数超过 [ShotGate.maxOnScreen]。参考图锁的是
///   单人造型，第 4 个人物没有锚点可依，模型会漏人或合成。
/// - `segment_seq`（warn）段号不符合 `G01` 格式，或批内不连号。拼接导出按
///   段号排序，断号会让成片顺序错。
/// - `frame_empty`（error）分镜图提示词没有中文正文。出图会是随机画面，
///   属于会白烧算力的硬错。
/// - `phrase_missing`（warn）景别 / 运镜词没落进分镜图提示词。结构化字段
///   填了但提示词不生效等于没填，模型看不到这个约束。
/// - `video_no_names`（warn）视频提示词的叙述正文出现角色名。视频侧引用
///   角色必须走 `{{ref N}}`，直呼其名会让模型去找字面实体。
///   分镜图侧语义相反、要直呼其名（见 `assets/skills/shot/storyboard.md`），
///   两条相反的门写在同一文件便于对照，别拆到两个文件。
library;

import 'dart:convert';

import '../../core/gate_issue.dart';
import '../../core/json_values.dart';
import '../../data/app_database.dart';

abstract final class ShotGate {
  ShotGate._();

  /// 同框角色上限。
  static const int maxOnScreen = 3;

  /// 段号格式：G01 / G02 ...
  static final RegExp segmentSeqPattern = RegExp(r'^G\d{2}$');

  /// 分镜图提示词的最小正文长度（去空白后）。低于这个值基本是模板残留。
  static const int minFramePromptChars = 20;

  /// 执行全部镜头门。
  ///
  /// [videoPrompt] 为视频侧 A9 提示词时启用 [videoNoNames]；分镜图侧不查。
  static List<GateIssue> validate({
    required List<Shot> shots,
    List<ShotFrame> frames = const [],
    List<String> characterNames = const [],
    String? videoPrompt,
  }) {
    return [
      ...crowdCheck(shots),
      ...segmentSeq(shots),
      ...frameEmpty(shots),
      ...phraseMissing(shots: shots, frames: frames),
      if (videoPrompt != null && videoPrompt.isNotEmpty)
        ...videoNoNames(
          locator: 'video',
          prompt: videoPrompt,
          characterNames: characterNames,
        ),
    ];
  }

  /// 同框人数门。角色数从 `assetStates.characters` 解析。
  static List<GateIssue> crowdCheck(List<Shot> shots) {
    final issues = <GateIssue>[];
    for (final shot in shots) {
      final count = onScreenCharacters(shot);
      if (count > maxOnScreen) {
        issues.add(
          GateIssue(
            code: 'crowd_check',
            severity: GateSeverity.warn,
            locator: shot.globalSeq,
            message: '同框角色 $count 人，超过上限 $maxOnScreen 人。'
                '参考图锁的是单人造型，多出来的人没有锚点可依，'
                '模型会漏人或合成，需要减人或在提示词里写清站位拆解',
          ),
        );
      }
    }
    return issues;
  }

  /// 解析本镜头同框角色数。解析失败返回 0（按未指定处理，不误报）。
  static int onScreenCharacters(Shot shot) {
    final decoded = _decode(shot.assetStates);
    if (decoded == null) return 0;
    final map = jsonMap(decoded);
    return jsonList(map['characters']).length;
  }

  /// 段号格式与批内连号门。
  static List<GateIssue> segmentSeq(List<Shot> shots) {
    final issues = <GateIssue>[];
    for (final shot in shots) {
      final seq = shot.globalSeq.trim();
      if (!segmentSeqPattern.hasMatch(seq)) {
        issues.add(
          GateIssue(
            code: 'segment_seq',
            severity: GateSeverity.warn,
            locator: shot.globalSeq,
            message: '段号「${shot.globalSeq}」不符合 G01 格式，拼接导出按段号排序',
          ),
        );
      }
    }

    final byBatch = <int, List<Shot>>{};
    for (final shot in shots) {
      byBatch.putIfAbsent(shot.batch, () => <Shot>[]).add(shot);
    }
    for (final entry in byBatch.entries) {
      final numbers = [
        for (final shot in entry.value)
          if (segmentSeqPattern.hasMatch(shot.globalSeq.trim()))
            int.parse(shot.globalSeq.trim().substring(1)),
      ]..sort();
      for (var i = 0; i < numbers.length; i++) {
        if (numbers[i] != i + 1) {
          issues.add(
            GateIssue(
              code: 'segment_seq',
              severity: GateSeverity.warn,
              locator: 'batch ${entry.key}',
              message: '本批段号 ${numbers.join('、')} 从 01 起不连号'
                  '（第 ${i + 1} 位期望 G${(i + 1).toString().padLeft(2, '0')}）',
            ),
          );
          break;
        }
      }
    }
    return issues;
  }

  /// 分镜图提示词非空门：去空白后不足 [minFramePromptChars] 或不含中文即报。
  static List<GateIssue> frameEmpty(List<Shot> shots) {
    final issues = <GateIssue>[];
    for (final shot in shots) {
      final prompt = shot.prompt.trim();
      if (prompt.isEmpty) {
        issues.add(
          GateIssue(
            code: 'frame_empty',
            severity: GateSeverity.error,
            locator: shot.globalSeq,
            message: '分镜图提示词为空，出图会是随机画面',
          ),
        );
      } else if (prompt.length < minFramePromptChars || !hasChinese(prompt)) {
        issues.add(
          GateIssue(
            code: 'frame_empty',
            severity: GateSeverity.error,
            locator: shot.globalSeq,
            message: '分镜图提示词去空白后仅 ${prompt.length} 字且无中文正文，'
                '出图会是随机画面',
          ),
        );
      }
    }
    return issues;
  }

  /// 是否含中日韩字符。提示词是中文产出，没有中文说明拼装断了。
  static bool hasChinese(String text) {
    for (var i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 0x4e00 && code <= 0x9fff) return true;
    }
    return false;
  }

  /// 景别与运镜词回查门：结构化字段填了但提示词里没有，模型看不到约束。
  static List<GateIssue> phraseMissing({
    required List<Shot> shots,
    required List<ShotFrame> frames,
  }) {
    final framesByShot = <int, List<ShotFrame>>{};
    for (final frame in frames) {
      framesByShot.putIfAbsent(frame.shotId, () => <ShotFrame>[]).add(frame);
    }

    final issues = <GateIssue>[];
    for (final shot in shots) {
      final prompt = shot.prompt.trim();
      if (prompt.isEmpty) continue;

      final shotType = shot.shotType?.trim() ?? '';
      if (shotType.isNotEmpty && !prompt.contains(shotType)) {
        issues.add(
          GateIssue(
            code: 'phrase_missing',
            severity: GateSeverity.warn,
            locator: shot.globalSeq,
            message: '景别「$shotType」没落进分镜图提示词，模型看不到这个约束',
          ),
        );
      }

      final seen = <String>{};
      for (final frame in framesByShot[shot.id] ?? const <ShotFrame>[]) {
        final entries = [
          (frame.shotSize.trim(), '景别'),
          (frame.camera.trim(), '运镜'),
        ];
        for (final entry in entries) {
          final value = entry.$1;
          if (value.isEmpty || value == '固定' || seen.contains(value)) continue;
          seen.add(value);
          if (!prompt.contains(value)) {
            issues.add(
              GateIssue(
                code: 'phrase_missing',
                severity: GateSeverity.warn,
                locator: '${shot.globalSeq} · F${frame.seq}',
                message: '${entry.$2}「$value」没落进分镜图提示词，'
                    '结构化字段填了但模型看不到',
              ),
            );
          }
        }
      }
    }
    return issues;
  }

  /// 视频提示词禁角色名门。
  ///
  /// 先剥掉必须出现角色名的区块（参考图绑定、服装覆盖），
  /// 剩下的叙述正文才是判定对象——参考图绑定靠名字把 `{{ref N}}` 映射到资产，
  /// 名字必须在。
  static List<GateIssue> videoNoNames({
    required String locator,
    required String prompt,
    required List<String> characterNames,
  }) {
    if (characterNames.isEmpty) return const [];
    final narrative = narrativeOnly(prompt);
    final issues = <GateIssue>[];
    for (final name in characterNames) {
      final n = name.trim();
      if (n.isEmpty) continue;
      if (narrative.contains(n)) {
        issues.add(
          GateIssue(
            code: 'video_no_names',
            severity: GateSeverity.warn,
            locator: locator,
            message: '视频提示词叙述正文出现角色名「$n」，视频侧请改用 {{ref N}} '
                '（分镜图侧相反，要直呼其名）',
          ),
        );
      }
    }
    return issues;
  }

  /// 视频提示词里允许出现角色名的区块（名字在这里是必需的）。
  static const Set<String> _excludedSections = {
    'Reference binding:',
    'Costume overrides:',
  };

  /// 已知区块标题：遇到新标题就切一次「是否跳过」状态。
  static const Set<String> _sectionHeaders = {
    'Objective:',
    'Reference binding:',
    'Costume overrides:',
    'Immutable locks:',
    'Target duration:',
    'Camera spec:',
    'Timeline:',
    'Visual direction:',
    'Audio direction:',
    'Preserve:',
    'Avoid:',
  };

  /// 剥掉 [_excludedSections] 里的区块，只留叙述正文。
  ///
  /// 标题必须逐行精确匹配，避免正文里出现 `Timeline:` 之类字样被误判为区块头。
  static String narrativeOnly(String prompt) {
    final kept = <String>[];
    var skip = false;
    for (final line in prompt.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && _sectionHeaders.contains(trimmed)) {
        if (_excludedSections.contains(trimmed)) {
          skip = true;
          continue;
        }
        skip = false;
      }
      if (!skip) kept.add(line);
    }
    return kept.join('\n');
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}
