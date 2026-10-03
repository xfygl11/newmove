import 'dart:convert';

/// 供应商分组。
enum ProviderGroup {
  llm('LLM 文本'),
  image('图片'),
  video('视频');

  const ProviderGroup(this.label);

  final String label;

  static ProviderGroup fromValue(String value) {
    return ProviderGroup.values.firstWhere(
      (g) => g.name == value,
      orElse: () => ProviderGroup.llm,
    );
  }
}

/// 模型条目（序列化在 [ProviderModelCodec]）。
///
/// [enabled] 为勾选态（借鉴 Toonflow 模型勾选）：false 时模型不出现在
/// 生成链路（模型下拉/active* 选择）。序列化缺省视为 true，兼容旧数据。
/// 能力字段（imageSizes/imageRatios/durationResolutions/audio/contextWindow/
/// maxOutputTokens）借鉴 Toonflow `MediaModel`，全部可选；缺省时 UI 落回
/// 通用词表，能力未知不猜测（docs/02 §4.1.2）。
class ProviderModel {
  const ProviderModel({
    required this.id,
    required this.label,
    this.enabled = true,
    this.imageSizes,
    this.imageRatios,
    this.durationResolutions,
    this.audio,
    this.contextWindow,
    this.maxOutputTokens,
  });

  final String id;
  final String label;
  final bool enabled;

  /// 图片模型可选尺寸（如 `1024x1024`），null 表示未知。
  final List<String>? imageSizes;

  /// 图片模型可选画幅（如 `16:9`），null 表示未知。
  final List<String>? imageRatios;

  /// 视频模型「时长(秒) ↔ 分辨率」合法组合，null 表示未知。
  final List<({List<int> duration, List<String> resolution})>?
  durationResolutions;

  /// 音频能力：true 必带 / false 不带 / "optional" 可选；null 未知。
  final Object? audio;

  final int? contextWindow;
  final int? maxOutputTokens;

  ProviderModel copyWith({
    String? id,
    String? label,
    bool? enabled,
    List<String>? imageSizes,
    List<String>? imageRatios,
    List<({List<int> duration, List<String> resolution})>?
    durationResolutions,
    Object? audio,
    int? contextWindow,
    int? maxOutputTokens,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      imageSizes: imageSizes ?? this.imageSizes,
      imageRatios: imageRatios ?? this.imageRatios,
      durationResolutions: durationResolutions ?? this.durationResolutions,
      audio: audio ?? this.audio,
      contextWindow: contextWindow ?? this.contextWindow,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (!enabled) 'enabled': false,
    if (imageSizes != null) 'imageSizes': imageSizes,
    if (imageRatios != null) 'imageRatios': imageRatios,
    if (durationResolutions != null)
      'durationResolutions': [
        for (final d in durationResolutions!)
          {'duration': d.duration, 'resolution': d.resolution},
      ],
    if (audio != null) 'audio': audio,
    if (contextWindow != null) 'contextWindow': contextWindow,
    if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
  };

  static ProviderModel fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? json['id'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      imageSizes: _stringList(json['imageSizes']),
      imageRatios: _stringList(json['imageRatios']),
      durationResolutions: _durationResolutions(json['durationResolutions']),
      audio: json['audio'],
      contextWindow: (json['contextWindow'] as num?)?.toInt(),
      maxOutputTokens: (json['maxOutputTokens'] as num?)?.toInt(),
    );
  }

  static List<String>? _stringList(Object? raw) {
    if (raw is! List) return null;
    return [for (final item in raw) if (item is String) item];
  }

  static List<({List<int> duration, List<String> resolution})>?
  _durationResolutions(Object? raw) {
    if (raw is! List) return null;
    final result = <({List<int> duration, List<String> resolution})>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final duration = [
        for (final d in (item['duration'] as List? ?? const []))
          if (d is num) d.toInt(),
      ];
      final resolution = [
        for (final r in (item['resolution'] as List? ?? const []))
          if (r is String) r,
      ];
      if (duration.isNotEmpty && resolution.isNotEmpty) {
        result.add((duration: duration, resolution: resolution));
      }
    }
    return result.isEmpty ? null : result;
  }
}

/// 模型列表与 JSON 字符串之间的编解码。
class ProviderModelCodec {
  const ProviderModelCodec._();

  static String encode(List<ProviderModel> models) {
    return jsonEncode([for (final m in models) m.toJson()]);
  }

  static List<ProviderModel> decode(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) ProviderModel.fromJson(item),
      ];
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }
}
