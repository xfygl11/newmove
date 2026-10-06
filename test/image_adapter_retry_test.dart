import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/network/image_provider_adapter.dart';
import 'package:newmove/core/network/protocols.dart';

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
  String protocol = Protocols.openaiImages,
  CancelToken? cancelToken,
}) {
  return adapter.textToImage(
    baseUrl: 'https://example.com/v1',
    apiKey: 'k',
    model: 'm',
    prompt: '一只猫',
    size: size,
    protocol: protocol,
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

    test('内联协议把 response_format 收进 extra_body，顶层不出现', () async {
      final captured = <String>[];
      final adapter = ImageProviderAdapter(
        dio: _stubDio(failTimes: 0, status: 200, captured: captured),
      );

      await _generate(
        adapter,
        size: '1K',
        protocol: Protocols.openaiImagesInline,
      );

      final body = jsonDecode(captured.single) as Map<String, Object?>;
      expect(body, isNot(contains('response_format')));
      expect(
        (body['extra_body'] as Map<String, Object?>)['response_format'],
        'b64_json',
      );
    });
  });

  group('图生图双通道', () {
    /// 用拦截器抓取请求路径与请求体，固定返回成功的 b64 图片。
    Dio captureDio({required List<String> paths, required List<dynamic> bodies}) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            paths.add(options.path);
            bodies.add(options.data);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'data': [
                  {'b64_json': base64Encode([9, 9, 9])},
                ]},
              ),
            );
          },
        ),
      );
      return dio;
    }

    Future<File> tempPng() async {
      final file = File(
        '${Directory.systemTemp.path}/imgtest_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes([0x89, 0x50, 0x4e, 0x47]);
      return file;
    }

    Future<ImageGenerationResult> invoke(
      ImageProviderAdapter adapter,
      List<String> referencePaths, {
      required String protocol,
    }) {
      if (referencePaths.length == 1) {
        return adapter.imageToImage(
          baseUrl: 'https://example.com/v1',
          apiKey: 'k',
          model: 'm',
          prompt: '把参考图改成夜景',
          size: '1K',
          protocol: protocol,
          referencePath: referencePaths.single,
        );
      }
      return adapter.imageToImageMulti(
        baseUrl: 'https://example.com/v1',
        apiKey: 'k',
        model: 'm',
        prompt: '把几张图合成一张',
        size: '1K',
        protocol: protocol,
        referencePaths: referencePaths,
      );
    }

    test('内联协议走 generations，参考图整体编码成 Data URI', () async {
      final ref = await tempPng();
      final paths = <String>[];
      final bodies = <dynamic>[];
      final adapter = ImageProviderAdapter(dio: captureDio(paths: paths, bodies: bodies));

      final result = await invoke(
        adapter,
        [ref.path],
        protocol: Protocols.openaiImagesInline,
      );

      expect(result.bytes, isNotNull);
      expect(paths.single, endsWith('/images/generations'));
      final body = bodies.single as Map<String, Object?>;
      final image = body['image']! as List<String>;
      expect(image.single, startsWith('data:image/png;base64,'));
      // `response_format` 只允许在 extra_body 内，顶层写会被判参数错误。
      expect(body.containsKey('response_format'), isFalse);
      final extra = body['extra_body']! as Map<String, Object?>;
      expect(extra['response_format'], 'b64_json');
      expect(extra['image'], same(image));
    });

    test('multipart 协议走 edits，多张参考图不互相覆盖', () async {
      final ref1 = await tempPng();
      final ref2 = await tempPng();
      final paths = <String>[];
      final bodies = <dynamic>[];
      final adapter = ImageProviderAdapter(dio: captureDio(paths: paths, bodies: bodies));

      final result = await invoke(
        adapter,
        [ref1.path, ref2.path],
        protocol: Protocols.openaiImages,
      );

      expect(result.bytes, isNotNull);
      expect(paths.single, endsWith('/images/edits'));
      final form = bodies.single as FormData;
      expect(form.fields, contains(const MapEntry('response_format', 'b64_json')));
      final names = [for (final entry in form.files) entry.value.filename];
      expect(names, ['reference_1.png', 'reference_2.png']);
    });

    test('参考图张数超过上限时按前 N 张截断', () async {
      final paths = <String>[];
      final bodies = <dynamic>[];
      final adapter = ImageProviderAdapter(dio: captureDio(paths: paths, bodies: bodies));
      final refs = <String>[];
      for (var i = 0; i < ImageProviderAdapter.maxReferences + 3; i++) {
        refs.add((await tempPng()).path);
      }

      await invoke(adapter, refs, protocol: Protocols.openaiImages);

      final form = bodies.single as FormData;
      expect(form.files, hasLength(ImageProviderAdapter.maxReferences));
    });

    test('文生图仍走 generations 且不受图生图协议影响', () async {
      final paths = <String>[];
      final bodies = <dynamic>[];
      final adapter = ImageProviderAdapter(dio: captureDio(paths: paths, bodies: bodies));

      await adapter.textToImage(
        baseUrl: 'https://example.com/v1',
        apiKey: 'k',
        model: 'm',
        prompt: '一只猫',
        size: '1K',
        protocol: Protocols.openaiImages,
      );

      expect(paths.single, endsWith('/images/generations'));
      expect(bodies.single, isA<Map<String, Object?>>());
    });
  });
}
