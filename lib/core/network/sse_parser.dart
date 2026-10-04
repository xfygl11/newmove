import 'dart:convert';

/// SSE（Server-Sent Events）字节流解析器。
///
/// 按「空行」切分事件，提取 `data:` 字段内容；以字节为单位累积，
/// 完整事件才做 UTF-8 解码，避免多字节字符被分块切断。
class SseByteParser {
  final List<int> _pending = [];

  /// 喂入一段字节，返回本次完整解析出的所有 `data:` 内容。
  List<String> push(List<int> chunk) {
    _pending.addAll(chunk);
    final events = <String>[];
    var i = 0;
    while (i < _pending.length - 1) {
      // 空行分隔符：\n\n 或 \r\n\r\n。
      final isLfLf = _pending[i] == 0x0A && _pending[i + 1] == 0x0A;
      final isCrlfCrlf =
          i + 3 < _pending.length &&
          _pending[i] == 0x0D &&
          _pending[i + 1] == 0x0A &&
          _pending[i + 2] == 0x0D &&
          _pending[i + 3] == 0x0A;

      if (isLfLf || isCrlfCrlf) {
        final sepLen = isLfLf ? 2 : 4;
        final eventBytes = _pending.sublist(0, i);
        _pending.removeRange(0, i + sepLen);
        final data = _extractData(eventBytes);
        if (data != null) events.add(data);
        i = 0;
      } else {
        i++;
      }
    }
    return events;
  }

  /// 从单个事件字节中提取所有 `data:` 行内容（多行用换行连接）。
  String? _extractData(List<int> eventBytes) {
    if (eventBytes.isEmpty) return null;
    // ACT: 供应商偶发畸形 UTF-8 字节时降级替换而非抛异常中断整条流；
    // 若后续需严格校验，可改为先 try decode 再走 allowMalformed 回退。
    final text = utf8.decode(eventBytes, allowMalformed: true);
    final dataLines = <String>[];
    for (final rawLine in text.split('\n')) {
      var line = rawLine;
      if (line.startsWith('data:')) {
        line = line.substring(5);
        // 规范允许 data: 后跟一个可选空格。
        if (line.startsWith(' ')) line = line.substring(1);
        dataLines.add(line);
      }
    }
    if (dataLines.isEmpty) return null;
    return dataLines.join('\n');
  }
}
