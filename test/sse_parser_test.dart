import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/network/sse_parser.dart';

void main() {
  group('SseByteParser', () {
    test('解析单个 data 事件', () {
      final p = SseByteParser();
      final events = p.push(utf8.encode('data: {"a":1}\n\n'));
      expect(events, ['{"a":1}']);
    });

    test('一次喂入多个事件', () {
      final p = SseByteParser();
      final events = p.push(
        utf8.encode('data: first\n\ndata: second\n\n'),
      );
      expect(events, ['first', 'second']);
    });

    test('多字节字符被分块切断仍能正确解码', () {
      final p = SseByteParser();
      // "你好" 的 UTF-8 字节被拆成两次喂入。
      final bytes = utf8.encode('data: 你好\n\n');
      final cut = 5; // 落在"你"的中间。
      final e1 = p.push(bytes.sublist(0, cut));
      final e2 = p.push(bytes.sublist(cut));
      expect(e1, isEmpty);
      expect(e2, ['你好']);
    });

    test('识别 [DONE] 事件', () {
      final p = SseByteParser();
      final events = p.push(utf8.encode('data: [DONE]\n\n'));
      expect(events, ['[DONE]']);
    });

    test('忽略无 data 的事件与注释行', () {
      final p = SseByteParser();
      final events = p.push(utf8.encode(': comment\n\nevent: ping\ndata: hi\n\n'));
      expect(events, ['hi']);
    });

    test('兼容 \\r\\n 换行', () {
      final p = SseByteParser();
      final events = p.push(utf8.encode('data: ok\r\n\r\n'));
      expect(events, ['ok']);
    });

    test('data 后跟可选空格', () {
      final p = SseByteParser();
      final events = p.push(utf8.encode('data:  hello\n\n'));
      expect(events, ['hello']);
    });
  });
}
