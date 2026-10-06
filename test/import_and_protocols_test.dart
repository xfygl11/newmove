import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/network/protocols.dart';
import 'package:newmove/core/text/chapter_import.dart';
import 'package:newmove/features/shot/shot_compose_service.dart';

void main() {
  group('ChapterImport.readText', () {
    test('超限拒绝读取', () async {
      final dir = await Directory.systemTemp.createTemp('newmove_import_test');
      addTearDown(() async => dir.delete(recursive: true));
      final file = File('${dir.path}/big.txt');
      await file.writeAsBytes(List.filled(ChapterImport.maxBytes + 1, 0));
      expect(
        () => ChapterImport.readText(file.path),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('2MB'),
          ),
        ),
      );
    });

    test('UTF-16LE BOM 解码', () async {
      final dir = await Directory.systemTemp.createTemp('newmove_import_test');
      addTearDown(() async => dir.delete(recursive: true));
      final file = File('${dir.path}/utf16.txt');
      await file.writeAsBytes([
        0xFF, 0xFE, // LE BOM
        0x60, 0x4F, 0x7D, 0x59, 0x16, 0x4E, 0x4C, 0x75,
      ]);
      expect(await ChapterImport.readText(file.path), '你好世界');
    });

    test('不存在的文件抛 StateError', () {
      expect(
        () => ChapterImport.readText('/nonexistent/newmove/none.txt'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ChapterImport.cleanHtml', () {
    test('script/style 块内容不进入正文', () {
      final text = ChapterImport.cleanHtml(
        '<html><body><p>正文</p>'
        '<script>alert(1);var hidden="不应出现";</script>'
        '<style>.x{color:red}</style>'
        '<p>结尾</p></body></html>',
      );
      expect(text, contains('正文'));
      expect(text, contains('结尾'));
      expect(text, isNot(contains('alert')));
      expect(text, isNot(contains('color:red')));
      expect(text, isNot(contains('<p>')));
    });

    test('HTML 实体解码（含数值实体）', () {
      expect(
        ChapterImport.cleanHtml('A &amp; B &nbsp; &#65; &lt;tag&gt;'),
        'A & B A <tag>',
      );
    });

    test('连续空白压缩为单空格', () {
      expect(ChapterImport.cleanHtml('<div> a   b\t\tc </div>'), 'a b c');
    });
  });

  group('ChapterImport.cleanText', () {
    test('html 扩展名走清洗', () {
      expect(ChapterImport.cleanText('<b>粗体</b>', fileName: 'a.HTM'), '粗体');
    });

    test('纯文本只 trim', () {
      expect(
        ChapterImport.cleanText('  <b>保留</b>  ', fileName: 'a.txt'),
        '<b>保留</b>',
      );
    });
  });

  group('ChapterImport.extractTitle', () {
    test('仅在前 5 行内取 H1，正文中部 H1 不顶替标题', () {
      const body = '一行\n二行\n三行\n四行\n五行\n# 文末标题\n后续正文';
      final r = ChapterImport.extractTitle(body, fileName: 'c.txt');
      expect(r.title, 'c');
      expect(r.content, contains('# 文末标题'));
    });

    test('开头 H1 作为标题并从正文剔除', () {
      final r = ChapterImport.extractTitle('# 第一章\n正文内容', fileName: 'c.txt');
      expect(r.title, '第一章');
      expect(r.content, '正文内容');
    });

    test('无标题时回退文件名', () {
      final r = ChapterImport.extractTitle('没有标题', fileName: '我的书.md');
      expect(r.title, '我的书');
      expect(r.content, '没有标题');
    });
  });

  group('ChapterImport.countWords', () {
    test('中文按单字计', () {
      expect(ChapterImport.countWords('你好世界'), 4);
    });

    test('英文按空白分词', () {
      expect(ChapterImport.countWords('Hello world foo'), 3);
    });

    test('中英混排不重复计数', () {
      expect(ChapterImport.countWords('你好 world 的'), 4);
      expect(ChapterImport.countWords('a b c'), 3);
    });

    test('空白与空串不计数', () {
      expect(ChapterImport.countWords(''), 0);
      expect(ChapterImport.countWords('   \n\t  '), 0);
    });
  });

  group('Protocols', () {
    test('分组协议列表', () {
      expect(Protocols.optionsFor('llm'), [
        'openai-completions',
        'openai-chat',
      ]);
      expect(Protocols.optionsFor('image'), [
        'openai-images',
        'openai-images-inline',
      ]);
      expect(Protocols.optionsFor('video'), ['async-task', 'openai-videos']);
      expect(Protocols.optionsFor('nope'), isEmpty);
    });

    test('isSupported 判定', () {
      expect(Protocols.isSupported('video', 'openai-videos'), isTrue);
      expect(Protocols.isSupported('video', 'openai-images'), isFalse);
      expect(Protocols.isSupported('llm', null), isFalse);
      expect(Protocols.isSupported('unknown', 'openai-chat'), isFalse);
    });

    test('require 对未知协议抛 ArgumentError', () {
      expect(
        () => Protocols.require('video', 'openai-images'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Protocols.require('video', 'openai-videos'),
        returnsNormally,
      );
      expect(() => Protocols.require('llm', 'openai-chat'), returnsNormally);
    });
  });

  group('ShotComposeService.safeOutputName', () {
    test('引号与空格被替换为下划线', () {
      expect(ShotComposeService.safeOutputName('我的 "剧本"/成片'), '我的__剧本__成片.mp4');
    });

    test('强制 .mp4 后缀', () {
      expect(ShotComposeService.safeOutputName('abc'), 'abc.mp4');
      expect(ShotComposeService.safeOutputName('abc.MP4'), 'abc.mp4');
    });

    test('去掉前导点，空名回退默认', () {
      expect(ShotComposeService.safeOutputName('...hidden'), 'hidden.mp4');
      expect(ShotComposeService.safeOutputName('///'), 'compose.mp4');
    });
  });
}
