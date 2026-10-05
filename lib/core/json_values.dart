/// 宽容的 JSON 取值工具。
///
/// AI 返回的 JSON 常出现类型漂移：数字写成字符串（`"seq": "1"`）、
/// 布尔写成字符串（`"accepted": "true"`）、单层值包成数组等。
/// 直接用 `as int?` / `as String?` 强转会在这些情况下抛 TypeError，
/// 导致整段生成结果解析失败。这里统一做「能转就转，转不了用兜底值」。
library;

import 'dart:convert';

/// 取字符串：非 null 一律 `toString()`，null 用 [fallback]。
String jsonString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// 取可空字符串：null 保持 null（用于 `String?` 字段，保留可空语义）。
String? jsonStringOrNull(Object? value) => value?.toString();

/// 取整数：支持 int、可 parse 的 String、double（截断）；其余用 [fallback]。
int jsonInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// 取整数，保留「未知」语义：null / 无法解析一律返回 null。
///
/// 与 [jsonInt] 的区别是它不把未知折叠成 0——「未知」和「0」在能力字段里
/// 含义相反（0 表示明确的无）。禁止用 `as num?` 强转代替：LLM 或手工编辑的
/// JSON 常把数字写成字符串，强转抛 TypeError 会让整条记录解析失败。
int? jsonIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return int.tryParse(text);
}

/// 取布尔：支持 bool、`"true"/"false"/"yes"/"1"` 等字符串；其余用 [fallback]。
bool jsonBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == 'yes' || v == '1') return true;
    if (v == 'false' || v == 'no' || v == '0') return false;
  }
  return fallback;
}

/// 取数组：非数组返回空数组。
List<dynamic> jsonList(Object? value) => value is List ? value : const [];

/// 取对象：非 Map 返回空 Map。
Map<String, dynamic> jsonMap(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

/// 从 LLM 回复中提取 JSON 对象。
///
/// 容忍 markdown 代码块包裹（```json ... ```）以及 JSON 前后的解释文字。
/// 提取失败抛 [FormatException] 并给出可读原因——**不吞成空 Map**：
/// 上层若把空结果当作成功落库，会在删旧数据后插入零条，造成静默数据丢失。
Map<String, dynamic> extractJsonObject(String reply) {
  var text = reply.trim();
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
  final m = fence.firstMatch(text);
  if (m != null) text = m.group(1)!.trim();

  final direct = _decodeObject(text);
  if (direct != null) return direct;

  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start >= 0 && end > start) {
    final sliced = _decodeObject(text.substring(start, end + 1));
    if (sliced != null) return sliced;
  }
  throw const FormatException('AI 返回内容不是有效 JSON，请重试');
}

Map<String, dynamic>? _decodeObject(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } on FormatException {
    return null;
  }
  return null;
}
