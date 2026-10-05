/// 镜头状态常量（DB 直接存中文）。
library;

import 'package:newmove/core/json_values.dart';

class ShotStatuses {
  ShotStatuses._();

  /// 骨架刚建立，尚未生成提示词。
  static const awaitingPrompt = '待提示词';

  /// 提示词与参考绑定已就绪，等待生成图片。
  static const awaitingImage = '待分镜图';

  /// 图片生成中。
  static const generating = '生成中';

  /// 图片已生成，等待用户验收。
  static const reviewing = '待验收';

  /// 用户确认分镜图。
  static const confirmed = '分镜图已确认';

  /// 视频生成中（M6）。
  static const videoGenerating = '视频生成中';

  /// 视频生成完成（M6）。
  static const videoDone = '视频完成';

  static const all = [
    awaitingPrompt,
    awaitingImage,
    generating,
    reviewing,
    confirmed,
    videoGenerating,
    videoDone,
  ];
}

/// ShotDirector 输出的一帧画面草案。
class ShotFrameDraft {
  const ShotFrameDraft({
    required this.seq,
    required this.timeRange,
    required this.subject,
    required this.shotSize,
    required this.angle,
    required this.camera,
    required this.blocking,
    required this.performance,
    required this.dialogue,
  });

  final int seq;
  final String timeRange;
  final String subject;
  final String shotSize;
  final String angle;
  final String camera;
  final String blocking;
  final String performance;
  final String? dialogue;

  factory ShotFrameDraft.fromJson(Map<String, dynamic> json) {
    return ShotFrameDraft(
      seq: jsonInt(json['seq'], 1),
      timeRange: jsonString(json['timeRange']).trim(),
      subject: jsonString(json['subject']).trim(),
      shotSize: jsonString(json['shotSize']).trim(),
      angle: normalizeAngle(jsonString(json['angle'])),
      camera: jsonString(json['camera']).trim(),
      blocking: jsonString(json['blocking']).trim(),
      performance: jsonString(json['performance']).trim(),
      dialogue: jsonStringOrNull(json['dialogue'])?.trim(),
    );
  }

  /// 角度词表容错：把 LLM 可能给的「镜头角度：平视」「overhead」等归一化到
  /// 平视 / 俯视 / 仰视 / 侧面 / 背面 词表，匹配不到回落「平视」。
  static String normalizeAngle(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '平视';
    if (text.contains('俯') || text.contains('overhead')) return '俯视';
    if (text.contains('仰') || text.contains('low')) return '仰视';
    if (text.contains('背')) return '背面';
    if (text.contains('侧')) return '侧面';
    return '平视';
  }
}

/// ShotDirector 输出的一条参考绑定草案。
class ShotRefDraft {
  const ShotRefDraft({required this.role, required this.stableId});

  /// 角色参考 / 场景参考 / 道具参考 / 仅站位。
  final String role;
  final String stableId;

  factory ShotRefDraft.fromJson(Map<String, dynamic> json) {
    return ShotRefDraft(
      role: _normalizeRole(jsonString(json['role'])),
      stableId: jsonString(json['stableId']).trim(),
    );
  }

  /// 角色词表容错：把 LLM 可能给的「角色」「角色参考图」等归一到词表。
  static String _normalizeRole(String raw) {
    final text = raw.trim();
    if (text.contains('道具')) return '道具参考';
    if (text.contains('场景') || text.contains('场景参考')) return '场景参考';
    if (text.contains('仅站位') || text.contains('站位')) return '仅站位';
    return '角色参考';
  }
}

/// ShotDirector 输出的单个镜头草案。
class ShotDraft {
  const ShotDraft({
    required this.globalSeq,
    required this.shotType,
    required this.prompt,
    required this.frames,
    required this.refs,
    this.composition,
    this.lens,
    this.cameraPosition,
    this.eyeline,
    this.focus,
    this.stability,
    this.blocking,
    this.dialogueStartRatio,
    this.dialogueEndRatio,
  });

  final String globalSeq;

  /// 主景别：远景 / 全景 / 中景 / 近景 / 特写。
  final String shotType;
  final String prompt;
  final List<ShotFrameDraft> frames;
  final List<ShotRefDraft> refs;

  /// 段级摄影参数（M19 T21.12）：构图 / 焦距 / 机位 / 视线 / 焦点 / 稳定性。
  final String? composition;
  final String? lens;
  final String? cameraPosition;
  final String? eyeline;
  final String? focus;
  final String? stability;

  /// 段级走位：人物在本段时长内的移动轨迹，与帧级首帧站位是两个东西。
  final String? blocking;

  /// 对白起止占段时长比例（百分比 0-100）；null 表示本段无对白。
  final int? dialogueStartRatio;
  final int? dialogueEndRatio;

  factory ShotDraft.fromJson(Map<String, dynamic> json) {
    final start = _ratio(json['dialogueStartRatio']);
    final end = _ratio(json['dialogueEndRatio']);
    return ShotDraft(
      globalSeq: jsonString(json['globalSeq']).trim(),
      shotType: normalizeShotType(jsonString(json['shotType'])),
      prompt: jsonString(json['prompt']).trim(),
      composition: _text(json['composition']),
      lens: _text(json['lens']),
      cameraPosition: _text(json['cameraPosition']),
      eyeline: _text(json['eyeline']),
      focus: _text(json['focus']),
      stability: _text(json['stability']),
      blocking: _text(json['blocking']),
      dialogueStartRatio: start,
      dialogueEndRatio: end,
      frames: [
        for (final f in jsonList(json['frames']))
          ShotFrameDraft.fromJson(jsonMap(f)),
      ],
      refs: [
        for (final r in jsonList(json['refs']))
          ShotRefDraft.fromJson(jsonMap(r)),
      ],
    );
  }

  /// 景别词表容错：提取 远/全/中/近/特 关键字并归一到五档词表。
  static String normalizeShotType(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '中景';
    if (text.contains('特')) return '特写';
    if (text.contains('近')) return '近景';
    if (text.contains('全')) return '全景';
    if (text.contains('远')) return '远景';
    return '中景';
  }

  /// 结构化字段容错：空串与占位词（无 / 未指定 / 同上 / - / N/A）一律视为未指定。
  static String? _text(Object? value) {
    final text = jsonString(value).trim();
    if (text.isEmpty) return null;
    if (_placeholders.contains(text)) return null;
    return text;
  }

  /// 对白占比容错：解析为整数并夹到 0-100，越界与不可解析视为未指定。
  static int? _ratio(Object? value) {
    if (value == null) return null;
    final n = value is num
        ? value
        : double.tryParse(jsonString(value).trim()) ?? -1;
    if (n < 0 || n > 100) return null;
    return n.round();
  }

  static const _placeholders = {'无', '未指定', '同上', '-', 'N/A', 'n/a'};
}

/// ShotDirector 一次输出的完整结果。
class ShotDirectionResult {
  const ShotDirectionResult({required this.shots});

  final List<ShotDraft> shots;

  factory ShotDirectionResult.fromJson(Map<String, dynamic> json) {
    return ShotDirectionResult(
      shots: [
        for (final s in jsonList(json['shots'])) ShotDraft.fromJson(jsonMap(s)),
      ],
    );
  }
}

/// 段间衔接校验（A7）发现的问题。
class ShotTransitionIssue {
  const ShotTransitionIssue({
    required this.fromSeq,
    required this.toSeq,
    required this.reason,
    required this.message,
  });

  final String fromSeq;
  final String toSeq;

  /// subject_same：主体相同；size_gap：景别差不足；angle_gap：角度差不足。
  final String reason;
  final String message;
}
