import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/gate_issue.dart';
import 'package:newmove/features/novel/character_gate.dart';
import 'package:newmove/features/novel/novel_models.dart';

CharacterSpec _c({
  String name = '林昭',
  String tier = CharacterTiers.lead,
  String evidenceQuotes = '',
}) =>
    CharacterSpec(
      name: name,
      role: '主角',
      goal: '活着',
      state: '初登场',
      relations: '',
      tier: tier,
      evidenceQuotes: evidenceQuotes,
    );

void main() {
  group('CharacterTiers', () {
    test('闭集与上限常量', () {
      expect(CharacterTiers.all, [
        '主角',
        '副角',
        '工具人',
        '其他',
      ]);
      expect(CharacterTiers.caps, {
        '主角': 1,
        '副角': 6,
        '工具人': 10,
      });
    });

    test('isKnown 对 null 与未登记值返回 false', () {
      expect(CharacterTiers.isKnown(CharacterTiers.lead), isTrue);
      expect(CharacterTiers.isKnown(CharacterTiers.other), isTrue);
      expect(CharacterTiers.isKnown(''), isFalse);
      expect(CharacterTiers.isKnown('配角'), isFalse);
      expect(CharacterTiers.isKnown(null), isFalse);
    });
  });

  group('tier_missing', () {
    test('空分档与未知分档都提示', () {
      final issues = CharacterGate.tierMissing([
        _c(name: '甲', tier: ''),
        _c(name: '乙', tier: '配角'),
      ]);
      expect(issues, hasLength(2));
      expect(issues.map((i) => i.code), everyElement('tier_missing'));
      expect(
        issues.map((i) => i.locator),
        containsAll(['甲', '乙']),
      );
      expect(issues.every((i) => i.severity == GateSeverity.warn), isTrue);
    });

    test('已分档角色不提示', () {
      expect(
        CharacterGate.tierMissing([
          _c(tier: CharacterTiers.lead),
          _c(name: '副', tier: CharacterTiers.support),
          _c(name: '工', tier: CharacterTiers.functional),
          _c(name: '其', tier: CharacterTiers.other),
        ]),
        isEmpty,
      );
    });

    test('空列表返回空', () {
      expect(CharacterGate.tierMissing(const []), isEmpty);
    });

    test('未命名角色定位降级为占位文案', () {
      final issue = CharacterGate.tierMissing([_c(name: '', tier: '')]).single;
      expect(issue.locator, '（未命名角色）');
    });
  });

  group('tier_cap', () {
    test('主角超过 1 人提示，消息含实际与上限人数', () {
      final issues = CharacterGate.tierCap([
        _c(name: '甲', tier: CharacterTiers.lead),
        _c(name: '乙', tier: CharacterTiers.lead),
      ]);
      expect(issues, hasLength(1));
      expect(issues.single.code, 'tier_cap');
      expect(issues.single.locator, '主角');
      expect(issues.single.message, '「主角」2 人，超过上限 1 人');
    });

    test('正好达到上限不提示', () {
      final chars = [
        _c(tier: CharacterTiers.lead),
        ...List.generate(
          6,
          (i) => _c(name: '副$i', tier: CharacterTiers.support),
        ),
        ...List.generate(
          10,
          (i) => _c(name: '工$i', tier: CharacterTiers.functional),
        ),
      ];
      expect(CharacterGate.tierCap(chars), isEmpty);
    });

    test('副角与工具人各自超上限时各报一条', () {
      final issues = CharacterGate.tierCap([
        ...List.generate(7, (i) => _c(name: '副$i', tier: CharacterTiers.support)),
        ...List.generate(11, (i) => _c(name: '工$i', tier: CharacterTiers.functional)),
      ]);
      expect(issues.map((i) => i.locator), ['副角', '工具人']);
    });

    test('未知分档不计入计数，由 tier_missing 提示', () {
      final issues = CharacterGate.tierCap([
        _c(name: '甲', tier: CharacterTiers.lead),
        _c(name: '乙', tier: '配角'),
      ]);
      expect(issues, isEmpty);
    });

    test('「其他」无上限，多少都不提示', () {
      final chars = [
        for (var i = 0; i < 40; i++) _c(name: '其$i', tier: CharacterTiers.other),
      ];
      expect(CharacterGate.tierCap(chars), isEmpty);
    });
  });

  group('evidence_unverified', () {
    const content = '林昭把刀插进土里，转身走了。雨下得很大。';

    test('正文为空时整门跳过，不刷假告警', () {
      expect(
        CharacterGate.evidenceUnverified([_c(evidenceQuotes: '不在这里')], ''),
        isEmpty,
      );
      expect(
        CharacterGate.evidenceUnverified([_c(evidenceQuotes: '不在这里')], '   '),
        isEmpty,
      );
    });

    test('引文在正文命中不提示', () {
      expect(
        CharacterGate.evidenceUnverified(
          [_c(evidenceQuotes: '把刀插进土里')],
          content,
        ),
        isEmpty,
      );
    });

    test('引文未命中提示，消息含截断后的引文', () {
      final issue = CharacterGate.evidenceUnverified(
        [_c(evidenceQuotes: '他从未离开过')],
        content,
      ).single;
      expect(issue.code, 'evidence_unverified');
      expect(issue.locator, '林昭');
      expect(issue.message, '引文未在正文命中：他从未离开过');
    });

    test('忽略空白命中（LLM 引文中间换行）', () {
      expect(
        CharacterGate.evidenceUnverified(
          [_c(evidenceQuotes: '把刀插进 土里')],
          content,
        ),
        isEmpty,
      );
    });

    test('不足四个字的引文按未命中提示', () {
      expect(
        CharacterGate.evidenceUnverified([_c(evidenceQuotes: '刀')], content),
        isNotEmpty,
      );
    });

    test('多条引文按「；」与 `;` 分隔，逐条核对', () {
      final issues = CharacterGate.evidenceUnverified(
        [_c(evidenceQuotes: '转身走了；雨下得很大;并不存在')],
        content,
      );
      expect(issues, hasLength(1));
      expect(issues.single.message, '引文未在正文命中：并不存在');
    });

    test('长引文在消息里截断到 30 字', () {
      final long =
          '这是一个完全不存在于本章正文中的、用来验证消息截断阈值的超长引文测试片段啊呀哇噢哈嘿哈嘿';
      final issue = CharacterGate.evidenceUnverified(
        [_c(evidenceQuotes: long)],
        content,
      ).single;
      expect(issue.message.length, lessThan(long.length));
      expect(issue.message, '引文未在正文命中：' '${long.substring(0, 30)}…');
    });

    test('多个角色各自定位', () {
      final issues = CharacterGate.evidenceUnverified(
        [
          _c(name: '甲', tier: CharacterTiers.support, evidenceQuotes: '不存在A'),
          _c(name: '乙', tier: CharacterTiers.support, evidenceQuotes: '不存在B'),
        ],
        content,
      );
      expect(issues.map((i) => i.locator), ['甲', '乙']);
    });

    test('引文为空串时不产生条目', () {
      expect(
        CharacterGate.evidenceUnverified(
          [_c(evidenceQuotes: '  ； ;  ')],
          content,
        ),
        isEmpty,
      );
    });
  });

  group('quotesOf', () {
    test('分隔、去空白、丢弃空段', () {
      expect(
        CharacterGate.quotesOf(_c(evidenceQuotes: ' 一 ；二;；  ；三')),
        ['一', '二', '三'],
      );
    });

    test('空串返回空列表', () {
      expect(CharacterGate.quotesOf(_c()), isEmpty);
    });
  });

  group('validate', () {
    test('三门结果合并', () {
      final issues = CharacterGate.validate(
        characters: [
          _c(name: '甲', tier: CharacterTiers.lead),
          _c(name: '乙', tier: CharacterTiers.lead),
          _c(name: '丙', tier: '', evidenceQuotes: '不存在的引文'),
        ],
        content: '这里没有那条引文。',
      );
      expect(issues.map((i) => i.code), containsAll([
        'tier_cap',
        'tier_missing',
        'evidence_unverified',
      ]));
      expect(issues.length, 3);
    });

    test('数据完整时无告警', () {
      expect(
        CharacterGate.validate(
          characters: [
            _c(tier: CharacterTiers.lead),
            _c(name: '副', tier: CharacterTiers.support),
          ],
          content: '林昭把刀插进土里。',
        ),
        isEmpty,
      );
    });
  });

  group('CharacterSpec 新增字段', () {
    test('可选字段默认空串', () {
      const c = CharacterSpec(
        name: 'n',
        role: '',
        goal: '',
        state: '',
        relations: '',
      );
      expect(c.tier, '');
      expect(c.arc, '');
      expect(c.evidenceQuotes, '');
      expect(c.voiceDesign, '');
      expect(c.performanceStyle, '');
    });

    test('fromJson 缺字段回落空串（存量数据）', () {
      final c = CharacterSpec.fromJson(const {
        'name': '旧角色',
        'role': '配角',
        'goal': '复仇',
        'state': '潜伏',
        'relations': '与主角对立',
      });
      expect(c.name, '旧角色');
      expect(c.tier, '');
      expect(c.performanceStyle, '');
    });

    test('fromJson 容忍数字与布尔写成字符串', () {
      final c = CharacterSpec.fromJson(const {
        'name': 123,
        'tier': true,
        'arc': null,
      });
      expect(c.name, '123');
      expect(c.tier, 'true');
      expect(c.arc, '');
    });

    test('toJson 包含全部十个字段', () {
      final json = _c(tier: CharacterTiers.lead).toJson();
      expect(
        json.keys,
        containsAll([
          'name',
          'role',
          'goal',
          'state',
          'relations',
          'tier',
          'arc',
          'evidenceQuotes',
          'voiceDesign',
          'performanceStyle',
        ]),
      );
    });
  });

  group('ReviewIssue.quoteInContent', () {
    const content = '林昭把刀插进土里，转身走了。';

    test('精确命中返回 true', () {
      expect(ReviewIssue.quoteInContent('把刀插进土里', content), isTrue);
    });

    test('未命中返回 false', () {
      expect(ReviewIssue.quoteInContent('他从未离开', content), isFalse);
    });

    test('短引文按未命中处理', () {
      expect(ReviewIssue.quoteInContent('刀', content), isFalse);
    });
  });
}
