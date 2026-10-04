import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 视频生成任务的三态快照（提交后 → 轮询中 → 终态）。
class VideoTaskSnapshot {
  const VideoTaskSnapshot({
    required this.taskId,
    required this.status,
    this.url,
    this.base64,
    this.error,
  });

  final String taskId;

  /// running / success / failed
  final String status;
  final String? url;
  final String? base64;
  final String? error;

  bool get isRunning => status == 'running';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
}

/// 异步任务协议视频供应商适配器（参考 Toonflow tfRouter 三步流）。
///
/// 步骤：
/// 1. `POST {base}/video/generateVideo` → `{ data: taskId }`
/// 2. 轮询 `POST {base}/video/getVideoStatus` `{ taskICode }` → `{ status, data }`
/// 3. 成功取 `data.data`（URL 或 `data:video/mp4;base64,...`）
///
/// 不感知业务语义；供应商配置由调用方传入。轮询由调用方驱动，
/// 便于 App 前台恢复轮询、后台暂停。
class VideoProviderAdapter {
  VideoProviderAdapter({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static String _strip(String baseUrl) => baseUrl.replaceAll(RegExp(r'/$'), '');

  /// 拼接视频生成端点：`{base}/video/generateVideo`。
  static String generateEndpoint(String baseUrl) =>
      '${_strip(baseUrl)}/video/generateVideo';

  /// 拼接视频状态端点：`{base}/video/getVideoStatus`。
  static String statusEndpoint(String baseUrl) =>
      '${_strip(baseUrl)}/video/getVideoStatus';

  /// 提交视频生成任务，返回 taskId。
  ///
  /// [referencePaths] 为参考图本地路径（如分镜图/资产图），转 data URI 上传；
  /// [firstFramePath] 非空时以 `first_frame` 角色单独提交（首帧通道，A9.2）；
  /// [maxImageRefs] 为图片参考数量上限（模型能力，默认 9）。
  Future<String> submit({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required int durationSec,
    required String ratio,
    required String resolution,
    List<String> referencePaths = const [],
    String? firstFramePath,
    int maxImageRefs = 9,
    bool generateAudio = false,
  }) async {
    final references = <Map<String, dynamic>>[];
    var budget = maxImageRefs < 1 ? 1 : maxImageRefs;
    if (firstFramePath != null && budget > 0) {
      references.add({
        'role': 'first_frame',
        'type': 'image_url',
        'image_url': {
          'url':
              'data:image/png;base64,${base64Encode(await File(firstFramePath).readAsBytes())}',
        },
      });
      budget--;
    }
    for (final p in referencePaths.take(budget)) {
      references.add({
        'role': 'reference_image',
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/png;base64,${base64Encode(await File(p).readAsBytes())}',
        },
      });
    }

    final body = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'duration': durationSec,
      'ratio': ratio,
      'resolution': resolution,
      'generate_audio': generateAudio,
      if (references.isNotEmpty)
        'metadata': {'ratio': ratio, 'references': references},
    };

    final response = await _dio.post<Map<String, dynamic>>(
      generateEndpoint(baseUrl),
      data: body,
      options: _options(apiKey),
    );

    final data = response.data?['data'];
    if (data is! String || data.isEmpty) {
      throw StateError('供应商未返回任务 ID');
    }
    return data;
  }

  /// 轮询一次任务状态；非终态返回 [VideoTaskSnapshot.isRunning]。
  Future<VideoTaskSnapshot> poll({
    required String baseUrl,
    required String apiKey,
    required String taskId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      statusEndpoint(baseUrl),
      data: {'taskICode': taskId},
      options: _options(apiKey),
    );

    final map = response.data ?? const {};
    final data = map['data'];
    final dataMap = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final rawStatus =
        (map['status'] ?? dataMap['status'] ?? 'running').toString().toLowerCase();

    if (rawStatus == 'success' || rawStatus == 'completed') {
      final result = dataMap['data'];
      if (result is String && result.startsWith('data:')) {
        // data:video/mp4;base64,xxxx
        final idx = result.indexOf(';base64,');
        return VideoTaskSnapshot(
          taskId: taskId,
          status: 'success',
          base64: idx >= 0 ? result.substring(idx + 8) : result,
        );
      }
      return VideoTaskSnapshot(
        taskId: taskId,
        status: 'success',
        url: result?.toString(),
      );
    }
    if (rawStatus == 'failed' || rawStatus == 'failure') {
      final reason = dataMap['failReason'];
      return VideoTaskSnapshot(
        taskId: taskId,
        status: 'failed',
        error: reason?.toString() ?? '视频生成失败',
      );
    }
    return VideoTaskSnapshot(taskId: taskId, status: 'running');
  }

  /// 下载视频为字节。
  Future<Uint8List> downloadUrl(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Options _options(String apiKey) {
    return Options(
      headers: {'Authorization': 'Bearer $apiKey'},
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 5),
    );
  }
}
