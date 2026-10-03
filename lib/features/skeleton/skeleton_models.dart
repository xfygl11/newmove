/// 剧本骨架模块的领域模型（AI 产物，与 Drift 表模型分层）。
library;

/// 原子节拍（源剧情账本 E##）。
class SkeletonBeat {
  const SkeletonBeat({
    required this.id,
    required this.sceneSeq,
    required this.type,
    required this.who,
    required this.content,
    required this.object,
    required this.estDurationMs,
    required this.tags,
  });

  final String id;
  // 来源场次序号（对应 Scenes.seq），用于落库到 Beats.sceneId。
  final int sceneSeq;
  final String type;
  final String who;
  final String content;
  final String object;
  final int estDurationMs;
  final List<String> tags;

  factory SkeletonBeat.fromJson(Map<String, dynamic> json) {
    return SkeletonBeat(
      id: json['id'] as String? ?? '',
      sceneSeq: json['sceneSeq'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      who: json['who'] as String? ?? '',
      content: json['content'] as String? ?? '',
      object: json['object'] as String? ?? '',
      estDurationMs: json['estDurationMs'] as int? ?? 0,
      tags: _stringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sceneSeq': sceneSeq,
    'type': type,
    'who': who,
    'content': content,
    'object': object,
    'estDurationMs': estDurationMs,
    'tags': tags,
  };

  static List<String> _stringList(dynamic value) {
    if (value is List) return [for (final v in value) v.toString()];
    return const [];
  }
}

/// 时间轴出镜状态点。
class TimelineEntry {
  const TimelineEntry({required this.range, required this.state});

  final String range;
  final String state;

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      range: json['range'] as String? ?? '',
      state: json['state'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'range': range, 'state': state};
}

/// 单个资产的出镜状态（角色 / 场景 / 道具共用）。
class AppearanceState {
  const AppearanceState({required this.name, required this.timeline});

  final String name;
  final List<TimelineEntry> timeline;

  factory AppearanceState.fromJson(Map<String, dynamic> json) {
    return AppearanceState(
      name: json['name'] as String? ?? '',
      timeline: [
        for (final t in (json['timeline'] as List<dynamic>? ?? const []))
          TimelineEntry.fromJson((t as Map).cast<String, dynamic>()),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'timeline': [for (final t in timeline) t.toJson()],
  };
}

/// 一段内的资产出镜状态。
class SegmentAssets {
  const SegmentAssets({
    required this.characters,
    required this.scenes,
    required this.props,
  });

  final List<AppearanceState> characters;
  final List<AppearanceState> scenes;
  final List<AppearanceState> props;

  factory SegmentAssets.fromJson(Map<String, dynamic> json) {
    return SegmentAssets(
      characters: _list(json['characters']),
      scenes: _list(json['scenes']),
      props: _list(json['props']),
    );
  }

  Map<String, dynamic> toJson() => {
    'characters': [for (final a in characters) a.toJson()],
    'scenes': [for (final a in scenes) a.toJson()],
    'props': [for (final a in props) a.toJson()],
  };

  static List<AppearanceState> _list(dynamic value) {
    if (value is List) {
      return [
        for (final v in value)
          AppearanceState.fromJson((v as Map).cast<String, dynamic>()),
      ];
    }
    return const [];
  }
}

/// 分段 G##。
class SkeletonSegment {
  const SkeletonSegment({
    required this.id,
    required this.batch,
    required this.durationMs,
    required this.globalTimeRange,
    required this.beatRefs,
    required this.assets,
  });

  final String id;
  final int batch;
  final int durationMs;
  final String globalTimeRange;
  final List<String> beatRefs;
  final SegmentAssets assets;

  factory SkeletonSegment.fromJson(Map<String, dynamic> json) {
    return SkeletonSegment(
      id: json['id'] as String? ?? '',
      batch: json['batch'] as int? ?? 1,
      durationMs: json['durationMs'] as int? ?? 0,
      globalTimeRange: json['globalTimeRange'] as String? ?? '',
      beatRefs: _stringList(json['beatRefs']),
      assets: SegmentAssets.fromJson(
        (json['assets'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'batch': batch,
    'durationMs': durationMs,
    'globalTimeRange': globalTimeRange,
    'beatRefs': beatRefs,
    'assets': assets.toJson(),
  };

  static List<String> _stringList(dynamic value) {
    if (value is List) return [for (final v in value) v.toString()];
    return const [];
  }
}

/// 骨架完整性检查发现的问题。
class SkeletonIssue {
  const SkeletonIssue({
    required this.kind,
    required this.ref,
    required this.message,
  });

  // unmapped_beat：节拍未映射到任何段；unknown_ref：段引用了不存在的节拍。
  final String kind;
  final String ref;
  final String message;
}

/// 一次骨架提取的完整产物。
class SkeletonResult {
  const SkeletonResult({
    required this.globalDurationMs,
    required this.beats,
    required this.segments,
  });

  final int globalDurationMs;
  final List<SkeletonBeat> beats;
  final List<SkeletonSegment> segments;

  factory SkeletonResult.fromJson(Map<String, dynamic> json) {
    return SkeletonResult(
      globalDurationMs: json['globalDurationMs'] as int? ?? 0,
      beats: [
        for (final b in (json['beats'] as List<dynamic>? ?? const []))
          SkeletonBeat.fromJson((b as Map).cast<String, dynamic>()),
      ],
      segments: [
        for (final s in (json['segments'] as List<dynamic>? ?? const []))
          SkeletonSegment.fromJson((s as Map).cast<String, dynamic>()),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'globalDurationMs': globalDurationMs,
    'beats': [for (final b in beats) b.toJson()],
    'segments': [for (final s in segments) s.toJson()],
  };
}
