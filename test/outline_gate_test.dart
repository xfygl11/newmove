import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/features/novel/novel_models.dart';
import 'package:newmove/features/novel/outline_gate.dart';

void main() {
  OutlineScene scene(String name, {bool primary = false, List<int> occ = const [], String avoid = ''}) =>
      OutlineScene(name: name, isPrimary: primary, occurrences: occ, onceAvoidance: avoid);

  OutlineProp prop(String name, {bool narrative = false}) =>
      OutlineProp(name: name, isNarrative: narrative);

  group('scene_cap 主场景上限', () {
    test('主场景超上限报警，公式 4+⌈集数/10⌉ 夹 5–15', () {
      // 10 集 → 上限 5。6 个主场景超限。
      final scenes = [
        for (var i = 0; i < 6; i++) scene('景$i', primary: true),
      ];
      final issues = OutlineGate.sceneCap(scenes, 10);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'scene_cap');
      expect(issues.first.message, contains('超过上限 5'));
    });

    test('主场景未超上限不报警', () {
      final scenes = [
        for (var i = 0; i < 5; i++) scene('景$i', primary: true),
      ];
      expect(OutlineGate.sceneCap(scenes, 10), isEmpty);
    });

    test('episodeCount 为 0 跳过（缺数据照常通过）', () {
      final scenes = [
        for (var i = 0; i < 20; i++) scene('景$i', primary: true),
      ];
      expect(OutlineGate.sceneCap(scenes, 0), isEmpty);
    });

    test('非主场景不计入上限', () {
      final scenes = [
        for (var i = 0; i < 20; i++) scene('景$i'),
      ];
      expect(OutlineGate.sceneCap(scenes, 10), isEmpty);
    });
  });

  group('maxScenes 公式边界', () {
    test('夹在 5–15', () {
      expect(OutlineGate.maxScenes(1), 5); // 4+1=5
      expect(OutlineGate.maxScenes(6), 5); // 4+1=5 夹到 5
      expect(OutlineGate.maxScenes(10), 5); // 4+1=5
      expect(OutlineGate.maxScenes(11), 6); // 4+2=6
      expect(OutlineGate.maxScenes(60), 10); // 4+6=10
      expect(OutlineGate.maxScenes(200), 15); // 4+20=24 夹到 15
    });
  });

  group('once_scene 一次性场景', () {
    test('只出现一次且无规避方案报警', () {
      final issues = OutlineGate.onceScene([
        scene('废弃医院', occ: [3]),
      ]);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'once_scene');
      expect(issues.first.locator, '废弃医院');
    });

    test('有规避方案不报警', () {
      final issues = OutlineGate.onceScene([
        scene('废弃医院', occ: [3], avoid: '复用营地废墟，改夜景雾天'),
      ]);
      expect(issues, isEmpty);
    });

    test('出现多次不算一次性场景', () {
      final issues = OutlineGate.onceScene([
        scene('营地', occ: [1, 2, 4]),
      ]);
      expect(issues, isEmpty);
    });

    test('无出现清单不算一次性场景（缺数据跳过）', () {
      final issues = OutlineGate.onceScene([scene('营地')]);
      expect(issues, isEmpty);
    });
  });

  group('prop_cap 叙事道具上限', () {
    test('叙事道具超 8 件报警', () {
      final props = [
        for (var i = 0; i < 9; i++) prop('道具$i', narrative: true),
      ];
      final issues = OutlineGate.propCap(props);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'prop_cap');
      expect(issues.first.message, contains('超过上限 8'));
    });

    test('叙事道具 8 件内不报警', () {
      final props = [
        for (var i = 0; i < 8; i++) prop('道具$i', narrative: true),
      ];
      expect(OutlineGate.propCap(props), isEmpty);
    });

    test('场景陈设（非叙事道具）不计入', () {
      final props = [
        for (var i = 0; i < 20; i++) prop('陈设$i'),
      ];
      expect(OutlineGate.propCap(props), isEmpty);
    });

    test('道具清单为空跳过', () {
      expect(OutlineGate.propCap(const []), isEmpty);
    });
  });

  group('validate 汇总', () {
    test('多门同时命中', () {
      final scenes = [
        for (var i = 0; i < 6; i++) scene('主景$i', primary: true),
        scene('一次性', occ: [5]),
      ];
      final props = [
        for (var i = 0; i < 9; i++) prop('道具$i', narrative: true),
      ];
      final issues = OutlineGate.validate(
        scenes: scenes,
        props: props,
        episodeCount: 10,
      );
      final codes = issues.map((i) => i.code).toSet();
      expect(codes, containsAll(['scene_cap', 'once_scene', 'prop_cap']));
    });
  });

  group('SetupResult 解析 outlineStructure', () {
    test('fromJson 解析结构化场景与道具', () {
      final result = SetupResult.fromJson({
        'premise': 'p',
        'world': 'w',
        'characters': [],
        'styleGuide': 's',
        'outline': '第 1 章 觉醒',
        'proposals': [],
        'outlineStructure': {
          'scenes': [
            {'name': '营地', 'isPrimary': true, 'occurrences': [1, 2], 'onceAvoidance': ''},
            {'name': '医院', 'isPrimary': false, 'occurrences': ['3'], 'onceAvoidance': '复用营地'},
          ],
          'props': [
            {'name': '药剂', 'isNarrative': 'true'},
            {'name': '桌子', 'isNarrative': false},
          ],
        },
      });
      expect(result.outlineScenes, hasLength(2));
      expect(result.outlineScenes.first.isPrimary, isTrue);
      expect(result.outlineScenes.first.occurrences, [1, 2]);
      // occurrences 里的字符串 "3" 宽容转为 int。
      expect(result.outlineScenes.last.occurrences, [3]);
      expect(result.outlineProps, hasLength(2));
      expect(result.outlineProps.first.isNarrative, isTrue);
    });

    test('缺 outlineStructure 字段时清单为空', () {
      final result = SetupResult.fromJson({
        'premise': 'p',
        'world': 'w',
        'characters': [],
        'styleGuide': 's',
        'outline': '',
        'proposals': [],
      });
      expect(result.outlineScenes, isEmpty);
      expect(result.outlineProps, isEmpty);
    });
  });
}
