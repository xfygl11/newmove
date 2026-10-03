/// 镜头状态常量（DB 直接存中文）。
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

  static const all = [
    awaitingPrompt,
    awaitingImage,
    generating,
    reviewing,
    confirmed,
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
      seq: json['seq'] as int? ?? 1,
      timeRange: (json['timeRange'] as String? ?? '').trim(),
      subject: (json['subject'] as String? ?? '').trim(),
      shotSize: (json['shotSize'] as String? ?? '').trim(),
      angle: normalizeAngle(json['angle'] as String? ?? ''),
      camera: (json['camera'] as String? ?? '').trim(),
      blocking: (json['blocking'] as String? ?? '').trim(),
      performance: (json['performance'] as String? ?? '').trim(),
      dialogue: (json['dialogue'] as String?)?.trim(),
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
  const ShotRefDraft({
    required this.role,
    required this.stableId,
  });

  /// 角色参考 / 场景参考 / 道具参考 / 仅站位。
  final String role;
  final String stableId;

  factory ShotRefDraft.fromJson(Map<String, dynamic> json) {
    return ShotRefDraft(
      role: _normalizeRole(json['role'] as String? ?? ''),
      stableId: (json['stableId'] as String? ?? '').trim(),
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
  });

  final String globalSeq;

  /// 主景别：远景 / 全景 / 中景 / 近景 / 特写。
  final String shotType;
  final String prompt;
  final List<ShotFrameDraft> frames;
  final List<ShotRefDraft> refs;

  factory ShotDraft.fromJson(Map<String, dynamic> json) {
    return ShotDraft(
      globalSeq: (json['globalSeq'] as String? ?? '').trim(),
      shotType: normalizeShotType(json['shotType'] as String? ?? ''),
      prompt: (json['prompt'] as String? ?? '').trim(),
      frames: [
        for (final f in (json['frames'] as List<dynamic>? ?? const []))
          ShotFrameDraft.fromJson((f as Map).cast<String, dynamic>()),
      ],
      refs: [
        for (final r in (json['refs'] as List<dynamic>? ?? const []))
          ShotRefDraft.fromJson((r as Map).cast<String, dynamic>()),
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
}

/// ShotDirector 一次输出的完整结果。
class ShotDirectionResult {
  const ShotDirectionResult({required this.shots});

  final List<ShotDraft> shots;

  factory ShotDirectionResult.fromJson(Map<String, dynamic> json) {
    return ShotDirectionResult(
      shots: [
        for (final s in (json['shots'] as List<dynamic>? ?? const []))
          ShotDraft.fromJson((s as Map).cast<String, dynamic>()),
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
