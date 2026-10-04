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
    this.videoModes,
    this.maxImageRefs,
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

  /// 视频生成模式（借鉴 Toonflow `MediaModel.mode` 的可用子集）：
  /// `text` 文生 / `multiImage` 多图参考 / `startFrameOptional` 首帧可选
  /// （分镜图可作首帧）。null 表示未知，按旧行为处理（仅多图参考）。
  final List<String>? videoModes;

  /// 图片参考数量上限（借鉴 `imageReference:N`）；null 时回退全局硬上限 9。
  final int? maxImageRefs;

  final int? contextWindow;
  final int? maxOutputTokens;

  /// 模型支持的视频时长（秒，升序去重）；无能力数据时返回空。
  List<int> get supportedDurations {
    final data = durationResolutions;
    if (data == null) return const [];
    final set = <int>{};
    for (final item in data) {
      set.addAll(item.duration);
    }
    return set.toList()..sort();
  }

  /// 指定时长下支持的分辨率；无能力数据或该时长无匹配时返回空。
  List<String> resolutionsFor(int durationSec) {
    final data = durationResolutions;
    if (data == null) return const [];
    final set = <String>{};
    for (final item in data) {
      if (item.duration.contains(durationSec)) set.addAll(item.resolution);
    }
    return set.toList();
  }

  /// 是否支持把分镜图作为首帧提交（A9.2 首帧通道）。
  bool get supportsStartFrame {
    final modes = videoModes;
    if (modes == null) return false;
    return modes.contains('startFrameOptional') ||
        modes.contains('startEndRequired') ||
        modes.contains('endFrameOptional');
  }

  /// 归一化时长：无能力数据返回原值；否则取最接近的合法值。
  int normalizeDuration(int value) {
    final list = supportedDurations;
    if (list.isEmpty) return value;
    if (list.contains(value)) return value;
    var best = list.first;
    for (final d in list) {
      if ((d - value).abs() < (best - value).abs()) best = d;
    }
    return best;
  }

  /// 归一化分辨率：无能力数据返回原值；否则给定时长下无匹配取第一个可选。
  String normalizeResolution(int durationSec, String value) {
    final list = resolutionsFor(durationSec);
    if (list.isEmpty) return value;
    if (list.contains(value)) return value;
    return list.first;
  }

  /// 音频三态：true 强制开 / false 强制关 / 其余（null、"optional"）可选。
  bool get audioRequired => identical(audio, true);
  bool get audioDisabled => identical(audio, false);
  bool get audioOptional => !audioRequired && !audioDisabled;

  ProviderModel copyWith({
    String? id,
    String? label,
    bool? enabled,
    List<String>? imageSizes,
    List<String>? imageRatios,
    List<({List<int> duration, List<String> resolution})>?
    durationResolutions,
    Object? audio,
    List<String>? videoModes,
    int? maxImageRefs,
    int? contextWindow,
    int? maxOutputTokens,
    bool clearVideoModes = false,
    bool clearDurationResolutions = false,
    bool clearImageSizes = false,
    bool clearImageRatios = false,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      imageSizes: clearImageSizes ? null : (imageSizes ?? this.imageSizes),
      imageRatios: clearImageRatios ? null : (imageRatios ?? this.imageRatios),
      durationResolutions: clearDurationResolutions
          ? null
          : (durationResolutions ?? this.durationResolutions),
      audio: audio ?? this.audio,
      videoModes: clearVideoModes ? null : (videoModes ?? this.videoModes),
      maxImageRefs: maxImageRefs ?? this.maxImageRefs,
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
    if (videoModes != null) 'videoModes': videoModes,
    if (maxImageRefs != null) 'maxImageRefs': maxImageRefs,
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
      videoModes: _stringList(json['videoModes']),
      maxImageRefs: (json['maxImageRefs'] as num?)?.toInt(),
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
