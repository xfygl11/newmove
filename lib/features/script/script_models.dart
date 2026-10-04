/// 剧本改编模块的领域模型（AI 产物，与 Drift 表模型分层）。
library;

import 'package:newmove/core/json_values.dart';

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
      speaker: jsonString(json['speaker']),
      type: jsonString(json['type'], '对白'),
      text: jsonString(json['text']),
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
    final sound = jsonMap(json['sound']);
    return AdaptedScene(
      seq: jsonInt(json['seq']),
      location: jsonString(json['location']),
      time: jsonString(json['time']),
      characters: [for (final c in jsonList(json['characters'])) c.toString()],
      summary: jsonString(json['summary']),
      action: jsonString(json['action']),
      dialogue: [
        for (final d in jsonList(json['dialogue']))
          DialogueLine.fromJson(jsonMap(d)),
      ],
      music: _stringList(sound['music']),
      sfx: _stringList(sound['sfx']),
      startState: jsonString(json['startState']),
      endState: jsonString(json['endState']),
      transition: jsonString(json['transition']),
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
    'sound': {'music': music, 'sfx': sfx},
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
      id: jsonString(json['id'], fallbackId ?? ''),
      type: jsonString(json['type'], '其他'),
      text: jsonString(json['text']),
      source: jsonString(json['source']),
      accepted: jsonBool(json['accepted']),
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
        for (final s in jsonList(json['scenes']))
          AdaptedScene.fromJson(jsonMap(s)),
      ],
      proposals: () {
        final list = jsonList(json['proposals']);
        return [
          for (var i = 0; i < list.length; i++)
            AdaptationProposal.fromJson(
              jsonMap(list[i]),
              fallbackId: 'P${i + 1}',
            ),
        ];
      }(),
    );
  }

  Map<String, dynamic> toJson() => {
    'scenes': [for (final s in scenes) s.toJson()],
    'proposals': [for (final p in proposals) p.toJson()],
  };
}
