import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'dio_factory.dart';
import 'protocols.dart';

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
  VideoProviderAdapter({Dio? dio}) : _dio = dio ?? createDio();

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
  /// [protocol] 决定端点格式：
  ///   - `async-task`（默认）：`POST {base}/video/generateVideo`
  ///   - `openai-videos`（Agnes）：`POST {base}/videos`
  /// [model] 在 openai-videos 轮询时作 `model_name` 传参。
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
    String protocol = Protocols.asyncTask,
    CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    Protocols.require('video', protocol);
    if (protocol == Protocols.openaiVideos) {
      return _submitOpenAiVideos(
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
        prompt: prompt,
        durationSec: durationSec,
        ratio: ratio,
        resolution: resolution,
        referencePaths: referencePaths,
        firstFramePath: firstFramePath,
        maxImageRefs: maxImageRefs,
        cancelToken: cancelToken,
      );
    }
    return _submitAsyncTask(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      prompt: prompt,
      durationSec: durationSec,
      ratio: ratio,
      resolution: resolution,
      referencePaths: referencePaths,
      firstFramePath: firstFramePath,
      maxImageRefs: maxImageRefs,
      generateAudio: generateAudio,
      cancelToken: cancelToken,
    );
  }

  /// 轮询一次任务状态；非终态返回 [VideoTaskSnapshot.isRunning]。
  ///
  /// [protocol] 与 [submit] 对应；[model] 在 `openai-videos` 协议时必填。
  Future<VideoTaskSnapshot> poll({
    required String baseUrl,
    required String apiKey,
    required String taskId,
    String model = '',
    String protocol = Protocols.asyncTask,
    CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    Protocols.require('video', protocol);
    if (protocol == Protocols.openaiVideos) {
      return _pollOpenAiVideos(
        baseUrl: baseUrl,
        apiKey: apiKey,
        taskId: taskId,
        model: model,
        cancelToken: cancelToken,
      );
    }
    return _pollAsyncTask(
      baseUrl: baseUrl,
      apiKey: apiKey,
      taskId: taskId,
      cancelToken: cancelToken,
    );
  }

  // ---- async-task 协议（现有行为，保持向后兼容） ----

  Future<String> _submitAsyncTask({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required int durationSec,
    required String ratio,
    required String resolution,
    required List<String> referencePaths,
    String? firstFramePath,
    required int maxImageRefs,
    required bool generateAudio,
    CancelToken? cancelToken,
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
          'url':
              'data:image/png;base64,${base64Encode(await File(p).readAsBytes())}',
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
      cancelToken: cancelToken,
    );

    final data = response.data?['data'];
    if (data is! String || data.isEmpty) {
      throw StateError('供应商未返回任务 ID');
    }
    return data;
  }

  Future<VideoTaskSnapshot> _pollAsyncTask({
    required String baseUrl,
    required String apiKey,
    required String taskId,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      statusEndpoint(baseUrl),
      data: {'taskICode': taskId},
      options: _options(apiKey),
      cancelToken: cancelToken,
    );

    final map = response.data ?? const {};
    final data = map['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final rawStatus = (map['status'] ?? dataMap['status'] ?? 'running')
        .toString()
        .toLowerCase();

    if (rawStatus == 'success' || rawStatus == 'completed') {
      final result = dataMap['data'];
      if (result is String && result.startsWith('data:')) {
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

  // ---- openai-videos 协议（Agnes AI） ----
  //
  // 提交：POST {base}/videos
  //   body: { model, prompt, size, seconds: "4"~"12", n: 1,
  //           mode: text|keyframe|reference, images?: [dataUri...],
  //           first_frame?: dataUri, last_frame?: dataUri }
  //   response: { video_id, model_name, status, ... }
  //
  // 轮询：GET {baseWithoutV1}/agnesapi?video_id={id}&model_name={model}
  //   response: { status: pending|processing|completed|failed, url }

  Future<String> _submitOpenAiVideos({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required int durationSec,
    required String ratio,
    required String resolution,
    required List<String> referencePaths,
    String? firstFramePath,
    required int maxImageRefs,
    CancelToken? cancelToken,
  }) async {
    final images = <dynamic>[];
    if (firstFramePath != null) {
      images.add(
        'data:image/png;base64,${base64Encode(await File(firstFramePath).readAsBytes())}',
      );
    }
    for (final p in referencePaths.take(maxImageRefs)) {
      images.add(
        'data:image/png;base64,${base64Encode(await File(p).readAsBytes())}',
      );
    }

    final mode = (images.isNotEmpty || firstFramePath != null)
        ? 'keyframe'
        : 'text';

    final body = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'size': resolution, // e.g. "720P", "1080P", "1K", "2K"
      'seconds': durationSec.toString(), // "4"~"12"
      'n': 1,
      'mode': mode,
      if (images.isNotEmpty) 'images': images,
    };

    final endpoint = _openAiVideosEndpoint(baseUrl);
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: body,
      options: _options(apiKey),
      cancelToken: cancelToken,
    );

    final map = response.data ?? const {};
    // Agnes 返回顶层 video_id（兼容 task_id / id）。
    final videoId = map['video_id'] ?? map['task_id'] ?? map['id'];
    if (videoId == null || videoId.toString().isEmpty) {
      final detail = map.toString();
      throw StateError(
        'Agnes 视频供应商未返回任务 ID: '
        '${detail.length < 200 ? detail : detail.substring(0, 200)}',
      );
    }
    return videoId.toString();
  }

  Future<VideoTaskSnapshot> _pollOpenAiVideos({
    required String baseUrl,
    required String apiKey,
    required String taskId,
    required String model,
    CancelToken? cancelToken,
  }) async {
    // 轮询端点在 host 根路径（非 /v1 子路径），故 strip /v1。
    final pollUrl =
        '${_openAiVideosPollHost(baseUrl)}?video_id=${Uri.encodeComponent(taskId)}'
        '&model_name=${Uri.encodeComponent(model)}';

    final response = await _dio.get<Map<String, dynamic>>(
      pollUrl,
      options: _options(apiKey),
      cancelToken: cancelToken,
    );

    final map = response.data ?? const {};
    final rawStatus = (map['status'] ?? 'running').toString().toLowerCase();

    if (rawStatus == 'completed' || rawStatus == 'success') {
      final url = map['url'];
      if (url is! String || url.isEmpty) {
        throw StateError('Agnes 轮询成功但未返回视频 URL');
      }
      return VideoTaskSnapshot(taskId: taskId, status: 'success', url: url);
    }
    if (rawStatus == 'failed' || rawStatus == 'failure') {
      final reason = map['error'] ?? map['fail_reason'];
      return VideoTaskSnapshot(
        taskId: taskId,
        status: 'failed',
        error: reason?.toString() ?? '视频生成失败',
      );
    }
    return VideoTaskSnapshot(taskId: taskId, status: 'running');
  }

  /// `{base}/videos`（base 含 `/v1`）。
  static String _openAiVideosEndpoint(String baseUrl) =>
      '${_strip(baseUrl)}/videos';

  /// `{host}/agnesapi`（去掉 `/v1` 前缀，host 根路径）。
  static String _openAiVideosPollHost(String baseUrl) {
    final base = _strip(baseUrl);
    // base 形如 https://host/v1，返回 https://host
    if (base.endsWith('/v1')) {
      return base.substring(0, base.length - 3);
    }
    return base;
  }

  /// 下载视频为字节。
  Future<Uint8List> downloadUrl(String url, {CancelToken? cancelToken}) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  /// 取消令牌已置位时立即抛出，使生成流程按普通失败处理并回滚状态。
  static void _throwIfCancelled(CancelToken? token) {
    if (token != null && token.isCancelled) {
      throw StateError('已取消');
    }
  }

  Options _options(String apiKey) {
    return Options(
      headers: {'Authorization': 'Bearer $apiKey'},
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 5),
    );
  }
}
