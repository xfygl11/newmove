import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/skeleton/beat_gate.dart';

Beat beat({
  int id = 1,
  int seq = 1,
  String sourceRef = 'E01',
  String? weight,
  int? hookBeatId,
}) =>
    Beat(
      id: id,
      sceneId: 1,
      seq: seq,
      type: '动作',
      who: '',
      content: '动作',
      sourceRef: sourceRef,
      estDurationMs: 0,
      tags: '[]',
      weight: weight,
      hookBeatId: hookBeatId,
    );

Shot shot({
  int id = 1,
  String globalSeq = 'G01',
  List<String> beatRefs = const [],
}) =>
    Shot(
      id: id,
      scriptId: 1,
      globalSeq: globalSeq,
      batch: 1,
      durationMs: 10000,
      globalTimeRange: '00:00-00:10',
      beatRefs: _json(beatRefs),
      assetStates: '{}',
      prompt: '',
      status: '待生成',
      outputType: '',
      isStale: 0,
    );

String _json(List<String> refs) {
  final buf = StringBuffer('[');
  buf.write(refs.map((r) => '"$r"').join(','));
  buf.write(']');
  return buf.toString();
}

void main() {
  group('beat_gap 相邻大爆点间隔', () {
    test('无 major 时整门跳过', () {
      final beats = [beat(id: 1, seq: 1), beat(id: 2, seq: 2, weight: 'minor')];
      expect(BeatGate.beatGap(beats), isEmpty);
    });

    test('节拍 < 2 时跳过', () {
      expect(BeatGate.beatGap([beat(id: 1, seq: 1, weight: 'major')]), isEmpty);
    });

    test('相邻 major 间隔超阈值报警', () {
      final beats = [
        beat(id: 1, seq: 1, weight: 'major', sourceRef: 'E01'),
        beat(id: 2, seq: 14, weight: 'major', sourceRef: 'E14'),
      ];
      final issues = BeatGate.beatGap(beats, maxMajorGap: 12);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'beat_gap');
    });

    test('间隔在阈值内不报警', () {
      final beats = [
        beat(id: 1, seq: 1, weight: 'major', sourceRef: 'E01'),
        beat(id: 2, seq: 13, weight: 'major', sourceRef: 'E13'),
      ];
      expect(BeatGate.beatGap(beats, maxMajorGap: 12), isEmpty);
    });

    test('开头真空：首个 major 位置超阈值', () {
      final beats = [
        for (var i = 1; i <= 20; i++) beat(id: i, seq: i, sourceRef: 'E$i'),
      ];
      // 只有一个 major 在第 20 拍，开头 19 拍真空。
      beats[19] = beat(id: 20, seq: 20, sourceRef: 'E20', weight: 'major');
      final issues = BeatGate.beatGap(beats, maxMajorGap: 12);
      expect(issues.any((i) => i.code == 'beat_gap'), isTrue);
    });

    test('结尾真空：最后 major 之后超阈值', () {
      final beats = [
        for (var i = 1; i <= 20; i++) beat(id: i, seq: i, sourceRef: 'E$i'),
      ];
      beats[0] = beat(id: 1, seq: 1, sourceRef: 'E01', weight: 'major');
      final issues = BeatGate.beatGap(beats, maxMajorGap: 12);
      expect(issues.any((i) => i.code == 'beat_gap'), isTrue);
    });
  });

  group('major_early 首个大爆点位置', () {
    test('首个 major 落在末段报警', () {
      final beats = [
        beat(id: 1, seq: 1, sourceRef: 'E01'),
        beat(id: 2, seq: 2, sourceRef: 'E02', weight: 'major'),
      ];
      final shots = [
        shot(id: 1, globalSeq: 'G01', beatRefs: ['E01']),
        shot(id: 2, globalSeq: 'G02', beatRefs: ['E02']),
      ];
      final issues = BeatGate.majorEarly(beats, shots);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'major_early');
    });

    test('首个 major 不在末段不报警', () {
      final beats = [
        beat(id: 1, seq: 1, sourceRef: 'E01', weight: 'major'),
        beat(id: 2, seq: 2, sourceRef: 'E02'),
      ];
      final shots = [
        shot(id: 1, globalSeq: 'G01', beatRefs: ['E01']),
        shot(id: 2, globalSeq: 'G02', beatRefs: ['E02']),
      ];
      expect(BeatGate.majorEarly(beats, shots), isEmpty);
    });

    test('无 major 或无分段时跳过', () {
      expect(BeatGate.majorEarly([beat(id: 1, seq: 1)], []), isEmpty);
      expect(BeatGate.majorEarly([], [shot()]), isEmpty);
    });
  });

  group('hook_orphan 钩子兑现引用', () {
    test('hookBeatId 引用不存在的节拍报警', () {
      final beats = [
        beat(id: 1, seq: 1, sourceRef: 'E01', hookBeatId: 999),
      ];
      final issues = BeatGate.hookOrphan(beats);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'hook_orphan');
    });

    test('hookBeatId 引用存在的节拍不报警', () {
      final beats = [
        beat(id: 1, seq: 1, sourceRef: 'E01'),
        beat(id: 2, seq: 2, sourceRef: 'E02', hookBeatId: 1),
      ];
      expect(BeatGate.hookOrphan(beats), isEmpty);
    });

    test('hookBeatId 为空不报警', () {
      expect(BeatGate.hookOrphan([beat(id: 1, seq: 1)]), isEmpty);
    });
  });

  group('validate 汇总', () {
    test('多门同时命中', () {
      final beats = [
        beat(id: 1, seq: 1, sourceRef: 'E01'),
        beat(id: 2, seq: 20, sourceRef: 'E20', weight: 'major', hookBeatId: 99),
      ];
      final shots = [
        shot(id: 1, globalSeq: 'G01', beatRefs: ['E01']),
        shot(id: 2, globalSeq: 'G02', beatRefs: ['E20']),
      ];
      final issues = BeatGate.validate(beats: beats, shots: shots);
      final codes = issues.map((i) => i.code).toSet();
      expect(codes, contains('major_early'));
      expect(codes, contains('hook_orphan'));
    });
  });
}
