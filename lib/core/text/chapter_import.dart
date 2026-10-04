import 'dart:convert';
import 'dart:io';

/// 章节文本导入与正文清洗的共享入口。
///
/// 书架页导入、章节编辑器导入、上下文预算切块都走这里，避免各处各自
/// 实现一套 HTML 剥离与字数算法（此前 HTML 只剥标签、`<script>` 内容会
/// 进正文并进 LLM 提示词；字数用 `content.length` 把字符数当字数）。
class ChapterImport {
  ChapterImport._();

  /// 单文件导入上限 2MB，防止整文件读入内存后拖垮渲染。
  static const int maxBytes = 2 * 1024 * 1024;

  /// 读取并按 BOM 判定编码解码（utf-8 / utf-8-bom / utf-16le / utf-16be）。
  ///
  /// 超限抛 [StateError]；BOM 未知时按 UTF-8 宽容解码，无法读出的字节替换为
  /// U+FFFD，保留能读到的部分。
  static Future<String> readText(String path) async {
    final file = File(path);
    if (!file.existsSync()) throw StateError('文件不存在：$path');
    if (file.lengthSync() > maxBytes) {
      throw StateError('文件超过 2MB 上限');
    }
    final bytes = await file.readAsBytes();
    var text = utf8.decode(bytes, allowMalformed: true);
    // UTF-16 BOM（Windows 记事本/导出常见）单独解码。
    if (bytes.length >= 2 &&
        ((bytes[0] == 0xFF && bytes[1] == 0xFE) ||
            (bytes[0] == 0xFE && bytes[1] == 0xFF))) {
      text = _utf16(bytes);
    }
    return text;
  }

  /// UTF-16 解码：识别 LE/BE BOM，处理代理对，控制字符丢弃。
  ///
  /// `dart:convert` 仅提供 UTF-8，UTF-16 需自行按码元解码。
  static String _utf16(List<int> bytes) {
    var data = bytes;
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      data = List<int>.of(bytes.sublist(2));
      for (var i = 0; i + 1 < data.length; i += 2) {
        final t = data[i];
        data[i] = data[i + 1];
        data[i + 1] = t;
      }
    } else {
      data = bytes.sublist(2);
    }
    final buf = StringBuffer();
    for (var i = 0; i + 1 < data.length; i += 2) {
      var code = data[i] | (data[i + 1] << 8);
      if (code >= 0xD800 && code <= 0xDBFF && i + 3 < data.length) {
        final low = data[i + 2] | (data[i + 3] << 8);
        if (low >= 0xDC00 && low <= 0xDFFF) {
          code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00);
          i += 2;
        }
      }
      if (code >= 0x20 && code != 0x7F) {
        buf.write(String.fromCharCode(code));
      }
    }
    return buf.toString();
  }

  /// 按扩展名分流：HTML 走清洗，其余按纯文本处理。
  static String cleanText(String content, {required String fileName}) {
    return fileName.toLowerCase().endsWith('.html') ||
            fileName.toLowerCase().endsWith('.htm')
        ? cleanHtml(content)
        : content.trim();
  }

  /// 剥离 `<script>` / `<style>` 块（先剥内容再剥标签），HTML 实体替换，
  /// 空行压缩，并把连续空白压成单个空格。
  static String cleanHtml(String content) {
    var text = content.replaceAllMapped(
      RegExp(
        '<script[^>]*>.*?</script\\s*>',
        caseSensitive: false,
        dotAll: true,
      ),
      (_) => '\n',
    );
    text = text.replaceAllMapped(
      RegExp('<style[^>]*>.*?</style\\s*>', caseSensitive: false, dotAll: true),
      (_) => '\n',
    );
    text = text.replaceAll(RegExp(r'<[^>]+>'), '\n');
    for (var i = 0; i < 2; i++) {
      text = text.replaceAll('&amp;', '&');
    }
    text = text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(
          RegExp(r'&#(\d{1,6});'),
          (m) => _numEntity(m.group(1)!),
        )
        .replaceAll(RegExp(r'\s+'), ' ');
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static String _numEntity(String digits) {
    final code = int.tryParse(digits);
    if (code == null || code < 32 || code > 0x10FFFF) return '';
    return String.fromCharCode(code);
  }

  /// 取标题与正文。
  ///
  /// 标题取首段内第一个 H1（不跨标题，避免文末标题顶掉真实标题）；无标题时
  /// 用去掉扩展名的文件名。返回的正文已去掉用于取标题的那一行。
  static ({String title, String content}) extractTitle(
    String content, {
    String? fileName,
  }) {
    final fallback = (fileName ?? '')
        .replaceAll(RegExp(r'\.(md|markdown|html|htm|txt)$'), '')
        .trim();
    final lines = content.split('\n');
    for (var i = 0; i < lines.length && i < 5; i++) {
      final match = RegExp(r'^#\s+(.+)$').firstMatch(lines[i].trim());
      if (match == null) continue;
      final title = match.group(1)!.trim();
      final rest = [...lines.sublist(0, i), ...lines.sublist(i + 1)].join('\n');
      return (title: title.isNotEmpty ? title : fallback, content: rest.trim());
    }
    return (title: fallback, content: content.trim());
  }

  /// 词数统计：中文/日文按单字计、其余按空白分词，不再用 `content.length`。
  static int countWords(String content) {
    final text = content.trim();
    if (text.isEmpty) return 0;
    final cjkPattern = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');
    final cjkCount = cjkPattern.allMatches(text).length;
    // 先剔除 CJK 字符再按空白分词，避免中英混排时同一串被重复计数。
    final rest = text.replaceAll(cjkPattern, ' ');
    final wordCount = rest
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return cjkCount + wordCount;
  }
}
