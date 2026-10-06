/// 剧本场次侧本地质量门（M22 T23.2）。
///
/// 纯函数、不写库、只提示不阻塞。校验码登记见 `docs/04` §8.ee.1：
///
/// - `has_action`（warn）场次没有画面动作描写。纯对话场次会让下游分镜图
///   提示词只剩人物与台词，构图全靠模型猜。
/// - `action_prose`（warn）画面动作里夹着对话引号。动作字段是画面，
///   台词必须进 `dialogue` 数组——混在一起会让 A9 的「口型对白在 dialogue
///   块」规则落不到字段上。
/// - `speaker_unknown`（warn）说话人不在本场次出场角色里。VO/OS 旁白豁免，
///   这类没有画面人物。
library;

import 'dart:convert';

import '../../core/gate_issue.dart';
import '../../core/json_values.dart';
import '../../data/app_database.dart';

abstract final class ScriptGate {
  ScriptGate._();

  /// 画面动作里的对话引号（中英各一套，含直角引号）。
  static const List<String> _quoteMarkers = ['“', '”', '「', '」', '『', '』', '"'];

  /// 执行全部剧本门。
  static List<GateIssue> validate({required List<Scene> scenes}) {
    return [
      ...hasAction(scenes),
      ...actionProse(scenes),
      ...speakerUnknown(scenes),
    ];
  }

  /// 无画面动作门。
  static List<GateIssue> hasAction(List<Scene> scenes) {
    return [
      for (final scene in scenes)
        if (scene.action.trim().isEmpty)
          GateIssue(
            code: 'has_action',
            severity: GateSeverity.warn,
            locator: sceneLocator(scene),
            message: '场次「${scene.location}」没有画面动作描写，'
                '下游分镜图提示词只剩人物与台词，构图全靠模型猜',
          ),
    ];
  }

  /// 动作字段夹对话引号门。
  static List<GateIssue> actionProse(List<Scene> scenes) {
    return [
      for (final scene in scenes)
        if (_containsAny(scene.action, _quoteMarkers))
          GateIssue(
            code: 'action_prose',
            severity: GateSeverity.warn,
            locator: sceneLocator(scene),
            message: '画面动作字段里出现了对话引号，台词请放进对白列表——'
                '混在动作里会让视频提示词的口型对白块落不到字段上',
          ),
    ];
  }

  /// 说话人越界门。VO/OS 豁免。
  static List<GateIssue> speakerUnknown(List<Scene> scenes) {
    final issues = <GateIssue>[];
    for (final scene in scenes) {
      final cast = _stringList(scene.characters);
      if (cast.isEmpty) continue;
      for (final line in _decodeList(scene.dialogue)) {
        final speaker = jsonString(line['speaker']).trim();
        final type = jsonString(line['type']).trim();
        if (speaker.isEmpty) continue;
        if (type == 'VO' || type == 'OS') continue;
        if (!cast.contains(speaker)) {
          issues.add(
            GateIssue(
              code: 'speaker_unknown',
              severity: GateSeverity.warn,
              locator: sceneLocator(scene),
              message: '说话人「$speaker」不在本场次出场角色 $cast 里'
                  '（VO/OS 豁免）。出场名单错会让分镜图少画一个人',
            ),
          );
        }
      }
    }
    return issues;
  }

  /// 场次定位串，供 UI 与日志使用。
  static String sceneLocator(Scene scene) =>
      '${scene.id} · ${scene.location}';

  static bool _containsAny(String text, List<String> markers) {
    if (text.isEmpty) return false;
    for (final marker in markers) {
      if (text.contains(marker)) return true;
    }
    return false;
  }

  static List<Map<String, dynamic>> _decodeList(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    return [for (final v in decoded) if (v is Map) jsonMap(v)];
  }

  static List<String> _stringList(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    return [
      for (final v in decoded) v.toString().trim(),
    ].where((v) => v.isNotEmpty).toList();
  }
}
