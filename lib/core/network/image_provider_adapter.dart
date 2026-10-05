import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../text/text_util.dart';
import 'dio_factory.dart';
import 'protocols.dart';

/// 图片生成结果：优先本地字节，其次远程 URL。
class ImageGenerationResult {
  const ImageGenerationResult({this.bytes, this.url});

  final Uint8List? bytes;
  final String? url;

  bool get isEmpty => bytes == null && url == null;
}

/// 图片生成失败：`toString()` 即为可直接展示给用户的中文原因。
///
/// 供应商原始报错常带 base64 片段或超长英文堆栈，直接 `$e` 吐给用户看不出
/// 是哪种问题；这里统一裁成「前缀（状态码 + 归类）+ 供应商消息」。
class ImageGenerationException implements Exception {
  const ImageGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// OpenAI Images 兼容适配器：文生图 + 图生图（参考图）。
///
/// 不感知业务语义，仅做协议适配；供应商配置由调用方传入。
/// 协议：`openai-images`（同步返回 b64/URL）。异步任务协议在 M6 视频阶段实现。
class ImageProviderAdapter {
  ImageProviderAdapter({Dio? dio, int maxRetries = 2})
    : _dio = dio ?? createDio(),
      _maxRetries = maxRetries < 0 ? 0 : maxRetries;

  final Dio _dio;
  final int _maxRetries;

  /// 视为临时故障、值得原样重发的状态码。
  ///
  /// 408/429 是超时与限流；5xx 是网关或上游模型侧故障（供应商文档里对 503
  /// 的处置建议就是「等几分钟重试」）。4xx 参数错误不在此列，重试只会白烧算力。
  static const Set<int> _retryableStatus = {408, 429, 500, 502, 503, 504};

  static const int _backoffSeconds = 2;

  static String _strip(String baseUrl) => baseUrl.replaceAll(RegExp(r'/$'), '');

  /// 拼接文生图端点：`{baseUrl}/images/generations`。
  static String generationsEndpoint(String baseUrl) {
    final trimmed = _strip(baseUrl);
    if (trimmed.endsWith('/images/generations')) return trimmed;
    return '$trimmed/images/generations';
  }

  /// 拼接图生图端点：`{baseUrl}/images/edits`。
  static String editsEndpoint(String baseUrl) {
    final trimmed = _strip(baseUrl);
    if (trimmed.endsWith('/images/edits')) return trimmed;
    return '$trimmed/images/edits';
  }

  /// 文生图。
  Future<ImageGenerationResult> textToImage({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    String size = '1024x1024',
    String protocol = Protocols.openaiImages,
    CancelToken? cancelToken,
  }) async {
    Protocols.require('image', protocol);
    return _withRetry(
      cancelToken: cancelToken,
      attempt: () => _dio
          .post<Map<String, dynamic>>(
            generationsEndpoint(baseUrl),
            data: {
              'model': model,
              'prompt': prompt,
              'n': 1,
              'size': size,
              'response_format': 'b64_json',
            },
            options: _options(apiKey),
            cancelToken: cancelToken,
          )
          .then((response) => _parse(response.data ?? const {})),
    );
  }

  /// 图生图：以 [referencePath] 作为参考底图生成变体，保持身份一致。
  Future<ImageGenerationResult> imageToImage({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required String referencePath,
    String size = '1024x1024',
    String protocol = Protocols.openaiImages,
    CancelToken? cancelToken,
  }) async {
    Protocols.require('image', protocol);
    return _withRetry(
      cancelToken: cancelToken,
      attempt: () async {
        final form = FormData.fromMap({
          'model': model,
          'prompt': prompt,
          'n': 1,
          'size': size,
          'response_format': 'b64_json',
          'image': await MultipartFile.fromFile(
            referencePath,
            filename: 'reference.png',
          ),
        });
        final response = await _dio.post<Map<String, dynamic>>(
          editsEndpoint(baseUrl),
          data: form,
          options: _options(apiKey),
          cancelToken: cancelToken,
        );
        return _parse(response.data ?? const {});
      },
    );
  }

  /// 多参考图图生图：按顺序传入多张参考图，用于「角色+场景」混合一致性。
  ///
  /// 兼容只收单张 `image` 字段的供应商：超过 1 张时只取第一张。
  Future<ImageGenerationResult> imageToImageMulti({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required List<String> referencePaths,
    String size = '1024x1024',
    String protocol = Protocols.openaiImages,
    CancelToken? cancelToken,
  }) async {
    Protocols.require('image', protocol);
    if (referencePaths.isEmpty) {
      throw ArgumentError.value(
        referencePaths,
        'referencePaths',
        '至少需要 1 张参考图',
      );
    }
    final paths = referencePaths.take(16).toList();
    return _withRetry(
      cancelToken: cancelToken,
      attempt: () async {
        final form = FormData.fromMap({
          'model': model,
          'prompt': prompt,
          'n': 1,
          'size': size,
          'response_format': 'b64_json',
          'image': await MultipartFile.fromFile(
            paths.first,
            filename: 'reference.png',
          ),
          for (var i = 1; i < paths.length; i++)
            'image': await MultipartFile.fromFile(
              paths[i],
              filename: 'ref_${i + 1}.png',
            ),
        });
        final response = await _dio.post<Map<String, dynamic>>(
          editsEndpoint(baseUrl),
          data: form,
          options: _options(apiKey),
          cancelToken: cancelToken,
        );
        return _parse(response.data ?? const {});
      },
    );
  }

