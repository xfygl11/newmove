// 画面风格词表测试：词表自洽性 + 画风提示词与 PromptGate 族关键词的同步守卫
// + effectiveArtStyle 的解析与回落。
// 词表是常量、门是纯函数，直接断言，不走数据库。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/asset/prompt_gate.dart';
import 'package:newmove/features/script/art_styles.dart';
import 'package:newmove/features/script/script_models.dart';

Asset asset({
  int id = 1,
  int scriptId = 1,
  String type = '角色',
  String name = '角色',
  String prompt = '',
  String status = '待生成',
  int isStale = 0,
}) => Asset(
  id: id,
  scriptId: scriptId,
  type: type,
  name: name,
  stableId: 'stable-$id',
  boardLayout: '四视图',
  prompt: prompt,
  status: status,
  isStale: isStale,
);

void main() {
  group('ArtStyleCatalog 词表自洽', () {
    test('16 条风格、短名唯一', () {
      expect(ArtStyleCatalog.styles, hasLength(16));
      expect(ArtStyleCatalog.styles.map((s) => s.name).toSet(), hasLength(16));
    });

    test('提示词非空且族名已登记', () {
      for (final style in ArtStyleCatalog.styles) {
        expect(style.prompt.trim(), isNotEmpty, reason: '${style.name} 提示词为空');
        expect(
          ArtStyleCatalog.grouped.keys,
          contains(style.family),
          reason: '${style.name} 的族 ${style.family} 未登记',
        );
      }
    });

    test('按族分组与铺开列表一致', () {
      final grouped = ArtStyleCatalog.grouped.values.expand((list) => list);
      expect(grouped.length, ArtStyleCatalog.styles.length);
      expect(ArtStyleCatalog.styles, orderedEquals(grouped.toList()));
    });

    test('默认画风在词表内且按名可解析', () {
      expect(
        ArtStyleCatalog.byName(ArtStyleCatalog.defaultName),
        ArtStyleCatalog.defaultStyle,
      );
      expect(ArtStyleCatalog.styles, contains(ArtStyleCatalog.defaultStyle));
      expect(
        ArtStyleCatalog.grouped['动漫']!.first,
        ArtStyleCatalog.defaultStyle,
      );
      expect(ArtStyleCatalog.defaultPrompt, equals(defaultArtStyle));
    });
  });

  group('画风提示词与 PromptGate 族关键词同步', () {
    test('每条风格都命中自己声明的族', () {
      for (final style in ArtStyleCatalog.styles) {
        expect(
          PromptGate.styleFamilyOf(style.prompt),
          style.family,
          reason:
              '${style.name} 的提示词没有命中 ${style.family} 族，'
              '或误含其它族关键词（负向分句也会命中）',
        );
      }
    });

    test('同族资产不报警', () {
      for (final group in ArtStyleCatalog.grouped.values) {
        expect(
          PromptGate.styleConflicts([
            for (var i = 0; i < group.length; i++)
              asset(id: i + 1, name: group[i].name, prompt: group[i].prompt),
          ]),
          isEmpty,
        );
      }
    });

    test('三族各取一条即报警并列出族名', () {
      final issues = PromptGate.styleConflicts([
        for (final group in ArtStyleCatalog.grouped.values)
          asset(name: group.first.name, prompt: group.first.prompt),
      ]);
      expect(issues, hasLength(1));
      expect(issues.single.code, 'style_conflict');
      for (final family in ArtStyleCatalog.grouped.keys) {
        expect(issues.single.locator, contains(family));
      }
    });
  });

  group('effectiveArtStyle 解析与回落', () {
    test('空值与纯空白回落到默认提示词', () {
      for (final raw in <String?>[null, '', '   ', '\t']) {
        expect(effectiveArtStyle(raw), defaultArtStyle);
      }
    });

    test('入库短名解析成完整提示词', () {
      for (final style in ArtStyleCatalog.styles) {
        expect(effectiveArtStyle(style.name), style.prompt);
        expect(effectiveArtStyle('  ${style.name}  '), style.prompt);
      }
    });

    test('历史自由文本按原样透传', () {
      const legacy = '手绘水彩，柔和光影，日系插画感';
      expect(effectiveArtStyle(legacy), legacy);
    });

    test('词表化之前的默认文案升级为完整默认提示词', () {
      expect(
        effectiveArtStyle(ArtStyleCatalog.legacyDefaultPrompt),
        defaultArtStyle,
      );
      expect(
        effectiveArtStyle('  ${ArtStyleCatalog.legacyDefaultPrompt}  '),
        defaultArtStyle,
      );
    });
  });

  group('effectiveArtStyleName', () {
    test('空值与未登记文本回落到默认短名', () {
      expect(effectiveArtStyleName(null), ArtStyleCatalog.defaultName);
      expect(effectiveArtStyleName(''), ArtStyleCatalog.defaultName);
      expect(effectiveArtStyleName('某段历史自定义描述'), ArtStyleCatalog.defaultName);
    });

    test('已登记短名原样返回', () {
      for (final style in ArtStyleCatalog.styles) {
        expect(effectiveArtStyleName(style.name), style.name);
      }
    });
  });
}
