import 'package:newmove/core/network/dio_factory.dart';
import 'package:dio/dio.dart';

import '../../core/network/protocols.dart';
import 'model_presets.dart';
import 'provider_models.dart';

/// 拉取结果：去重后的模型列表。
typedef FetchedModel = ({String id, String label});

/// 一键获取模型（借鉴 Toonflow `fetchProviderModels` /
/// `refreshMediaProviderModels`，docs/02 §4.1.1）。
///
/// - LLM 组：请求 `{baseUrl}/models`（pathname 为 `/` 时先补 `/v1`）。
/// - 图片/视频组：请求 `{baseUrl}/models?type=image|video` 过滤无关模型。
/// - 鉴权：默认 `Bearer`；anthropic 协议改 `x-api-key` +
///   `anthropic-version: 2023-06-01`（本项目协议词表当前无该值，保留分支）。
/// - 响应 `{ data: [...] }`，label 取 `display_name || displayName ||
///   name || id`。
class ModelFetcher {
  ModelFetcher({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  /// 拼接 /models 端点（媒体组追加 type 查询参数）。
  static String endpoint(
    String baseUrl, {
    bool mediaType = false,
    String? type,
  }) {
    var path = baseUrl.trim();
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    if (path.endsWith('/models')) {
      return mediaType && type != null && type.isNotEmpty
          ? '$path?type=$type'
          : path;
    }
    // 根路径视作「只有 host」，补 /v1（对齐 Toonflow：pathname "/" → "/v1"）。
    final uri = Uri.tryParse(path);
    final needsV1 = uri == null || uri.path.isEmpty || uri.path == '/';
    final base = needsV1 ? '$path/v1' : path;
    final modelsUrl = '$base/models';
    if (mediaType && type != null && type.isNotEmpty) {
      return '$modelsUrl?type=$type';
    }
    return modelsUrl;
  }

  /// 拉取模型列表。失败抛 [DioException]，HTTP 非 2xx 也抛。
  Future<List<FetchedModel>> fetch({
    required String baseUrl,
    required String apiKey,
    required String protocol,
    required ProviderGroup group,
  }) async {
    final isAnthropic = protocol == Protocols.anthropicMessages;
    final headers = <String, String>{'Accept': 'application/json'};
    if (isAnthropic) {
      headers['x-api-key'] = apiKey;
      headers['anthropic-version'] = '2023-06-01';
    } else if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final url = endpoint(
      baseUrl,
      mediaType: group != ProviderGroup.llm,
      type: group == ProviderGroup.image
          ? 'image'
          : group == ProviderGroup.video
          ? 'video'
          : null,
    );

    final response = await _dio.get<Map<String, dynamic>>(
      url,
      options: Options(
        headers: headers,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final map = response.data ?? const {};
    final data = map['data'];
    if (data is! List) {
      throw const FormatException('响应缺少 data 数组');
    }

    final seen = <String>{};
    final result = <FetchedModel>[];
    for (final item in data) {
      if (item is! Map) continue;
      final id = _str(item['id']).trim();
      if (id.isEmpty || !seen.add(id)) continue;
      final label =
          _strOrNull(item['display_name']) ??
          _strOrNull(item['displayName']) ??
          _strOrNull(item['name']) ??
          id;
      result.add((id: id, label: label));
    }
    return result;
  }

  /// 宽容地把 JSON 值转成字符串（兼容数值型 id 等）。
  static String _str(Object? value) => value?.toString() ?? '';

  /// 宽容转字符串，null 保持 null 以保留 `??` 回退语义。
  static String? _strOrNull(Object? value) => value?.toString();

  /// 把拉取结果合并进现有模型列表（docs/02 §4.1.1 合并策略）。
  ///
  /// 同 id 保留既有勾选态与能力字段，仅补 label（现有 label 优先）；
  /// 新模型默认 `enabled: false`，并套用 [ModelPresets] 补全已知能力，
  /// 由用户勾选后进入生成链路。
  static List<ProviderModel> mergeFetched({
    required List<ProviderModel> existing,
    required List<FetchedModel> fetched,
  }) {
    final byId = {for (final m in existing) m.id: m};
    final merged = [
      for (final f in fetched)
        byId.containsKey(f.id)
            ? byId[f.id]!.copyWith(
                label: byId[f.id]!.label.trim().isEmpty ? f.label : null,
              )
            : ModelPresets.apply(
                ProviderModel(id: f.id, label: f.label, enabled: false),
              ),
    ];
    // 保留拉取结果里没有的手填模型，追加在尾部。
    final fetchedIds = {for (final f in fetched) f.id};
    merged.addAll(existing.where((m) => !fetchedIds.contains(m.id)));
    return merged;
  }
}
