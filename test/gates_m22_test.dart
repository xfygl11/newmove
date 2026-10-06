// M22 T23.x 本地质量门：PromptGate 五条新门 + ShotGate 五条 +
// ScriptGate 三条 + SkeletonGate.coverage。
// 门都是纯函数，直接构造实体，不走数据库。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/asset/prompt_gate.dart';
import 'package:newmove/features/script/script_gate.dart';
import 'package:newmove/features/skeleton/skeleton_gate.dart';
import 'package:newmove/features/shot/shot_gate.dart';

Asset asset({
  int id = 1,
  int scriptId = 1,
  String type = '角色',
  String name = '佐藤',
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

Shot shot({
  int id = 1,
  int scriptId = 1,
  String globalSeq = 'G01',
  int batch = 1,
  int durationMs = 8000,
  String globalTimeRange = '00:00-00:08',
  String beatRefs = '[]',
  String assetStates = '{}',
  String? shotType,
  String prompt = '',
  String status = '待提示词',
  String outputType = 'image',
  int isStale = 0,
}) =>
    Shot(
      id: id,
      scriptId: scriptId,
      globalSeq: globalSeq,
      batch: batch,
      modelVersion: null,
      durationMs: durationMs,
      globalTimeRange: globalTimeRange,
      beatRefs: beatRefs,
      assetStates: assetStates,
      shotType: shotType,
      composition: null,
      lens: null,
      cameraPosition: null,
      eyeline: null,
      focus: null,
      stability: null,
      blocking: null,
      dialogueStartRatio: null,
      dialogueEndRatio: null,
      costumeOverrides: null,
      sceneId: null,
      prompt: prompt,
      status: status,
      outputPath: null,
      outputType: outputType,
      isStale: isStale,
    );

ShotFrame frame({
  int id = 1,
  int shotId = 1,
  int seq = 1,
  String timeRange = '00:00-00:04',
  String subject = '佐藤',
  String shotSize = '中景',
  String angle = '平视',
  String camera = '',
  String blocking = '',
  String performance = '',
  String? dialogue,
}) =>
    ShotFrame(
      id: id,
      shotId: shotId,
      seq: seq,
      timeRange: timeRange,
      subject: subject,
      shotSize: shotSize,
      angle: angle,
      camera: camera,
      blocking: blocking,
      performance: performance,
      dialogue: dialogue,
    );

Beat beat({
  int id = 1,
  int sceneId = 1,
  int seq = 1,
  String type = '动作',
  String who = '',
  String content = '起身',
  String? object,
  String sourceRef = 'E01',
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
      object: object,
      sourceRef: sourceRef,
      estDurationMs: estDurationMs,
      tags: tags,
    );

Scene scene({
  int id = 1,
  int scriptId = 1,
  int seq = 1,
  String location = '教室',
  String time = '白天',
  String characters = '[]',
  String? summary = '相遇',
  String action = '',
  String? startState,
  String? endState,
  String? transition,
  String dialogue = '[]',
  String sound = '{}',
}) =>
    Scene(
      id: id,
      scriptId: scriptId,
      seq: seq,
      location: location,
      time: time,
      characters: characters,
      summary: summary,
      action: action,
      startState: startState,
      endState: endState,
      transition: transition,
      dialogue: dialogue,
      sound: sound,
    );

/// 真实项目里常见的 5 字段外观锚点。
String anchor(List<String> fields) => jsonEncode({
  'age': fields[0],
  'gender': fields[1],
  'hair': fields[2],
  'outfit': fields[3],
  if (fields.length > 4) 'key': fields[4],
});

void main() {
  group('PromptGate anchor_count', () {
    test('3-5 个字段通过', () {
      expect(
        PromptGate.anchorCountGate([
          asset(appearanceAnchor: anchor(['16', '女', '黑发', '校服', '胎记'])),
          asset(
            id: 2,
            appearanceAnchor: jsonEncode({'hair': '黑发', 'outfit': '校服', 'key': '胎记'}),
          ),
        ]),
        isEmpty,
      );
    });

    test('字段不足 3 个报警', () {
      final issues = PromptGate.anchorCountGate([
        asset(appearanceAnchor: jsonEncode({'hair': '黑发', 'outfit': '校服'})),
      ]);
      expect(issues.single.code, 'anchor_count');
      expect(issues.single.message, contains('2 个字段'));
    });

    test('字段超过 5 个报警', () {
      final issues = PromptGate.anchorCountGate([
        asset(
          appearanceAnchor: jsonEncode({
            'age': '16', 'gender': '女', 'hair': '黑发', 'outfit': '校服',
            'key': '胎记', 'extra': '多余字段',
          }),
        ),
      ]);
      expect(issues.single.code, 'anchor_count');
      expect(issues.single.message, contains('6 个字段'));
    });

    test('空锚点与坏 JSON 跳过，不误报', () {
      expect(
        PromptGate.anchorCountGate([
          asset(),
          asset(id: 2, appearanceAnchor: null),
          asset(id: 3, appearanceAnchor: 'abc'),
        ]),
        isEmpty,
      );
    });

    test('三种资产类型都检查', () {
      expect(
        PromptGate.anchorCountGate([
          asset(type: '场景', appearanceAnchor: jsonEncode({'a': '1'})),
          asset(id: 2, type: '道具', appearanceAnchor: jsonEncode({'a': '1'})),
        ]),
        hasLength(2),
      );
      expect(
        PromptGate.anchorCountGate([
          asset(type: '角色', appearanceAnchor: jsonEncode({'a': '1'})),
        ]),
        hasLength(1),
      );
    });
  });

  group('PromptGate lighting_missing', () {
    test('prompt 或锚点任一处有光照描述都通过', () {
      expect(
        PromptGate.lightingMissing([
          asset(
            prompt: '角色参考板，侧逆光',
            appearanceAnchor: jsonEncode({'hair': '黑发', 'outfit': '校服'}),
          ),
          asset(
            id: 2,
            type: '场景',
            prompt: '一间教室',
            appearanceAnchor: jsonEncode({
              'location': '教室', 'time': '黄昏', 'lighting': '环境光', 'key': '木桌',
            }),
          ),
          asset(
            id: 3,
            appearanceAnchor: jsonEncode({'hair': '黑发', 'outfit': '校服', 'lighting': 'rim light source'}),
          ),
        ]),
        isEmpty,
      );
    });

    test('两处都没有光照描述报警', () {
      final issues = PromptGate.lightingMissing([
        asset(
          prompt: '角色参考板',
          appearanceAnchor: anchor(['16', '女', '黑发', '校服', '胎记']),
        ),
      ]);
      expect(issues.single.code, 'lighting_missing');
      expect(issues.single.locator, '佐藤');
    });

    test('三种资产类型都检查', () {
      final issues = PromptGate.lightingMissing([
        asset(type: '场景', prompt: '一间教室'),
        asset(id: 2, type: '道具', prompt: '一块旧怀表'),
      ]);
      expect(issues, hasLength(2));
      expect(issues.every((i) => i.code == 'lighting_missing'), isTrue);
    });
  });

  group('PromptGate prop_states / prop_scale / prop_white_bg', () {
    test('道具描述齐全且提示词有白底通过', () {
      final prop = asset(
        type: '道具',
        name: '怀表',
        prompt: '一块旧怀表，white background，无人物，手部',
        appearanceAnchor: jsonEncode({
          'state': '正常', 'size': '掌心大小', 'material': '黄铜',
        }),
      );
      expect(PromptGate.propStates([prop]), isEmpty);
      expect(PromptGate.propScale([prop]), isEmpty);
      expect(PromptGate.propWhiteBg([prop]), isEmpty);
    });

    test('三扇门各自只报自己的码', () {
      final issues = PromptGate.validate(assets: [
        asset(
          type: '道具',
          name: '怀表',
          prompt: '一块旧怀表',
          appearanceAnchor: jsonEncode({'material': '黄铜'}),
        ),
      ]);
      expect(
        issues.map((i) => i.code).toSet(),
        {'anchor_count', 'lighting_missing', 'prop_states', 'prop_scale',
          'prop_white_bg', 'scene_not_empty', 'prop_has_hand'},
      );
    });

    test('状态与尺度两处都算，白底只查 prompt', () {
      final promptOnly = asset(
        type: '道具',
        name: '怀表',
        prompt: '一块旧怀表，正常状态，掌心大小，白色背景，无人物，手部',
        appearanceAnchor: jsonEncode({'material': '黄铜'}),
      );
      expect(PromptGate.propStates([promptOnly]), isEmpty);
      expect(PromptGate.propScale([promptOnly]), isEmpty);
      expect(PromptGate.propWhiteBg([promptOnly]), isEmpty);

      final anchorOnly = asset(
        type: '道具',
        name: '怀表',
        prompt: '一块旧怀表',
        appearanceAnchor: jsonEncode({'state': '破损', 'size': '10 厘米'}),
      );
      expect(PromptGate.propStates([anchorOnly]), isEmpty);
      expect(PromptGate.propScale([anchorOnly]), isEmpty);
      expect(PromptGate.propWhiteBg([anchorOnly]), hasLength(1));
    });

    test('角色与场景资产不参与道具门', () {
      expect(PromptGate.propStates([asset()]), isEmpty);
      expect(PromptGate.propScale([asset(type: '场景')]), isEmpty);
      expect(PromptGate.propWhiteBg([asset()]), isEmpty);
    });
  });

  group('ShotGate crowd_check', () {
    test('超过上限报警', () {
      final s = shot(
        assetStates: jsonEncode({
          'characters': [
            for (var i = 0; i < 4; i++) {'name': '角色$i', 'timeline': []},
          ],
        }),
      );
      final issues = ShotGate.crowdCheck([s]);
      expect(issues.single.code, 'crowd_check');
      expect(issues.single.message, contains('4 人'));
      expect(issues.single.locator, 'G01');
    });

    test('上限内通过，坏 JSON 按未指定处理', () {
      expect(
        ShotGate.crowdCheck([
          shot(
            assetStates: jsonEncode({
              'characters': [
                {'name': '佐藤', 'timeline': []},
                {'name': '老周', 'timeline': []},
                {'name': '小豆', 'timeline': []},
              ],
            }),
          ),
          shot(id: 2, globalSeq: 'G02', assetStates: 'abc'),
          shot(id: 3, globalSeq: 'G03', assetStates: '{}'),
        ]),
        isEmpty,
      );
    });
  });

  group('ShotGate segmentSeq', () {
    test('格式错误报警', () {
      final issues = ShotGate.segmentSeq([
        shot(globalSeq: 'g1'),
        shot(id: 2, globalSeq: 'G1'),
        shot(id: 3, globalSeq: 'G010'),
      ]);
      expect(issues, hasLength(3));
      expect(issues.every((i) => i.code == 'segment_seq'), isTrue);
    });

    test('批内不连号报警，跨批互不影响', () {
      final issues = ShotGate.segmentSeq([
        shot(id: 1, globalSeq: 'G01', batch: 1),
        shot(id: 2, globalSeq: 'G03', batch: 1),
        shot(id: 3, globalSeq: 'G01', batch: 2),
      ]);
      expect(issues.single.locator, 'batch 1');
      expect(issues.single.message, contains('不连号'));
      expect(issues.single.message, contains('G02'));
    });

    test('连号通过', () {
      expect(
        ShotGate.segmentSeq([
          for (var i = 1; i <= 6; i++)
            shot(
              id: i,
              globalSeq: 'G${i.toString().padLeft(2, '0')}',
              batch: 1,
            ),
        ]),
        isEmpty,
      );
    });
  });

  group('ShotGate frameEmpty', () {
    test('空提示词与短英文提示词分别报警', () {
      final issues = ShotGate.frameEmpty([
        shot(id: 1, globalSeq: 'G01'),
        shot(id: 2, globalSeq: 'G02', prompt: '   '),
        shot(id: 3, globalSeq: 'G03', prompt: 'anime style'),
      ]);
      expect(issues, hasLength(3));
      expect(issues.every((i) => i.code == 'frame_empty'), isTrue);
      expect(issues.every((i) => i.isError), isTrue);
    });

    test('中文正文通过', () {
      expect(
        ShotGate.frameEmpty([
          shot(prompt: '佐藤站在教室门口，侧逆光，中景，缓慢推近'),
        ]),
        isEmpty,
      );
    });
  });

  group('ShotGate phraseMissing', () {
    test('景别与运镜词没落进提示词报警', () {
      final issues = ShotGate.phraseMissing(
        shots: [shot(id: 1, shotType: '特写', prompt: '佐藤站在教室门口')],
        frames: [frame(id: 1, shotId: 1, shotSize: '中景', camera: '手持推进')],
      );
      expect(issues.map((i) => i.code), ['phrase_missing', 'phrase_missing', 'phrase_missing']);
      expect(issues.map((i) => i.message).join('\n'), contains('特写'));
      expect(issues.map((i) => i.message).join('\n'), contains('中景'));
      expect(issues.map((i) => i.message).join('\n'), contains('手持推进'));
    });

    test('词已回查进提示词通过，固定机位不检查', () {
      expect(
        ShotGate.phraseMissing(
          shots: [
            shot(
              id: 1,
              shotType: '中景',
              prompt: '佐藤站在教室门口，中景，固定机位',
            ),
          ],
          frames: [frame(id: 1, shotId: 1, shotSize: '中景', camera: '固定')],
        ),
        isEmpty,
      );
    });

    test('空提示词跳过（由 frame_empty 报）', () {
      expect(
        ShotGate.phraseMissing(
          shots: [shot(id: 1, shotType: '特写', prompt: '')],
          frames: [frame(id: 1, shotId: 1, shotSize: '中景')],
        ),
        isEmpty,
      );
    });
  });

  group('ShotGate videoNoNames', () {
    test('叙述正文出现角色名报警', () {
      final issues = ShotGate.videoNoNames(
        locator: 'G01',
        prompt: 'Objective: 完成本段画面事件——佐藤走进房间\n'
            'Reference binding:\n'
            '- {{ref1}}：佐藤（角色 参考）\n'
            'Visual direction:\n'
            '佐藤回头看向画外',
        characterNames: ['佐藤', '老周'],
      );
      expect(issues.single.code, 'video_no_names');
      expect(issues.single.locator, 'G01');
      expect(issues.single.message, contains('{{ref N}}'));
    });

    test('仅在参考图绑定与服装覆盖区块出现名字不报警', () {
      expect(
        ShotGate.videoNoNames(
          locator: 'G01',
          prompt: 'Objective: 完成本段画面事件——一个人物走进房间\n'
              'Reference binding:\n'
              '- {{ref1}}：佐藤（角色 参考）\n'
              '- {{ref2}}：老周（角色 参考）\n'
              'Costume overrides:\n'
              '- 佐藤：本镜头穿「蓝白校服」\n'
              'Immutable locks: 保持人物身份与外观锚点不变\n'
              'Timeline:\n'
              '【0:00-0:05】\n'
              '画面为中景，主体是人物',
          characterNames: ['佐藤', '老周'],
        ),
        isEmpty,
      );
    });

    test('正文里出现 Timeline: 字样不被误判为区块头', () {
      expect(
        ShotGate.videoNoNames(
          locator: 'G01',
          prompt: 'Visual direction:\n'
              '旁白提到 Timeline: 佐藤的过去',
          characterNames: ['佐藤'],
        ),
        isNotEmpty,
      );
    });

    test('区块头独占一行才被剥离', () {
      final narrative = ShotGate.narrativeOnly(
        'Reference binding:\n- {{ref1}}：佐藤（角色 参考）\n'
            'Costume overrides:\n- 佐藤：本镜头穿「蓝白校服」\n'
            'Visual direction:\n佐藤回头',
      );
      expect(narrative, contains('Visual direction:'));
      expect(narrative, isNot(contains('{{ref1}}')));
      expect(narrative, isNot(contains('蓝白校服')));
    });

    test('无角色名时不检查', () {
      expect(
        ShotGate.videoNoNames(
          locator: 'G01',
          prompt: '佐藤走进房间',
          characterNames: [],
        ),
        isEmpty,
      );
    });
  });

  group('ShotGate.validate 汇总', () {
    test('镜头侧四门合并，videoPrompt 为空时不查视频门', () {
      final issues = ShotGate.validate(
        shots: [shot(id: 1, globalSeq: 'G01', shotType: '特写', prompt: '画面开始')],
        frames: [frame(id: 1, shotId: 1, shotSize: '中景')],
        characterNames: ['佐藤'],
      );
      expect(issues.map((i) => i.code).toSet(), {'frame_empty', 'phrase_missing'});
    });

    test('传 videoPrompt 时追加视频门', () {
      final issues = ShotGate.validate(
        shots: [shot(id: 1, prompt: '佐藤站在教室门口的阴影里，教室里只剩下她一个人')],
        frames: [],
        characterNames: ['佐藤'],
        videoPrompt: 'Visual direction:\n佐藤回头看向画外',
      );
      expect(issues.map((i) => i.code).toSet(), {'video_no_names'});
    });
  });

  group('ScriptGate has_action', () {
    test('无画面动作报警', () {
      final issues = ScriptGate.hasAction([scene(action: '')]);
      expect(issues.single.code, 'has_action');
      expect(issues.single.locator, '1 · 教室');
    });

    test('有画面动作通过', () {
      expect(ScriptGate.hasAction([scene(action: '佐藤抬手推开木门')]), isEmpty);
    });
  });

  group('ScriptGate action_prose', () {
    test('动作字段夹对话引号报警', () {
      expect(
        ScriptGate.actionProse([scene(action: '佐藤说：“快走”')]).single.code,
        'action_prose',
      );
      expect(
        ScriptGate.actionProse([scene(id: 2, action: '老者低声念「快走」')]).single.code,
        'action_prose',
      );
      expect(
        ScriptGate.actionProse([scene(id: 3, action: '老者念出"快走"')]).single.code,
        'action_prose',
      );
    });

    test('纯动作描述通过', () {
      expect(ScriptGate.actionProse([scene(action: '佐藤抬手推开木门，回头')]), isEmpty);
    });
  });

  group('ScriptGate speaker_unknown', () {
    test('说话人不在出场名单报警', () {
      final issues = ScriptGate.speakerUnknown([
        scene(
          characters: jsonEncode(['佐藤', '老周']),
          dialogue: jsonEncode([
            {'speaker': '小豆', 'type': '对白', 'text': '快走'},
          ]),
        ),
      ]);
      expect(issues.single.code, 'speaker_unknown');
      expect(issues.single.message, contains('小豆'));
      expect(issues.single.message, contains('老周'));
    });

    test('出场名单为空时跳过', () {
      expect(
        ScriptGate.speakerUnknown([
          scene(
            characters: '[]',
            dialogue: jsonEncode([{'speaker': '佐藤', 'type': '对白', 'text': '快走'}]),
          ),
        ]),
        isEmpty,
      );
    });

    test('VO 与 OS 旁白豁免', () {
      expect(
        ScriptGate.speakerUnknown([
          scene(
            characters: jsonEncode(['佐藤']),
            dialogue: jsonEncode([
              {'speaker': '旁白', 'type': 'VO', 'text': '多年以后'},
              {'speaker': '佐藤', 'type': 'OS', 'text': '快走'},
            ]),
          ),
        ]),
        isEmpty,
      );
    });

    test('出场角色正常说话通过', () {
      expect(
        ScriptGate.speakerUnknown([
          scene(
            characters: jsonEncode(['佐藤']),
            dialogue: jsonEncode([{'speaker': '佐藤', 'type': '对白', 'text': '快走'}]),
          ),
        ]),
        isEmpty,
      );
    });
  });

  group('ScriptGate.validate 汇总', () {
    test('三条门合并输出', () {
      final issues = ScriptGate.validate(scenes: [
        scene(
          characters: jsonEncode(['佐藤']),
          action: '佐藤说：“快走”',
          dialogue: jsonEncode([
            {'speaker': '小豆', 'type': '对白', 'text': '快走'},
          ]),
        ),
      ]);
      expect(
        issues.map((i) => i.code),
        containsAll(['action_prose', 'speaker_unknown']),
      );
    });
  });

  group('SkeletonGate.coverage', () {
    test('认领完整且顺序正常时通过', () {
      expect(
        SkeletonGate.coverage(
          beats: SkeletonGate.beatOrder([beat(id: 1, sourceRef: 'E01'), beat(id: 2, sourceRef: 'E02')]),
          shots: [shot(beatRefs: jsonEncode(['E01', 'E02']))],
        ),
        isEmpty,
      );
    });

    test('编号重复报警（error）', () {
      final issues = SkeletonGate.coverage(
        beats: SkeletonGate.beatOrder([beat(id: 1, sourceRef: 'E01'), beat(id: 2, sourceRef: 'E01')]),
        shots: [shot(beatRefs: jsonEncode(['E01']))],
      );
      expect(issues.single.code, 'coverage');
      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('重复'));
    });

    test('未知引用报警（error）', () {
      final issues = SkeletonGate.coverage(
        beats: [beat(id: 1, sourceRef: 'E01')],
        shots: [shot(beatRefs: jsonEncode(['E01', 'E09']))],
      );
      expect(issues.single.code, 'coverage');
      expect(issues.single.isError, isTrue);
      expect(issues.single.locator, 'G01');
      expect(issues.single.message, contains('E09'));
    });

    test('重复认领与段内顺序倒流分别报警（warn）', () {
      final issues = SkeletonGate.coverage(
        beats: SkeletonGate.beatOrder([beat(id: 1, sourceRef: 'E01'), beat(id: 2, sourceRef: 'E02')]),
        shots: [
          shot(id: 1, globalSeq: 'G01', beatRefs: jsonEncode(['E01', 'E02'])),
          shot(id: 2, globalSeq: 'G02', beatRefs: jsonEncode(['E02', 'E01'])),
        ],
      );
      final locators = {for (final i in issues) i.locator};
      expect(locators, containsAll({'E01', 'E02', 'G02'}));
      expect(issues.where((i) => i.locator == 'E01').single.message, contains('认领 2 次'));
      expect(issues.where((i) => i.locator == 'G02').single.message, contains('倒流'));
    });

    test('未认领节拍报警（warn）', () {
      final issues = SkeletonGate.coverage(
        beats: SkeletonGate.beatOrder([beat(id: 1, sourceRef: 'E01'), beat(id: 2, sourceRef: 'E02')]),
        shots: [shot(beatRefs: jsonEncode(['E01']))],
      );
      expect(issues.single.locator, 'E02');
      expect(issues.single.message, contains('未被任何段认领'));
    });

    test('beatOrder 按 E## 数字排序，无法解析的排在后面', () {
      final ordered = SkeletonGate.beatOrder([
        beat(id: 1, sourceRef: 'E10'),
        beat(id: 2, sourceRef: 'E02'),
        beat(id: 3, sourceRef: '坏号'),
      ]);
      expect(ordered.map((b) => b.sourceRef).toList(), ['E02', 'E10', '坏号']);
    });
  });
}
