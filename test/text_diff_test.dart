import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/text/text_diff.dart';

/// 把 diff 压缩成易断言的字符串：`= 行` / `+ 行` / `- 行`。
String _sig(List<DiffLine> diff) =>
    diff.map((d) => '${switch (d.op) {
      DiffOp.equal => '=',
      DiffOp.insert => '+',
      DiffOp.delete => '-',
    }} ${d.text}').join('\n');

void main() {
  group('TextDiff.lines', () {
    test('两版完全一致 → 全 equal 且无变化', () {
      final diff = TextDiff.lines('a\nb\nc', 'a\nb\nc');
      expect(TextDiff.hasChange(diff), isFalse);
      expect(diff.every((d) => d.op == DiffOp.equal), isTrue);
    });

    test('纯新增一行', () {
      final diff = TextDiff.lines('a\nc', 'a\nb\nc');
      expect(_sig(diff), '= a\n+ b\n= c');
    });

    test('纯删除一行', () {
      final diff = TextDiff.lines('a\nb\nc', 'a\nc');
      expect(_sig(diff), '= a\n- b\n= c');
    });

    test('中间整段替换', () {
      final diff = TextDiff.lines('a\nb\nc\nd', 'a\nx\ny\nd');
      expect(_sig(diff), '= a\n- b\n- c\n+ x\n+ y\n= d');
    });

    test('旧文为空 → 全部新增', () {
      final diff = TextDiff.lines('', 'a\nb');
      expect(TextDiff.hasChange(diff), isTrue);
      expect(diff.every((d) => d.op == DiffOp.insert), isTrue);
    });

    test('新文为空 → 全部删除', () {
      final diff = TextDiff.lines('a\nb', '');
      expect(diff.every((d) => d.op == DiffOp.delete), isTrue);
    });

    test('规模超上限退化为整块替换（结果仍正确）', () {
      final oldText = List.generate(1200, (i) => 'old$i').join('\n');
      final newText = List.generate(1200, (i) => 'new$i').join('\n');
      final diff = TextDiff.lines(oldText, newText);
      expect(diff.where((d) => d.op == DiffOp.delete).length, 1200);
      expect(diff.where((d) => d.op == DiffOp.insert).length, 1200);
      expect(diff.any((d) => d.op == DiffOp.equal), isFalse);
    });

    test('重建后等于新文本（不丢不重）', () {
      const oldText = '第一章\n勇者出发\n遇见同伴\n踏上旅途';
      const newText = '第一章\n勇者出发\n遭遇魔物\n遇见同伴\n踏上旅途';
      final diff = TextDiff.lines(oldText, newText);
      final rebuilt = diff
          .where((d) => d.op != DiffOp.delete)
          .map((d) => d.text)
          .join('\n');
      expect(rebuilt, newText);
    });
  });
}
