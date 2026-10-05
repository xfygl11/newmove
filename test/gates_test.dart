// 本地质量门测试：剧本时长门（M19 T21.2/T21.3）+ 资产提示词门（T21.1/T21.4/T21.5）。
// 门都是纯函数，直接构造实体，不走数据库。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/asset/prompt_gate.dart';
import 'package:newmove/features/script/duration_gate.dart';

Beat beat({
  int id = 1,
  int sceneId = 1,
  int seq = 1,
  String type = '对白',
  String who = '',
  String content = '',
  String sourceRef = '',
  int estDurationMs = 0,
  String tags = '[]',
}) =>
    Beat(
      id: id,
      sceneId: sceneId,
      seq: seq,
      type: type,
      who: who,
      content: content,
      sourceRef: sourceRef,
      estDurationMs: estDurationMs,
      tags: tags,
    );

Asset asset({
  int id = 1,
  int scriptId = 1,
  String type = '角色',
  String name = '角色',
  String prompt = '',
  String? appearanceAnchor,
  String boardLayout = '四视图',
  String status = '待生成',
  int? heightCm,
  String? bodyType,
  String? costumeSets,
  int isStale = 0,
}) =>
    Asset(
      id: id,
      scriptId: scriptId,
      type: type,
      name: name,
      stableId: 'stable-$id',
      appearanceAnchor: appearanceAnchor,
      heightCm: heightCm,
      bodyType: bodyType,
      costumeSets: costumeSets,
      boardLayout: boardLayout,
      prompt: prompt,
      status: status,
      isStale: isStale,
    );

Scene scene({int id = 1, int scriptId = 1, int seq = 1, String dialogue = '[]'}) =>
    Scene(
      id: id,
      scriptId: scriptId,
      seq: seq,
      location: '',
      time: '',
      characters: '[]',
      action: '',
      dialogue: dialogue,
      sound: '{}',
    );

