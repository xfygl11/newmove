import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';

/// 拦截请求并用固定响应应答，避免真实网络。
Dio _stubDio(List<String> captured) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        captured.add(
          options.data is String ? options.data! : jsonEncode(options.data),
        );
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'choices': [
                {
                  'message': {'content': 'ok'},
                },
              ],
            },
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  group('LlmProviderAdapter 请求体清洗', () {
    // 空 content 会触发 DashScope 的
    // InvalidParameter「Unexpected item type in content.」，本地先拦下。
    test('跳过空白消息并去除首尾空白', () async {
      final captured = <String>[];
      final adapter = LlmProviderAdapter(dio: _stubDio(captured));

      final reply = await adapter.chat(
        baseUrl: 'https://example.com/v1',
        apiKey: 'k',
        model: 'm',
        messages: const [
          (role: ChatRole.system, content: ''),
          (role: ChatRole.user, content: '   '),
          (role: ChatRole.user, content: '  你好  '),
        ],
      );

      expect(reply, 'ok');
      expect(captured, hasLength(1));
      expect(captured.single, contains('"messages":['));
      expect(captured.single, contains('你好'));
      expect(captured.single, isNot(contains('"content":""')));
      expect(captured.single, isNot(contains('"content":"   "')));
    });

    test('全部为空时抛 StateError', () async {
      final adapter = LlmProviderAdapter(dio: _stubDio([]));
      await expectLater(
        adapter.chat(
          baseUrl: 'https://example.com/v1',
          apiKey: 'k',
          model: 'm',
          messages: const [
            (role: ChatRole.system, content: ''),
            (role: ChatRole.user, content: '\n\t '),
          ],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('提示词为空'),
          ),
        ),
      );
    });

    test('model 去除首尾空白', () async {
      final captured = <String>[];
      final adapter = LlmProviderAdapter(dio: _stubDio(captured));

      await adapter.chat(
        baseUrl: 'https://example.com/v1',
        apiKey: 'k',
        model: '  qwen-plus  ',
        messages: const [(role: ChatRole.user, content: 'hi')],
      );

      expect(captured.single, contains('"model":"qwen-plus"'));
    });
  });
}
