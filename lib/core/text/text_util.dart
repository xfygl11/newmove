/// 显示用文本截断的共享入口。
///
/// 提示词、正文、日志都可能含 emoji 等超出 BMP 的字符，它们在 Dart 的
/// UTF-16 字符串里占两个码元。按 `length` 直接 `substring` 可能正好落在
/// 代理对中间，留下孤立低代理；这种字符串一旦进入 `utf8.encode`（网络
/// 请求体、日志落盘）就会抛 FormatException，让一次生成在序列化阶段失败。
class TextUtil {
  TextUtil._();

  /// 按码元截断到 [limit]，切点落在代理对中间时回退一位。
  ///
  /// [limit] 是码元数（`String.length` 单位），不是码点数：日志与提示词
  /// 截断本来按码元数走，语义保持一致。
  static String clip(String text, int limit) {
    if (limit <= 0) return '';
    if (text.length <= limit) return text;
    var end = limit;
    final code = text.codeUnitAt(end);
    if (code >= 0xDC00 && code <= 0xDFFF) end--;
    return text.substring(0, end);
  }
}
