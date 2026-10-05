import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/features/novel/chapter_maintain_gate.dart';

void main() {
  group('ChapterMaintainGate 阈值判定（T21.15）', () {
    test('字数未过阈值不提示', () {
      expect(
        ChapterMaintainGate.issue(
          wordCount: 499,
          aiGenerated: true,
          similarity: 0.1,
        ),
        isNull,
      );
      expect(
        ChapterMaintainGate.issue(
          wordCount: 0,
          aiGenerated: true,
        ),
        isNull,
      );
    });

    test('恰好等于阈值视为未过阈值', () {
      expect(
        ChapterMaintainGate.issue(
          wordCount: maintainWordThreshold,
          aiGenerated: true,
        ),
        isNull,
      );
      expect(
        ChapterMaintainGate.issue(
          wordCount: maintainWordThreshold + 1,
          aiGenerated: true,
        ),
        isNotNull,
      );
    });

    test('非 AI 生成不提示，无论字数多少', () {
      expect(
        ChapterMaintainGate.issue(
          wordCount: 20000,
          aiGenerated: false,
          similarity: 0.1,
        ),
        isNull,
      );
    });

    test('相似度缺失时只做清单提示，跳过重写建议', () {
      final issue = ChapterMaintainGate.issue(
        wordCount: 1200,
        aiGenerated: true,
      );

      expect(issue, isNotNull);
      expect(issue!.wordCount, 1200);
      expect(issue.rewriteSuggested, isFalse);
    });

    test('相似度低于阈值触发全量重写建议', () {
      expect(
        ChapterMaintainGate.issue(
          wordCount: 1200,
          aiGenerated: true,
          similarity: 0.2,
        )!.rewriteSuggested,
        isTrue,
      );
      expect(
        ChapterMaintainGate.issue(
          wordCount: 1200,
          aiGenerated: true,
          similarity: 0.9,
        )!.rewriteSuggested,
        isFalse,
      );
      expect(
        ChapterMaintainGate.issue(
          wordCount: 1200,
          aiGenerated: true,
          similarity: maintainRewriteSimilarity,
        )!.rewriteSuggested,
        isFalse,
      );
    });
  });

  group('ChapterMaintainGate.similarity', () {
    test('空串与超短文本视为测不了，返回 null', () {
      expect(ChapterMaintainGate.similarity('', '任意正文'), isNull);
      expect(ChapterMaintainGate.similarity('短', '短'), isNull);
      expect(ChapterMaintainGate.similarity('   ', '任意正文'), isNull);
    });

    test('完全相同文本相似度为 1', () {
      final text = '阿青沿着荒原走了很远的路，天边的云压得很低，脚步声落在枯草上。';
      expect(ChapterMaintainGate.similarity(text, text), 1.0);
    });

    test('内容完全不同的两段文本相似度低于重写阈值', () {
      final a = '阿青沿着荒原走了很远的路，天边的云压得很低，脚步声落在枯草上。';
      final b = '实验室的灯一整夜没有关过，离心机嗡嗡响，试管里的液体慢慢变色。';
      final s = ChapterMaintainGate.similarity(a, b);
      expect(s, isNotNull);
      expect(s!, lessThan(maintainRewriteSimilarity));
    });

    test('词元数不足时返回 null，不误判为低相似度', () {
      expect(
        ChapterMaintainGate.similarity('三个字', '另外三个字'),
        isNull,
      );
    });
  });

  group('四项目维护清单', () {
    test('四项与 TruthFile 四类状态对应，顺序固定', () {
      expect(maintainChecklist, [
        '角色状态',
        '场景状态',
        '伏笔进展',
        '道具状态',
      ]);
    });

    test('阈值常量单一来源', () {
      expect(maintainWordThreshold, 500);
      expect(maintainRewriteSimilarity, lessThan(1));
      expect(maintainRewriteSimilarity, greaterThan(0));
    });
  });
}
