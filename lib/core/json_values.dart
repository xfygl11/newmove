/// 宽容的 JSON 取值工具。
///
/// AI 返回的 JSON 常出现类型漂移：数字写成字符串（`"seq": "1"`）、
/// 布尔写成字符串（`"accepted": "true"`）、单层值包成数组等。
/// 直接用 `as int?` / `as String?` 强转会在这些情况下抛 TypeError，
/// 导致整段生成结果解析失败。这里统一做「能转就转，转不了用兜底值」。
library;

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