  /// 下载远程图片为本地字节（同样走临时故障重试）。
  Future<Uint8List> downloadUrl(String url, {CancelToken? cancelToken}) {
    return _withRetry(
      cancelToken: cancelToken,
      attempt: () => _dio
          .get<List<int>>(
            url,
            options: Options(responseType: ResponseType.bytes),
            cancelToken: cancelToken,
          )
          .then((response) => Uint8List.fromList(response.data ?? const [])),
    );
  }

  ImageGenerationResult _parse(Map<String, dynamic> map) {
    final data = map['data'];
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) {
        final b64 = first['b64_json'];
        if (b64 is String && b64.isNotEmpty) {
          return ImageGenerationResult(bytes: base64Decode(b64));
        }
        final url = first['url'];
        if (url is String && url.isNotEmpty) {
          return ImageGenerationResult(url: url);
        }
      }
    }
    return const ImageGenerationResult();
  }

  Options _options(String apiKey) {
    return Options(
      headers: {'Authorization': 'Bearer $apiKey'},
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 5),
    );
  }

  /// 临时故障有限重试：只对可重试状态码与网络超时重发，参数类错误立刻抛出。
  ///
  /// 重试期间逐段指数退避，并遵守供应商的 `Retry-After`；每次重发前检查
  /// 取消标记，用户取消不会被重试吞掉。
  Future<R> _withRetry<R>({
    required CancelToken? cancelToken,
    required Future<R> Function() attempt,
  }) async {
    for (var attemptNo = 0; attemptNo <= _maxRetries; attemptNo++) {
      try {
        return await attempt();
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) rethrow;
        final delay = _retryDelay(e, attemptNo);
        if (delay == null) {
          throw ImageGenerationException(_describeError(e, retried: attemptNo));
        }
        await Future<void>.delayed(delay);
        if (cancelToken != null && cancelToken.isCancelled) {
          throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          );
        }
      }
    }
    throw StateError('unreachable');
  }

  /// 该错误是否值得再发一次；不值得返回 null。
  Duration? _retryDelay(DioException e, int attemptNo) {
    if (attemptNo >= _maxRetries) return null;

    final statusCode = e.response?.statusCode;
    final byStatus =
        statusCode != null && _retryableStatus.contains(statusCode);
    final byNetwork = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
    if (!byStatus && !byNetwork) return null;

    // 供应商明确告知等待时间时优先遵守，同时夹在 1-30 秒之间，
    // 避免供应商返回一个大数把生成流程挂住。
    final retryAfter = e.response?.headers.value('retry-after');
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null && seconds > 0) {
        final capped = seconds > 30 ? 30 : seconds;
        return Duration(seconds: capped);
      }
    }
    return Duration(seconds: _backoffSeconds * (attemptNo + 1));
  }

  /// 把 DioException 裁成用户能看懂的中文原因。
  String _describeError(DioException e, {required int retried}) {
    final code = e.response?.statusCode;
    final tail = retried > 0 ? '（已重试 $retried 次）' : '';
    final detail = _supplierMessage(e);

    final prefix = switch (e.type) {
      DioExceptionType.cancel => '生成已取消',
      DioExceptionType.connectionTimeout => '连接供应商超时',
      DioExceptionType.sendTimeout => '请求发送超时',
      DioExceptionType.receiveTimeout => '等待供应商响应超时',
      DioExceptionType.connectionError => '网络连接失败',
      _ => switch (code) {
        401 || 403 => 'API Key 无效或无权限',
        400 || 404 || 422 => '供应商拒绝了请求参数',
        429 => '供应商请求过于频繁',
        500 || 502 || 503 || 504 => '供应商服务暂时不可用',
        null => '图片生成失败',
        final other => '供应商返回 HTTP $other',
      },
    };

    if (detail == null) return '$prefix$tail';
    // 供应商消息可能是完整 JSON，裁到 300 字避免刷屏。
    final text = TextUtil.clip(detail, 300);
    final head = code == null ? prefix : 'HTTP $code · $prefix';
    return '$head：$text$tail';
  }

  /// 从供应商响应体里挑出可读的错误文本。
  String? _supplierMessage(DioException e) {
    final raw = e.response?.data;
    if (raw is Map) {
      final nested = raw['error'];
      final candidate = switch (nested) {
        Map() => (nested['message'] ?? nested['code'] ?? '').toString(),
        String() => nested,
        _ => raw['message']?.toString() ?? raw['detail']?.toString(),
      };
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (e.message != null && e.message!.isNotEmpty) return e.message;
    return null;
  }
}
