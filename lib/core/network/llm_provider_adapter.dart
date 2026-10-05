import 'dart:convert';

import 'package:dio/dio.dart';

import 'dio_factory.dart';
import 'sse_parser.dart';

/// 消息角色。
enum ChatRole { system, user, assistant }

/// OpenAI 兼容 LLM 适配器：`/chat/completions` + SSE 流式。
///
/// 不感知业务语义，仅做协议适配；供应商配置由调用方传入。
class LlmProviderAdapter {
  LlmProviderAdapter({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  /// 拼接 `/chat/completions` 端点。
  static String endpoint(String baseUrl) {
    final trimmed = baseUrl.replaceAll(RegExp(r'/$'), '');
    if (trimmed.endsWith('/chat/completions')) return trimmed;
    return '$trimmed/chat/completions';
  }

  /// 流式对话，逐段产出增量文本。
  Stream<String> chatStream({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<({ChatRole role, String content})> messages,
    double temperature = 0.8,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      endpoint(baseUrl),
      data: _buildBody(model, messages, temperature, stream: true),
      options: _options(apiKey, stream: true),
    );

    final body = response.data;
    if (body == null) return;

    final parser = SseByteParser();
    await for (final chunk in body.stream) {
      for (final event in parser.push(chunk)) {
        if (event == '[DONE]') return;
        final content = _extractDeltaContent(event);
        if (content != null && content.isNotEmpty) {
          yield content;
        }
      }
    }
  }

  /// 非流式对话，返回完整回复文本（用于 JSON 输出等场景）。
  Future<String> chat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<({ChatRole role, String content})> messages,
    double temperature = 0.8,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint(baseUrl),
      data: _buildBody(model, messages, temperature, stream: false),
      options: _options(apiKey, stream: false),
    );

    final map = response.data ?? const {};
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) return '';
    final first = choices.first;
    if (first is! Map) return '';
    final message = first['message'];
    if (message is! Map) return '';
    final content = message['content'];
    return content is String ? content : '';
  }

  /// 连接测试：发送一条最小请求，验证 BaseUrl / Key / 模型可用。
  ///
  /// 成功返回 null，失败抛出 [DioException]。
  Future<void> testConnection({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      endpoint(baseUrl),
      data: _buildBody(
        model,
        const [(role: ChatRole.user, content: '请仅回复"ok"两个字。')],
        0,
        stream: false,
      ),
      options: _options(apiKey, stream: false),
    );
  }

  Map<String, dynamic> _buildBody(
    String model,
    List<({ChatRole role, String content})> messages,
    double temperature, {
    required bool stream,
  }) {
    // 跳过空内容消息：DashScope 等供应商对空 content 返回
    // InvalidParameter「Unexpected item type in content.」，不可读。
    final kept = messages
        .where((m) => m.content.trim().isNotEmpty)
        .map((m) => {'role': m.role.name, 'content': m.content.trim()})
        .toList();
    if (kept.isEmpty) {
      throw StateError('提示词为空，无法发起 LLM 请求');
    }
    return {
      'model': model.trim(),
      'messages': kept,
      'temperature': temperature,
      'stream': stream,
    };
  }

  Options _options(String apiKey, {required bool stream}) {
    return Options(
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      responseType: stream ? ResponseType.stream : ResponseType.json,
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: stream
          ? const Duration(minutes: 5)
          : const Duration(minutes: 2),
    );
  }

  /// 从流式事件 JSON 中提取 `choices[0].delta.content`。
  String? _extractDeltaContent(String jsonText) {
    try {
      final map = jsonDecode(jsonText);
      if (map is! Map<String, dynamic>) return null;
      final choices = map['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final delta = first['delta'];
      if (delta is! Map) return null;
      final content = delta['content'];
      return content is String ? content : null;
    } on FormatException {
      return null;
    }
  }
}
