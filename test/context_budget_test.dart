import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/features/novel/context_budget.dart';
import 'package:newmove/features/novel/truth_file_kinds.dart';

void main() {
  group('ContextBudget.estimateTokens', () {
    test('CJK 单字按 1 token，其余按 4 字符 1 token', () {
      expect(ContextBudget.estimateTokens(''), 0);
      expect(ContextBudget.estimateTokens('你好世界'), 4);
      expect(ContextBudget.estimateTokens('abcd'), 1);
      expect(ContextBudget.estimateTokens('abcdabcdabcdabcd'), 4);
      expect(ContextBudget.estimateTokens('你好 abcd'), 3);
    });
  });

  group('ContextBudget.budgetTruthFiles', () {
    test('保护级 kind 永不丢弃，压缩池超限整体丢弃', () {
      final texts = {
        TruthFileKind.characterMatrix: '{"characters":[]}',
        TruthFileKind.worldFacts: '{"facts":[]}',
        TruthFileKind.hooks: '{"hooks":[]}',
      };
      // 预算耗尽（fixed 已超容量），压缩池必丢、保护级仍在。
      final b = const ContextBudget(maxTokens: 128)
          .budgetTruthFiles(texts, fixedContext: 'x' * 200);
      expect(b.texts.containsKey(TruthFileKind.characterMatrix), isTrue);
      expect(b.texts.containsKey(TruthFileKind.worldFacts), isTrue);
      expect(b.texts.containsKey(TruthFileKind.hooks), isFalse);
      expect(b.note, contains('伏笔'));
    });

    test('伏笔只留 open / progressing，无 status 按未闭合保留', () {
      final texts = {
        TruthFileKind.hooks: jsonEncode({
          'hooks': [
            {'id': 'h1', 'status': 'open'},
            {'id': 'h2', 'status': 'progressing'},
            {'id': 'h3', 'status': 'resolved'},
            {'id': 'h4', 'desc': '无状态'},
          ],
        }),
      };
      final b = const ContextBudget(
        maxTokens: 4096,
        headroom: 0,
      ).budgetTruthFiles(texts, fixedContext: '');
      final decoded =
          jsonDecode(b.texts[TruthFileKind.hooks]!) as Map<String, dynamic>;
      final hooks = decoded['hooks']! as List<dynamic>;
      expect(hooks, hasLength(3));
      expect(hooks.map((h) => (h as Map)['id']), isNot(contains('h3')));
    });

    test('章节摘要只留最近 N 章并按章号升序返回', () {
      final rows = [
        for (var i = 1; i <= 20; i++)
          {'chapterNumber': i, 'summary': '第 $i 章摘要'},
      ];
      final texts = {
        TruthFileKind.chapterSummaries: jsonEncode({'rows': rows}),
      };
      final b = const ContextBudget(
        maxTokens: 4096,
        headroom: 0,
        recentSummaryChapters: 3,
      ).budgetTruthFiles(texts, fixedContext: '');
      final decoded = jsonDecode(
        b.texts[TruthFileKind.chapterSummaries]!,
      ) as Map<String, dynamic>;
      expect(decoded['pruned'], 17);
      final numbers = ((decoded['rows']! as List<dynamic>)
          .map((r) => ((r as Map)['chapterNumber'] as num).toInt())
          .toList());
      expect(numbers, [18, 19, 20]);
    });

    test('预算充足时不裁剪', () {
      final texts = {
        TruthFileKind.characterMatrix: '{"characters":[]}',
        TruthFileKind.hooks: '{"hooks":[]}',
        TruthFileKind.resources: '{"items":[]}',
      };
      final b = const ContextBudget(
        maxTokens: 32768,
        headroom: 0,
      ).budgetTruthFiles(texts, fixedContext: '');
      expect(b.dropped, isEmpty);
      expect(b.fits, isTrue);
      expect(b.note, isEmpty);
    });
  });

  group('ContextBudget.fitSourceTexts', () {
    test('超出剩余预算的章节整篇丢弃，至少保留一篇', () {
      final ctx = const ContextBudget(maxTokens: 200, headroom: 0);
      final texts = ['第一章正文' * 100, '第二章正文' * 100, '第三章正文' * 100];
      final r = ctx.fitSourceTexts(texts, reservedTokens: 50);
      expect(r.texts, hasLength(1));
      expect(r.droppedCount, 2);
    });

    test('预算足够时全部保留', () {
      final ctx = const ContextBudget(maxTokens: 4096, headroom: 0);
      final r = ctx.fitSourceTexts(['第一章', '第二章'], reservedTokens: 10);
      expect(r.droppedCount, 0);
      expect(r.texts, hasLength(2));
    });
  });
}
