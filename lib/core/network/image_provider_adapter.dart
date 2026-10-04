import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'protocols.dart';

/// 图片生成结果：优先本地字节，其次远程 URL。
class ImageGenerationResult {
  const ImageGenerationResult({this.bytes, this.url});

  final Uint8List? bytes;
  final String? url;

  bool get isEmpty => bytes == null && url == null;
}

/// OpenAI Images 兼容适配器：文生图 + 图生图（参考图）。
///
/// 不感知业务语义，仅做协议适配；供应商配置由调用方传入。
/// 协议：`openai-images`（同步返回 b64/URL）。异步任务协议在 M6 视频阶段实现。
class ImageProviderAdapter {
  ImageProviderAdapter({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

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
    final response = await _dio.post<Map<String, dynamic>>(
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
    );
    return _parse(response.data ?? const {});
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
  }

  /// 下载远程图片为本地字节。
  Future<Uint8List> downloadUrl(String url, {CancelToken? cancelToken}) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
    );
    return Uint8List.fromList(response.data ?? const []);
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
}
