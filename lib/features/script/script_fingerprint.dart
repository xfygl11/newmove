import 'dart:convert';

import '../../data/app_database.dart';

/// 剧本场次指纹（M19 T21.14）。
///
/// 指纹覆盖场次行的全部内容字段，与行 id 无关：同内容不同插入顺序得到同指纹，
/// 场次内容一变指纹就变。
///
/// 它必须覆盖 `Scenes` 表的行而不是 `Scripts.content`：场次编辑走
/// `updateScene` 只写 `Scenes` 表，而提案确认只改 `content` 里的 `proposals`、
/// 不重写场次行，所以不应使下游失效。
///
/// 指纹只用于「是否变化」判断，不参与业务逻辑，因此用 64 位 FNV-1a 而
/// 不引 crypto 依赖。
abstract final class ScriptFingerprint {
  /// 计算场次指纹；场次按 seq 升序参与。
  static String hashOf(List<Scene> scenes) {
    final rows = [...scenes]..sort((a, b) => a.seq.compareTo(b.seq));
    final canonical = jsonEncode([
      for (final s in rows) <String, Object?>{
        'seq': s.seq,
        'location': s.location,
        'time': s.time,
        'characters': s.characters,
        'summary': s.summary,
        'action': s.action,
        'startState': s.startState,
        'endState': s.endState,
        'transition': s.transition,
        'dialogue': s.dialogue,
        'sound': s.sound,
      },
    ]);
    return _fnv1a64(canonical);
  }

  static String _fnv1a64(String input) {
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(input)) {
      hash = ((hash ^ byte) & _mask64) * 0x100000001b3 & _mask64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  static const int _mask64 = 0xFFFFFFFFFFFFFFFF;
}
