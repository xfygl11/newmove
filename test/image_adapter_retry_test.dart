import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/network/image_provider_adapter.dart';

/// 前 [failTimes] 次返回固定状态码，之后返回成功的 b64 图片。
///
/// 响应带 `retry-after: 1`，把重试间隔压到 1 秒，测试不至于等指数退避。
Dio _stubDio({
  required int failTimes,
  required int status,
  required List<String> captured,
  void Function(int call)? onCall,
  Map<String, dynamic> body = const {
    'error': {'message': '上游服务暂时不可用，请稍后重试'},
  },
}) {
  final dio = Dio();
  var calls = 0;
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        calls++;
        captured.add(jsonEncode(options.data));
        onCall?.call(calls);
        if (calls <= failTimes) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: status,
                data: body,
                headers: Headers.fromMap({
                  'retry-after': ['1'],
                }),
              ),
            ),
          );
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': [
                {
                  'b64_json': base64Encode([1, 2, 3]),
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

Future<ImageGenerationResult> _generate(
  ImageProviderAdapter adapter, {
  String size = '1K',
  CancelToken? cancelToken,
}) {
  return adapter.textToImage(
    baseUrl: 'https://example.com/v1',
    apiKey: 'k',
    model: 'm',
    prompt: '一只猫',
    size: size,
    cancelToken: cancelToken,
  );
}

void main() {
  group('图片生成临时故障重试', () {
    test('503 后自动重试并成功返回', () async {
      final captured = <String>[];
      final adapter = ImageProviderAdapter(
        dio: _stubDio(failTimes: 1, status: 503, captured: captured),
        maxRetries: 1,
      );

      final result = await _generate(adapter);

      expect(result.bytes, Uint8List.fromList([1, 2, 3]));
      expect(captured, hasLength(2));
    });

    test('503 重试耗尽后抛出中文原因，不再裸抛 DioException', () async {
      final captured = <String>[];
      final adapter = ImageProviderAdapter(
        dio: _stubDio(failTimes: 99, status: 503, captured: captured),
        maxRetries: 1,
      );

      Object? error;
      try {
        await _generate(adapter);
      } catch (e) {
        error = e;
      }

      expect(error, isA<ImageGenerationException>());
      final message = error.toString();
      expect(message, contains('供应商服务暂时不可用'));
      expect(message, contains('上游服务暂时不可用'));
      expect(message, contains('已重试'));
      expect(captured, hasLength(2));
    });

    test('400 参数错误不重试，直接失败', () async {
      final captured = <String>[];
      final adapter = ImageProviderAdapter(
        dio: _stubDio(failTimes: 99, status: 400, captured: captured),
        maxRetries: 2,
      );

      await expectLater(
        _generate(adapter),
        throwsA(
          isA<ImageGenerationException>().having(
            (e) => e.toString(),
            'message',
            contains('供应商拒绝了请求参数'),
          ),
        ),
      );
      expect(captured, hasLength(1));
    });

    test('退避期间用户取消立即中止，不再重发', () async {
      final captured = <String>[];
      final adapter = ImageProviderAdapter(
        dio: _stubDio(failTimes: 99, status: 503, captured: captured),
        maxRetries: 2,
      );
      final token = CancelToken();
      token.cancel();

      await expectLater(
        _generate(adapter, cancelToken: token),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      // 已取消的 token 在 Dio 发请求前就拒绝，重试根本不会发生。
      expect(captured, isEmpty);
    });

    test('退避期间取消则中止，不再重发', () async {
      final captured = <String>[];
      final token = CancelToken();
      final adapter = ImageProviderAdapter(
        dio: _stubDio(
          failTimes: 99,
          status: 503,
          captured: captured,
          onCall: (call) {
            if (call == 1) token.cancel();
          },
        ),
        maxRetries: 2,
      );

      await expectLater(
        _generate(adapter, cancelToken: token),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(captured, hasLength(1));
    });
  });

  group('请求体边界', () {
    test('size 按调用方透传，不夹带网关拒绝的字段', () async {
      final captured = <String>[];
      final adapter = ImageProviderAdapter(
        dio: _stubDio(failTimes: 0, status: 200, captured: captured),
      );

      await _generate(adapter, size: '1K');
      await _generate(adapter, size: '1024x1024');

      expect(captured, hasLength(2));
      expect(captured[0], contains('"size":"1K"'));
      expect(captured[1], contains('"size":"1024x1024"'));
      for (final body in captured) {
        expect(body, contains('"n":1'));
        expect(body, isNot(contains('"format"')));
        expect(body, isNot(contains('"stream"')));
        expect(body, isNot(contains('"images"')));
      }
    });

    test('未知协议直接抛错，不静默降级', () async {
      final adapter = ImageProviderAdapter(dio: Dio());

      await expectLater(
        adapter.textToImage(
          baseUrl: 'https://example.com/v1',
          apiKey: 'k',
          model: 'm',
          prompt: 'p',
          protocol: 'no-such-protocol',
        ),
        throwsArgumentError,
      );
    });
  });
}
