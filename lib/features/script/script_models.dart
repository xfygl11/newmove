/// 剧本改编模块的领域模型（AI 产物，与 Drift 表模型分层）。
library;

/// 一句对白 / 画外音。
class DialogueLine {
  const DialogueLine({
    required this.speaker,
    required this.type,
    required this.text,
  });

  final String speaker;
  // 对白 / OS / VO。
  final String type;
  final String text;

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      speaker: json['speaker'] as String? ?? '',
      type: json['type'] as String? ?? '对白',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'speaker': speaker,
    'type': type,
    'text': text,
  };

  DialogueLine copyWith({String? speaker, String? type, String? text}) {
    return DialogueLine(
      speaker: speaker ?? this.speaker,
      type: type ?? this.type,
      text: text ?? this.text,
    );
  }
}

/// 一场改编结果。
class AdaptedScene {
  const AdaptedScene({
    required this.seq,
    required this.location,
    required this.time,
    required this.characters,
    required this.summary,
    required this.action,
    required this.dialogue,
    required this.music,
    required this.sfx,
    required this.startState,
    required this.endState,
    required this.transition,
  });

  final int seq;
  final String location;
  final String time;
  final List<String> characters;
  final String summary;
  final String action;
  final List<DialogueLine> dialogue;
  final List<String> music;
  final List<String> sfx;
  final String startState;
  final String endState;
  final String transition;

  factory AdaptedScene.fromJson(Map<String, dynamic> json) {
    final sound = json['sound'];
    final soundMap = sound is Map<String, dynamic> ? sound : const <String, dynamic>{};
    return AdaptedScene(
      seq: json['seq'] as int? ?? 0,
      location: json['location'] as String? ?? '',
      time: json['time'] as String? ?? '',
      characters: [
        for (final c in (json['characters'] as List<dynamic>? ?? const []))
          c.toString(),
      ],
      summary: json['summary'] as String? ?? '',
      action: json['action'] as String? ?? '',
      dialogue: [
        for (final d in (json['dialogue'] as List<dynamic>? ?? const []))
          DialogueLine.fromJson((d as Map).cast<String, dynamic>()),
      ],
      music: _stringList(soundMap['music']),
      sfx: _stringList(soundMap['sfx']),
      startState: json['startState'] as String? ?? '',
      endState: json['endState'] as String? ?? '',
      transition: json['transition'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'seq': seq,
    'location': location,
    'time': time,
    'characters': characters,
    'summary': summary,
    'action': action,
    'dialogue': [for (final d in dialogue) d.toJson()],
    'sound': {
      'music': music,
      'sfx': sfx,
    },
    'startState': startState,
    'endState': endState,
    'transition': transition,
  };

  static List<String> _stringList(dynamic value) {
    if (value is List) return [for (final v in value) v.toString()];
    return const [];
  }
}

/// 改编提案：AI 提出的删并/新增/改视角等建议，需用户逐条确认。
class AdaptationProposal {
  const AdaptationProposal({
    required this.id,
    required this.type,
    required this.text,
    required this.source,
    this.accepted = false,
  });

  final String id;
  final String type;
  final String text;
  final String source;
  final bool accepted;

  factory AdaptationProposal.fromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
  }) {
    return AdaptationProposal(
      id: json['id'] as String? ?? fallbackId ?? '',
      type: json['type'] as String? ?? '其他',
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? '',
      accepted: json['accepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'text': text,
    'source': source,
    'accepted': accepted,
  };

  AdaptationProposal copyWith({bool? accepted}) {
    return AdaptationProposal(
      id: id,
      type: type,
      text: text,
      source: source,
      accepted: accepted ?? this.accepted,
    );
  }
}

/// 一次改编的完整产物。
class AdaptationResult {
  const AdaptationResult({required this.scenes, required this.proposals});

  final List<AdaptedScene> scenes;
  final List<AdaptationProposal> proposals;

  factory AdaptationResult.fromJson(Map<String, dynamic> json) {
    return AdaptationResult(
      scenes: [
        for (final s in (json['scenes'] as List<dynamic>? ?? const []))
          AdaptedScene.fromJson((s as Map).cast<String, dynamic>()),
      ],
      proposals: [
        for (var i = 0; i < (json['proposals'] as List<dynamic>? ?? const []).length; i++)
          AdaptationProposal.fromJson(
            (json['proposals'] as List)[i] as Map<String, dynamic>,
            fallbackId: 'P${i + 1}',
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'scenes': [for (final s in scenes) s.toJson()],
    'proposals': [for (final p in proposals) p.toJson()],
  };
}
