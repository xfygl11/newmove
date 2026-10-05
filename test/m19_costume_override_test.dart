import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/asset/asset_models.dart';
import 'package:newmove/features/shot/costume_gate.dart';
import 'package:newmove/features/shot/shot_models.dart';
import 'package:newmove/features/shot/video_prompt.dart';

void main() {
  group('ShotCostumeOverride 编解码（T21.13）', () {
    test('encode/decode 往返一致', () {
      final overrides = const [
        ShotCostumeOverride(stableId: 'char_qing', name: '校服'),
        ShotCostumeOverride(stableId: 'char_rock', name: '囚服'),
      ];

      final raw = ShotCostumeOverride.encode(overrides);
      final decoded = ShotCostumeOverride.decode(raw);

      expect(decoded, hasLength(2));
      expect(decoded.first.stableId, 'char_qing');
      expect(decoded.first.name, '校服');
      expect(decoded.last.stableId, 'char_rock');
      expect(decoded.last.name, '囚服');
    });

    test('空清单编成空数组、解回空列表', () {
      expect(ShotCostumeOverride.encode(const []), '[]');
      expect(ShotCostumeOverride.decode('[]'), isEmpty);
    });

    test('null、空串、坏 JSON、顶层非数组一律解码为空', () {
      expect(ShotCostumeOverride.decode(null), isEmpty);
      expect(ShotCostumeOverride.decode(''), isEmpty);
      expect(ShotCostumeOverride.decode('{不是数组'), isEmpty);
      expect(ShotCostumeOverride.decode('{"a":1}'), isEmpty);
      // 非 Map 条目与 null 条目被丢弃。
      expect(ShotCostumeOverride.decode('[null, 5, "字符串", [1, 2]]'), isEmpty);
    });

    test('条目内字段缺失视为空串后被丢弃', () {
      expect(
        ShotCostumeOverride.decode(
          '[{"stableId":"char_qing"},{"name":"校服"},{"stableId":null,"name":null}]',
        ),
        isEmpty,
      );
    });

    test('数值类型漂移按字符串收，不抛错', () {
      final decoded = ShotCostumeOverride.decode(
        '[{"stableId":"char_qing","name":1}]',
      );
      expect(decoded.single.name, '1');
    });

    test('缺 stableId 或 name 的条目被丢弃，不写进库', () {
      final raw =
          '[{"stableId":"char_qing","name":""},{"stableId":"","name":"校服"},{"stableId":"char_ok","name":"斗篷"}]';
      final decoded = ShotCostumeOverride.decode(raw);

      expect(decoded, hasLength(1));
      expect(decoded.single.stableId, 'char_ok');
    });
  });

  group('ShotDraft.costumeOverrides 解析', () {
    ShotDraft parse(Object? overrides) {
      final json = {
        'globalSeq': 'G01',
        'shotType': '中景',
        'prompt': '提示词',
        'frames': <dynamic>[],
        'refs': <dynamic>[],
      };
      if (overrides != null) json['costumeOverrides'] = overrides;
      return ShotDraft.fromJson(json);
    }

    test('有效条目全部解析', () {
      final draft = parse([
        {'stableId': 'char_qing', 'name': '校服'},
        {'stableId': 'char_rock', 'name': '囚服'},
      ]);

      expect(draft.costumeOverrides, hasLength(2));
      expect(draft.costumeOverrides!.first.name, '校服');
    });

    test('全空与不可解析条目被丢弃后回 null，不落空数组', () {
      expect(
        parse([
          {'stableId': '', 'name': '校服'},
          {'stableId': 'char_qing'},
        ]).costumeOverrides,
        isNull,
      );
      expect(parse([]).costumeOverrides, isNull);
      expect(parse(const <String>[]).costumeOverrides, isNull);
    });

    test('顶层不是数组视为未指定，不抛错', () {
      expect(parse('校服').costumeOverrides, isNull);
      expect(parse(null).costumeOverrides, isNull);
    });

    test('缺字段的旧输出照常解析', () {
      expect(
        ShotDraft.fromJson({
          'globalSeq': 'G02',
          'shotType': '中景',
          'prompt': '提示词',
          'frames': [],
          'refs': [],
        }).costumeOverrides,
        isNull,
      );
    });
  });

  group('AssetCostumeSets 扩展', () {
    Asset asset(String? costumeSets) => Asset(
      id: 1,
      scriptId: 1,
      type: '角色',
      name: '阿青',
      stableId: 'char_qing',
      boardLayout: 'main_view',
      prompt: '提示词',
      status: '已采用',
      isStale: 0,
      costumeSets: costumeSets,
    );

    test('套名与描述按名读取', () {
      final a = asset(
        '[{"name":"校服","description":"蓝白运动外套"},{"name":"斗篷","description":"深灰长斗篷"}]',
      );

      expect(a.costumeNames, ['校服', '斗篷']);
      expect(a.costumeDescriptionOf('校服'), '蓝白运动外套');
      expect(a.costumeDescriptionOf('斗篷'), '深灰长斗篷');
      // 找不到的套名返回空串，不编造描述。
      expect(a.costumeDescriptionOf('囚服'), '');
    });

    test('null、坏 JSON 与缺 name 的条目折叠为空清单', () {
      expect(asset(null).costumeNames, isEmpty);
      expect(asset('{坏').costumeNames, isEmpty);
      expect(
        asset('[{"description":"无套名"},{"name":""},{"name":"  "}]').costumeNames,
        isEmpty,
      );
    });
  });

  group('CostumeGate 校验（T21.13）', () {
    Shot shot({String? costumeOverrides, String seq = 'G01'}) => Shot(
      id: 1,
      scriptId: 1,
      globalSeq: seq,
      batch: 1,
      durationMs: 6000,
      globalTimeRange: '00:00-00:06',
      beatRefs: '[]',
      assetStates: '{}',
      prompt: '提示词',
      status: '待分镜图',
      outputType: 'image',
      isStale: 0,
      costumeOverrides: costumeOverrides,
    );

    Asset character({
      int id = 1,
      String stableId = 'char_qing',
      String? costumeSets,
    }) => Asset(
      id: id,
      scriptId: 1,
      type: '角色',
      name: '阿青',
      stableId: stableId,
      boardLayout: 'main_view',
      prompt: '提示词',
      status: '已采用',
      isStale: 0,
      costumeSets: costumeSets,
    );

    AssetRef ref(int assetId) =>
        AssetRef(id: 1, shotId: 1, assetId: assetId, role: '角色参考', order: 0);

    final twoSets =
        '[{"name":"校服","description":"蓝白运动外套"},{"name":"斗篷","description":"深灰长斗篷"}]';

    test('无覆盖不产生任何问题', () {
      expect(CostumeGate.validate(shot(), [ref(1)], {1: character()}), isEmpty);
      expect(CostumeGate.validate(shot(), const [], const {}), isEmpty);
    });

    test('清单内套名 + 已出镜角色：通过', () {
      final issues = CostumeGate.validate(
        shot(costumeOverrides: '[{"stableId":"char_qing","name":"斗篷"}]'),
        [ref(1)],
        {1: character(costumeSets: twoSets)},
      );
      expect(issues, isEmpty);
    });

    test('套名不在清单内：costume_unknown，并列出可用套名', () {
      final issues = CostumeGate.validate(
        shot(costumeOverrides: '[{"stableId":"char_qing","name":"囚服"}]'),
        [ref(1)],
        {1: character(costumeSets: twoSets)},
      );

      expect(issues, hasLength(1));
      expect(issues.single.code, 'costume_unknown');
      expect(issues.single.locator, 'G01 · 阿青');
      expect(issues.single.message, contains('囚服'));
      expect(issues.single.message, contains('可用：校服 / 斗篷'));
      expect(issues.single.isError, isFalse);
    });

    test('资产未登记服装套：提示可用套名为「无」', () {
      final issues = CostumeGate.validate(
        shot(costumeOverrides: '[{"stableId":"char_qing","name":"校服"}]'),
        [ref(1)],
        {1: character(costumeSets: null)},
      );

      expect(issues.single.code, 'costume_unknown');
      expect(issues.single.message, contains('可用：无'));
    });

    test('角色不在参考绑定里：costume_orphan', () {
      final issues = CostumeGate.validate(
        shot(costumeOverrides: '[{"stableId":"char_rock","name":"校服"}]'),
        [ref(1)],
        {1: character(costumeSets: twoSets)},
      );

      expect(issues, hasLength(1));
      expect(issues.single.code, 'costume_orphan');
      expect(issues.single.locator, 'G01 · 未知角色');
    });

    test('同一角色多套覆盖：costume_duplicate', () {
      final issues = CostumeGate.validate(
        shot(
          costumeOverrides: '[{"stableId":"char_qing","name":"校服"},{"stableId":"char_qing","name":"斗篷"}]',
        ),
        [ref(1)],
        {1: character(costumeSets: twoSets)},
      );

      expect(issues, hasLength(1));
      expect(issues.single.code, 'costume_duplicate');
    });

    test('混合场景三类问题同现且只报 warn', () {
      final issues = CostumeGate.validate(
        shot(
          costumeOverrides: '[{"stableId":"char_qing","name":"囚服"},{"stableId":"char_rock","name":"校服"},{"stableId":"char_qing","name":"斗篷"}]',
        ),
        [ref(1)],
        {1: character(costumeSets: twoSets)},
      );

      expect(
        issues.map((i) => i.code),
        unorderedEquals([
          'costume_unknown',
          'costume_orphan',
          'costume_duplicate',
        ]),
      );
      expect(issues.every((i) => !i.isError), isTrue);
    });

    test('参考绑定指向已删资产：跳过不崩', () {
      final issues = CostumeGate.validate(
        shot(costumeOverrides: '[{"stableId":"char_qing","name":"校服"}]'),
        [ref(99)],
        {},
      );

      expect(issues.single.code, 'costume_orphan');
    });
  });

  group('视频提示词的服装覆盖段', () {
    Shot shot(String? costumeOverrides) => Shot(
      id: 1,
      scriptId: 1,
      globalSeq: 'G01',
      batch: 1,
      durationMs: 6000,
      globalTimeRange: '00:00-00:06',
      beatRefs: '[]',
      assetStates: '{}',
      prompt: '本段目标事件',
      status: '分镜图已确认',
      outputType: 'image',
      isStale: 0,
      costumeOverrides: costumeOverrides,
    );

    ShotFrame frame() => const ShotFrame(
      id: 1,
      shotId: 1,
      seq: 1,
      timeRange: '00:00-00:06',
      subject: '阿青',
      shotSize: '中景',
      angle: '平视',
      camera: '固定',
      blocking: '阿青位于画面左侧',
      performance: '扶起老者',
      dialogue: null,
    );

    const builder = VideoPromptBuilder();

    String build({
      required String? costumeOverrides,
      required Map<int, Asset> assetById,
      required List<AssetRef> refs,
    }) {
      return builder.build(
        shot: shot(costumeOverrides),
        frames: [frame()],
        refs: refs,
        assetById: assetById,
      );
    }

    Asset character() => const Asset(
      id: 1,
      scriptId: 1,
      type: '角色',
      name: '阿青',
      stableId: 'char_qing',
      boardLayout: 'main_view',
      prompt: '提示词',
      status: '已采用',
      isStale: 0,
    );

    AssetRef ref() =>
        const AssetRef(id: 1, shotId: 1, assetId: 1, role: '角色参考', order: 0);

    test('有覆盖时出现 Costume overrides 段并按资产名与套名列出', () {
      final prompt = build(
        costumeOverrides: '[{"stableId":"char_qing","name":"斗篷"}]',
        assetById: {1: character()},
        refs: [ref()],
      );

      expect(prompt, contains('Costume overrides:'));
      expect(prompt, contains('阿青：本镜头穿「斗篷」'));
      expect(prompt, contains('覆盖参考图中的基础态造型'));
      // 覆盖段紧随 Reference binding，在 Timeline 之前。
      expect(
        prompt.indexOf('Costume overrides:'),
        lessThan(prompt.indexOf('Timeline:')),
      );
    });

    test('无覆盖时不出现该段', () {
      expect(
        build(
          costumeOverrides: null,
          assetById: {1: character()},
          refs: [ref()],
        ),
        isNot(contains('Costume overrides')),
      );
    });

    test('覆盖的角色不在参考绑定里时整段跳过，不写未知角色名', () {
      final prompt = build(
        costumeOverrides: '[{"stableId":"char_missing","name":"校服"}]',
        assetById: {1: character()},
        refs: [ref()],
      );

      expect(prompt, isNot(contains('Costume overrides')));
      expect(prompt, isNot(contains('未知')));
    });
  });
}
