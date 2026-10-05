import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/features/asset/asset_models.dart';

void main() {
  group('AssetDraft 角色身体参数解析（T21.13）', () {
    test('身高 / 体型 / 服装套全部解析成功', () {
      final draft = AssetDraft.fromJson({
        'type': '角色',
        'name': '佐藤',
        'stableId': 'char_sato',
        'appearanceAnchor': {'age': '16', 'gender': '女'},
        'heightCm': 158,
        'bodyType': '匀称',
        'costumeSets': [
          {
            'name': '校服',
            'description': '蓝白运动外套配深蓝长裤，左胸校徽',
          },
          {
            'name': '常服',
            'description': '米色针织开衫配卡其长裙',
          },
        ],
        'boardLayout': '四视图',
        'prompt': '提示词',
      });

      expect(draft.heightCm, 158);
      expect(draft.bodyType, '匀称');
      expect(draft.costumeSets, isNotNull);
      expect(draft.costumeSets, hasLength(2));
      expect(draft.costumeSets![0]['name'], '校服');
      expect(
        draft.costumeSets![0]['description'],
        '蓝白运动外套配深蓝长裤，左胸校徽',
      );
      expect(draft.costumeSets![1]['name'], '常服');
    });

    test('身高字符串可解析，越界与不可解析视为未指定', () {
      AssetDraft parse(Object? value) => AssetDraft.fromJson({
            'type': '角色',
            'name': 'A',
            'stableId': 'char_a',
            'heightCm': value,
            'boardLayout': '四视图',
            'prompt': '',
          });

      expect(parse('165').heightCm, 165);
      expect(parse(170.6).heightCm, 171);
      expect(parse(60).heightCm, isNull);
      expect(parse(250).heightCm, isNull);
      expect(parse('一米六').heightCm, isNull);
    });

    test('体型必须在词表内，未知与任意词视为未指定', () {
      AssetDraft parse(Object? value) => AssetDraft.fromJson({
            'type': '角色',
            'name': 'A',
            'stableId': 'char_a',
            'bodyType': value,
            'boardLayout': '四视图',
            'prompt': '',
          });

      for (final t in BodyTypes.all) {
        expect(parse(t).bodyType, t, reason: '词表内的 $t 应保留');
      }
      expect(parse('未知').bodyType, isNull);
      expect(parse('高大').bodyType, isNull);
      expect(parse(null).bodyType, isNull);
    });

    test('服装套只保留 name 非空的项，全空时返回 null', () {
      AssetDraft parse(Object? value) => AssetDraft.fromJson({
            'type': '角色',
            'name': 'A',
            'stableId': 'char_a',
            'costumeSets': value,
            'boardLayout': '四视图',
            'prompt': '',
          });

      expect(parse(null), isNot(throwsA(anything)));
      expect(parse(null).costumeSets, isNull);
      expect(parse([]).costumeSets, isNull);
      expect(parse([{'name': '', 'description': 'x'}]).costumeSets, isNull);
      expect(parse([{'description': '无名字'}]).costumeSets, isNull);

      final draft = parse([
        {'name': '  基础装  '},
        {'name': ''},
        {'name': '变装', 'description': ' 黑裙  '},
      ]);
      expect(draft.costumeSets, hasLength(2));
      expect(draft.costumeSets![0]['name'], '基础装');
      expect(draft.costumeSets![0]['description'], '');
      expect(draft.costumeSets![1]['description'], '黑裙');
    });

    test('缺字段的旧输出照常解析，三个字段回落 null', () {
      final draft = AssetDraft.fromJson({
        'type': '场景',
        'name': '荒原',
        'stableId': 'scene_wasteland',
        'boardLayout': '主视图',
        'prompt': '提示词',
      });

      expect(draft.heightCm, isNull);
      expect(draft.bodyType, isNull);
      expect(draft.costumeSets, isNull);
      expect(draft.boardLayout, '主视图');
    });

    test('服装套描述缺失时补空串，不抛异常', () {
      final draft = AssetDraft.fromJson({
        'type': '角色',
        'name': 'A',
        'stableId': 'char_a',
        'costumeSets': [
          {'name': '套装一'},
        ],
        'boardLayout': '四视图',
        'prompt': '',
      });

      expect(draft.costumeSets, hasLength(1));
      expect(draft.costumeSets![0]['description'], '');
    });
  });

  group('体型词表', () {
    test('六个取值与文档字段规则一致', () {
      expect(
        BodyTypes.all,
        ['瘦长', '匀称', '结实', '魁梧', '丰腴', '娇小'],
      );
      expect(BodyTypes.all, hasLength(6));
      expect(
        BodyTypes.all,
        containsAll([
          BodyTypes.slim,
          BodyTypes.balanced,
          BodyTypes.sturdy,
          BodyTypes.burly,
          BodyTypes.plump,
          BodyTypes.petite,
        ]),
      );
    });
  });
}