void main() {
  group('DurationGate 字符与秒数', () {
    test('去空白，标点算时间', () {
      expect(DurationGate.lineChars('你好，世界！'), 6);
      expect(DurationGate.lineChars('你 好， 世界'), 5);
      expect(DurationGate.lineChars(''), 0);
      expect(DurationGate.lineChars(null), 0);
    });

    test('lineSeconds 保留一位小数', () {
      expect(DurationGate.lineSeconds('你好世界'), 0.9);
      expect(DurationGate.lineSeconds('字' * 45), 10.0);
      expect(DurationGate.lineSeconds(''), 0);
    });

    test('常量单一来源', () {
      expect(DurationGate.charsPerSecond, 4.5);
      expect(DurationGate.actionSeconds, 2.5);
      expect(DurationGate.totalTolerance, 0.15);
      expect(DurationGate.maxLineChars, 35);
    });
  });

  group('DurationGate dialogueLines', () {
    test('按顺序取非空台词，丢弃空句与非对象条目', () {
      final dialogue = jsonEncode([
        {'speaker': '佐藤', 'type': '对白', 'text': '走吧。'},
        {'speaker': '', 'type': '对白', 'text': ''},
        {'speaker': '旁白', 'type': 'VO', 'text': '夜色很深'},
        {'speaker': '白', 'type': 'OS', 'text': '   '},
        'not-an-object',
        {'speaker': '黑', 'type': '对白'},
      ]);
      expect(DurationGate.dialogueLines(scene(dialogue: dialogue)), ['走吧。', '夜色很深']);
    });

    test('坏 JSON 与空串收敛为空列表', () {
      expect(DurationGate.dialogueLines(scene(dialogue: 'not json')), isEmpty);
      expect(DurationGate.dialogueLines(scene(dialogue: '')), isEmpty);
      expect(DurationGate.dialogueLines(scene(dialogue: '{}')), isEmpty);
    });
  });

  group('DurationGate 节拍估算', () {
    test('对白按字符折算，不采信 estDurationMs', () {
      expect(DurationGate.beatSeconds(beat(content: '你好世界', estDurationMs: 999999)), 0.9);
    });

    test('非对白节拍用 estDurationMs，为 0 时回落 2.5s', () {
      expect(DurationGate.beatSeconds(beat(type: '动作', estDurationMs: 6000)), 6.0);
      expect(DurationGate.beatSeconds(beat(type: '动作')), 2.5);
      expect(DurationGate.beatSeconds(beat(type: '留白', estDurationMs: 0)), 2.5);
    });

    test('beatsSeconds 累加并保留一位小数', () {
      final beats = [
        beat(id: 1, type: '动作', estDurationMs: 6000),
        beat(id: 2, type: '对白', content: '你好世界'),
        beat(id: 3, type: '动作'),
      ];
      expect(DurationGate.beatsSeconds(beats), 9.4);
    });
  });

  group('DurationGate 单句台词门', () {
    test('上限内通过', () {
      expect(DurationGate.longLinesOfScenes([scene(dialogue: jsonEncode([
        {'speaker': 'a', 'type': '对白', 'text': '字' * 35},
      ]))]), isEmpty);
    });

    test('超长报警并点名场次', () {
      final issues = DurationGate.longLinesOfScenes([
        scene(id: 7, seq: 3, dialogue: jsonEncode([
          {'speaker': 'a', 'type': '对白', 'text': '走。'},
          {'speaker': 'b', 'type': '对白', 'text': '字' * 40},
        ])),
      ]);
      expect(issues, hasLength(1));
      expect(issues.single.code, 'line_too_long');
      expect(issues.single.isError, isTrue);
      expect(issues.single.locator, 'S3');
      expect(issues.single.message, contains('第 2 句'));
      expect(issues.single.message, contains('40 字'));
    });

    test('节拍来源同样判定，缺 sourceRef 回落场次号', () {
      final issues = DurationGate.longLinesOfBeats([
        beat(content: '字' * 35),
        beat(id: 1, content: '字' * 36),
        beat(id: 2, type: '动作', content: '字' * 50),
        beat(id: 3, content: '字' * 36, sourceRef: 'E07'),
      ]);
      expect(issues.map((i) => i.locator), ['S1', 'E07']);
    });
  });

  group('DurationGate 总时长门', () {
    test('目标为 0 时跳过', () {
      expect(
        DurationGate.totalBudgetOfBeats([beat(type: '动作', estDurationMs: 1)], 0),
        isEmpty,
      );
      expect(
        DurationGate.totalBudgetOfBeats([], -1),
        isEmpty,
      );
    });

    test('容差内通过', () {
      final beats = [
        for (var i = 0; i < 3; i++) beat(id: i + 1, type: '动作', estDurationMs: 20000),
      ];
      expect(DurationGate.totalBudgetOfBeats(beats, 60000), isEmpty);
      expect(DurationGate.totalBudgetOfBeats(beats, 63000), isEmpty);
    });

    test('超预算与欠预算分别报码', () {
      final over = DurationGate.totalBudgetOfBeats([
        for (var i = 0; i < 3; i++) beat(id: i + 1, type: '动作', estDurationMs: 25000),
      ], 60000);
      expect(over.single.code, 'total_over_budget');
      expect(over.single.isError, isFalse);

      final under = DurationGate.totalBudgetOfBeats([
        for (var i = 0; i < 4; i++) beat(id: i + 1, type: '动作', estDurationMs: 10000),
      ], 60000);
      expect(under.single.code, 'total_under_budget');
    });

    test('validate 合并单句与总量', () {
      final issues = DurationGate.validate(
        beats: [
          beat(id: 1, content: '字' * 50),
          beat(id: 2, type: '动作', estDurationMs: 25000),
        ],
        targetDurationMs: 30000,
      );
      expect(issues.map((i) => i.code), containsAll(['line_too_long', 'total_over_budget']));
    });
  });

  group('PromptGate jaccard 与分词', () {
    test('相同文本为 1，无关文本为 0', () {
      expect(PromptGate.jaccard('甲乙丙丁戊己庚辛壬癸', '甲乙丙丁戊己庚辛壬癸'), 1.0);
      expect(PromptGate.jaccard('甲乙丙丁戊己庚辛壬癸', '子丑寅卯辰巳午未申酉'), 0);
    });

    test('词元数不足阈值返回 0', () {
      expect(PromptGate.jaccard('甲乙', '甲乙'), 0);
      expect(PromptGate.jaccard('甲乙丙丁戊', '甲乙丙丁戊'), 0);
      expect(PromptGate.jaccard('甲乙丙丁戊己庚', '甲乙丙丁戊己庚辛'), greaterThan(0));
    });

    test('CJK 逐字分词，连续的字母数字串算一个词元', () {
      final tokens = PromptGate.tokens('黑短发 Black a 1 校服');
      expect(tokens.contains('黑'), isTrue);
      expect(tokens.contains('短发'), isFalse);
      expect(tokens.contains('black'), isTrue);
      expect(tokens.contains('校服'), isFalse);
      expect(tokens.contains('a'), isFalse);
      expect(tokens.contains('1'), isFalse);
    });

    test('jaccard 对区分良好与近克隆角色给出可分档的结果', () {
      final a = PromptGate.descriptorOf(
        asset(name: '佐藤', appearanceAnchor: _anchor('16', '女', '黑色短发齐刘海', '蓝白校服', '左手腕胎记')),
      );
      final b = PromptGate.descriptorOf(
        asset(id: 2, name: '阿青', appearanceAnchor: _anchor('17', '女', '黑色短发齐刘海', '蓝白校服', '右手腕胎记')),
      );
      final c = PromptGate.descriptorOf(
        asset(id: 3, name: '老周', appearanceAnchor: _anchor('35', '男', '花白短须', '青灰长袍', '右眉旧疤')),
      );
      expect(PromptGate.jaccard(a, b), greaterThanOrEqualTo(0.75));
      expect(PromptGate.jaccard(a, c), lessThan(0.2));
    });
  });

  group('PromptGate descriptorOf', () {
    test('空锚点返回空串', () {
      expect(PromptGate.descriptorOf(asset()), '');
      expect(PromptGate.descriptorOf(asset(appearanceAnchor: null)), '');
      expect(PromptGate.descriptorOf(asset(appearanceAnchor: '   ')), '');
    });

    test('JSON 对象按值顺序拼接', () {
      expect(
        PromptGate.descriptorOf(asset(appearanceAnchor: _anchor('16', '女', '黑发', '校服', '胎记'))),
        '16 女 黑发 校服 胎记',
      );
    });

    test('非 JSON 与坏 JSON 回落原文，不抛异常', () {
      expect(PromptGate.descriptorOf(asset(appearanceAnchor: '黑发校服')), '黑发校服');
      expect(PromptGate.descriptorOf(asset(appearanceAnchor: '[1,2]')), '[1,2]');
    });
  });

  group('PromptGate 雷同门', () {
    test('雷同角色报警并点名双方', () {
      final issues = PromptGate.similarCharacters([
        asset(id: 1, name: '佐藤', appearanceAnchor: _anchor('16', '女', '黑色短发齐刘海', '蓝白校服', '左手腕胎记')),
        asset(id: 2, name: '阿青', appearanceAnchor: _anchor('17', '女', '黑色短发齐刘海', '蓝白校服', '右手腕胎记')),
        asset(id: 3, name: '老周', appearanceAnchor: _anchor('35', '男', '花白短须', '青灰长袍', '右眉旧疤')),
      ]);
      expect(issues, hasLength(1));
      expect(issues.single.code, 'prompt_similar');
      expect(issues.single.locator, '佐藤 / 阿青');
      expect(issues.single.message, contains('80.0'));
    });

    test('区分良好不报警', () {
      final issues = PromptGate.similarCharacters([
        asset(id: 1, name: '佐藤', appearanceAnchor: _anchor('16', '女', '黑色短发齐刘海', '蓝白校服', '左手腕胎记')),
        asset(id: 2, name: '老周', appearanceAnchor: _anchor('35', '男', '花白短须', '青灰长袍', '右眉旧疤')),
        asset(id: 3, name: '小豆', appearanceAnchor: _anchor('8', '男', '光头', '红布肚兜', '额头月牙胎记')),
      ]);
      expect(issues, isEmpty);
    });

    test('只查角色，空锚点与变体不参与', () {
      final issues = PromptGate.similarCharacters([
        asset(id: 1, type: '场景', name: '教室', appearanceAnchor: _anchor('16', '女', '黑色短发齐刘海', '蓝白校服', '左手腕胎记')),
        asset(id: 2, name: '空锚点'),
        asset(id: 3, name: '坏锚点', appearanceAnchor: 'abc'),
      ]);
      expect(issues, isEmpty);
    });
  });

  group('PromptGate 空景与无手门', () {
    test('场景有空景表述通过', () {
      expect(
        PromptGate.emptyScene([asset(type: '场景', name: '教室', prompt: '一间空教室，无人物、无人影')]),
        isEmpty,
      );
      expect(
        PromptGate.emptyScene([asset(type: '场景', name: '教室', prompt: 'empty scene, no people')]),
        isEmpty,
      );
    });

    test('场景没有空景表述报警', () {
      final issues = PromptGate.emptyScene([asset(type: '场景', name: '教室', prompt: '一间明亮的教室')]);
      expect(issues.single.code, 'scene_not_empty');
      expect(issues.single.isError, isTrue);
      expect(issues.single.locator, '教室');
    });

    test('道具须同时有空景与手部排除', () {
      final ok = PromptGate.emptyScene([
        asset(type: '道具', name: '怀表', prompt: '一块旧怀表，无人物、手部、额外物件'),
      ]);
      expect(ok, isEmpty);

      final missingHand = PromptGate.emptyScene([
        asset(type: '道具', name: '怀表', prompt: '一块旧怀表，无人物'),
      ]);
      expect(missingHand.map((i) => i.code), ['prop_has_hand']);

      final missingBoth = PromptGate.emptyScene([
        asset(type: '道具', name: '怀表', prompt: '一块旧怀表'),
      ]);
      expect(missingBoth.map((i) => i.code), ['scene_not_empty', 'prop_has_hand']);
    });

    test('角色类资产跳过', () {
      expect(
        PromptGate.emptyScene([asset(type: '角色', name: '佐藤', prompt: '一个女孩站在教室')]),
        isEmpty,
      );
    });
  });

  group('PromptGate 场景出现角色名门', () {
    test('场景提示词出现角色名报警', () {
      final issues = PromptGate.namedCharactersInScene(
        assets: [asset(type: '场景', name: '教室', prompt: '佐藤常坐的座位，黑板与桌椅')],
        characterNames: ['佐藤', '老周'],
      );
      expect(issues.single.code, 'scene_named_character');
      expect(issues.single.message, contains('佐藤'));
    });

    test('否定语境不报警', () {
      final issues = PromptGate.namedCharactersInScene(
        assets: [
          asset(type: '场景', name: '教室', prompt: '教室一角，画面不出现佐藤'),
        ],
        characterNames: ['佐藤'],
      );
      expect(issues, isEmpty);
    });

    test('角色名为空、非场景资产、无命中都不报警', () {
      expect(
        PromptGate.namedCharactersInScene(assets: [asset(type: '场景', name: 'a')], characterNames: []),
        isEmpty,
      );
      expect(
        PromptGate.namedCharactersInScene(
          assets: [asset(type: '角色', name: 'a', prompt: '佐藤')],
          characterNames: ['佐藤'],
        ),
        isEmpty,
      );
      expect(
        PromptGate.namedCharactersInScene(
          assets: [asset(type: '场景', name: 'a', prompt: '空教室')],
          characterNames: ['  ', '佐藤'],
        ),
        isEmpty,
      );
    });
  });

  group('PromptGate 画风互斥门', () {
    test('同族不报警', () {
      final assets = [
        asset(id: 1, name: '教室', prompt: '日式 2D 动画，干净线稿，柔和上色，一间空教室，无人物'),
        asset(id: 2, name: '走廊', prompt: '日式 2D 动画，干净线稿，柔和上色，走廊，无人物'),
      ];
      expect(PromptGate.styleConflicts(assets), isEmpty);
    });

    test('跨族报警并列出族与归属', () {
      final issues = PromptGate.styleConflicts([
        asset(id: 1, name: '教室', prompt: '日式 2D 动画，干净线稿，一间空教室，无人物'),
        asset(id: 2, name: '怀表', prompt: 'photorealistic product render，一块旧怀表，无人物，手部'),
      ]);
      expect(issues.single.code, 'style_conflict');
      expect(issues.single.locator, contains('动漫'));
      expect(issues.single.locator, contains('写实'));
    });

    test('未命中画风词不报警', () {
      expect(
        PromptGate.styleConflicts([
          asset(id: 1, name: 'a', prompt: '一间空教室，无人物'),
          asset(id: 2, name: 'b', prompt: '一块旧怀表，无人物，手部'),
        ]),
        isEmpty,
      );
    });
  });

  group('PromptGate validate 汇总', () {
    test('多条门结果合并输出', () {
      final issues = PromptGate.validate(
        assets: [
          asset(id: 1, type: '场景', name: '教室', prompt: '日式 2D 动画，佐藤的座位'),
          asset(id: 2, type: '道具', name: '怀表', prompt: 'photorealistic，一块旧怀表'),
          asset(id: 3, name: '佐藤', appearanceAnchor: _anchor('16', '女', '黑色短发齐刘海', '蓝白校服', '左手腕胎记')),
          asset(id: 4, name: '阿青', appearanceAnchor: _anchor('17', '女', '黑色短发齐刘海', '蓝白校服', '右手腕胎记')),
        ],
        characterNames: ['佐藤'],
      );
      expect(issues.map((i) => i.code), containsAll([
        'scene_not_empty',
        'prop_has_hand',
        'scene_not_empty',
        'scene_named_character',
        'style_conflict',
        'prompt_similar',
      ]));
      expect(issues.first.noteLine, startsWith('['));
    });
  });
}

/// 拼出真实项目里常见的 5 字段外观锚点 JSON。
String _anchor(String age, String gender, String hair, String outfit, String key) =>
    jsonEncode({
      'age': age,
      'gender': gender,
      'hair': hair,
      'outfit': outfit,
      'key': key,
    });
