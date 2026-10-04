import 'provider_models.dart';

/// 常见模型能力预设（借鉴 Toonflow providers 里内置的能力声明）。
///
/// 一键获取模型时 `/models` 只返回 id/label，能力元数据缺失；命中已知模型
/// （按 id/label 小写子串匹配）时补全能力字段，让参数联动可直接生效。
/// 只补空字段，不覆盖用户已填的能力，也不改勾选态。
class ModelPresets {
  ModelPresets._();

  /// 内置预设：按 [_Spec.match] 顺序匹配，首个命中的生效。
  static const List<_Spec> _specs = [
    // Seedance 2.5：4-30s，480p/720p/1080p，多参 + 首帧可选。
    _Spec(
      match: ['seedance 2.5', 'seedance-2.5', 'seedance_2.5'],
      durations: null, // 由 range 表达
      durationRange: (4, 30),
      resolutions: ['480p', '720p', '1080p'],
      videoModes: ['text', 'multiImage', 'startFrameOptional'],
      maxImageRefs: 9,
      audio: 'optional',
    ),
    // Seedance 2.0 系列（含 fast / mini）：4-15s，480p/720p。
    _Spec(
      match: [
        'seedance 2.0',
        'seedance-2.0',
        'seedance 2.0 fast',
        'seedance 2.0 mini',
        'seedance2',
      ],
      durationRange: (4, 15),
      resolutions: ['480p', '720p'],
      videoModes: ['text', 'multiImage', 'startFrameOptional'],
      maxImageRefs: 9,
      audio: 'optional',
    ),
    // Wan 3.0：2-30s。
    _Spec(
      match: ['wan-3', 'wan3', 'wan 3'],
      durationRange: (2, 30),
      resolutions: ['480p', '720p', '1080p'],
      videoModes: ['text', 'multiImage', 'startFrameOptional'],
      maxImageRefs: 9,
      audio: 'optional',
    ),
    // MiniMax H3：4-15s，768p/2K，原生音频。
    _Spec(
      match: ['minimax'],
      durationRange: (4, 15),
      resolutions: ['480p', '720p', '768p', '2K'],
      videoModes: ['text', 'multiImage', 'startFrameOptional'],
      maxImageRefs: 9,
      audio: true,
    ),
    // Kling 系：5/10s，720p/1080p，首尾帧。
    _Spec(
      match: ['kling'],
      durations: [5, 10],
      resolutions: ['720p', '1080p'],
      videoModes: [
        'text',
        'multiImage',
        'startFrameOptional',
        'startEndRequired',
      ],
      maxImageRefs: 9,
      audio: 'optional',
    ),
    // 图片：豆包 Seedream。
    _Spec(
      match: ['seedream'],
      imageSizes: ['1K', '1.5K', '2K', '4K'],
      imageRatios: ['16:9', '9:16', '1:1', '4:3', '3:4'],
    ),
    // 图片：通用 gpt-image / 全能图片 / 通义万相。
    _Spec(
      match: ['gpt-image', 'gpt image', '全能图片', 'wanx', '通用图片'],
      imageSizes: ['1K', '2K', '4K'],
      imageRatios: ['1:1', '9:16', '16:9', '3:4', '4:3', '3:2', '2:3'],
    ),
    // Agnes LLM：512K 上下文。
    _Spec(
      match: ['agnes-2.5', 'agnes 2.5', 'agnes-2.5-flash'],
      contextWindow: 512000,
      maxOutputTokens: 65536,
    ),
    // Agnes 图片：1K-4K 尺寸，多画幅。
    _Spec(
      match: ['agnes-image', 'agnes image'],
      imageSizes: ['1K', '2K', '3K', '4K'],
      imageRatios: ['1:1', '3:4', '4:3', '16:9', '9:16', '2:3', '3:2', '21:9'],
    ),
    // Agnes 视频 2.5：4-12s，720P/1080P/1K/2K，多参 + 首尾帧，12 个媒体文件上限。
    _Spec(
      match: ['agnes-video-2.5', 'agnes video 2.5'],
      durationRange: (4, 12),
      resolutions: ['720P', '1080P', '1K', '2K'],
      videoModes: [
        'text',
        'multiImage',
        'startFrameOptional',
        'startEndRequired',
      ],
      maxImageRefs: 8,
      audio: 'optional',
    ),
  ];

  /// 对单个模型套用预设（仅补空字段）。
  static ProviderModel apply(ProviderModel model) {
    final key = '${model.id} ${model.label}'.toLowerCase();
    for (final spec in _specs) {
      if (!spec.matches(key)) continue;
      return spec.fill(model);
    }
    return model;
  }

  /// 对列表批量套用预设。
  static List<ProviderModel> applyAll(List<ProviderModel> models) => [
    for (final m in models) apply(m),
  ];
}

/// 单条预设规则。
class _Spec {
  const _Spec({
    required this.match,
    this.durations,
    this.durationRange,
    this.resolutions,
    this.imageSizes,
    this.imageRatios,
    this.videoModes,
    this.maxImageRefs,
    this.audio,
    this.contextWindow,
    this.maxOutputTokens,
  });

  final List<String> match;
  final List<int>? durations;

  /// (起, 止) 闭区间时长；与 [durations] 二选一。
  final (int, int)? durationRange;
  final List<String>? resolutions;
  final List<String>? imageSizes;
  final List<String>? imageRatios;
  final List<String>? videoModes;
  final int? maxImageRefs;
  final Object? audio;
  final int? contextWindow;
  final int? maxOutputTokens;

  bool matches(String key) => match.any(key.contains);

  ProviderModel fill(ProviderModel m) {
    final duration =
        durations ??
        (durationRange == null
            ? null
            : [for (var d = durationRange!.$1; d <= durationRange!.$2; d++) d]);
    final durRes =
        m.durationResolutions ??
        (duration != null && resolutions != null
            ? [(duration: duration, resolution: resolutions!)]
            : null);
    return m.copyWith(
      durationResolutions: durRes,
      imageSizes: m.imageSizes ?? imageSizes,
      imageRatios: m.imageRatios ?? imageRatios,
      videoModes: m.videoModes ?? videoModes,
      maxImageRefs: m.maxImageRefs ?? maxImageRefs,
      audio: m.audio ?? audio,
      contextWindow: m.contextWindow ?? contextWindow,
      maxOutputTokens: m.maxOutputTokens ?? maxOutputTokens,
    );
  }
}
