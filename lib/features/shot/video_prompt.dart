import 'dart:convert';

import '../../data/app_database.dart';

/// 视频生成参数快照（提交前构造，随任务持久化）。
class VideoGenParams {
  const VideoGenParams({
    required this.modelId,
    required this.durationSec,
    required this.ratio,
    required this.resolution,
    required this.generateAudio,
    required this.referenceCount,
  });

  final String modelId;
  final int durationSec;
  final String ratio;
  final String resolution;
  final bool generateAudio;
  final int referenceCount;

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'durationSec': durationSec,
    'ratio': ratio,
    'resolution': resolution,
    'generateAudio': generateAudio,
    'referenceCount': referenceCount,
  };

  factory VideoGenParams.fromJson(Map<String, dynamic> json) {
    return VideoGenParams(
      modelId: json['modelId'] as String? ?? '',
      durationSec: json['durationSec'] as int? ?? 5,
      ratio: json['ratio'] as String? ?? '16:9',
      resolution: json['resolution'] as String? ?? '480p',
      generateAudio: json['generateAudio'] as bool? ?? false,
      referenceCount: json['referenceCount'] as int? ?? 0,
    );
  }

  String encode() => jsonEncode(toJson());

  static VideoGenParams decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return VideoGenParams.fromJson(decoded);
    } on FormatException {
      // 落库内容异常时返回默认值。
    }
    return const VideoGenParams(
      modelId: '',
      durationSec: 5,
      ratio: '16:9',
      resolution: '480p',
      generateAudio: false,
      referenceCount: 0,
    );
  }
}

/// A9.2 视频分段提示词模板构造（docs/03 5.5）。
///
/// 输入取自 Shot 落库数据：prompt（M5 分镜提示词）、frames（时间轴）、
/// AssetRefs（参考绑定）+ 资产名称，拼成结构化模板文本。
class VideoPromptBuilder {
  const VideoPromptBuilder();

  /// 构造视频提示词。
  ///
  /// [artStyle] 剧本画风；[shot] 镜头（prompt 作为 Objective 底稿）；
  /// [frames] 分镜帧；[refs] 参考绑定；[assetNames] assetId → 资产名；
  /// [durationSec] 覆盖目标时长（默认取镜头 durationMs 换算）。
  String build({
    required Shot shot,
    required List<ShotFrame> frames,
    required List<AssetRef> refs,
    required Map<int, Asset> assetById,
    String artStyle = '日式 2D 动画，干净线稿，柔和上色',
    int? durationSec,
  }) {
    final targetSec = durationSec ?? (shot.durationMs / 1000).round();
    final buf = StringBuffer();

    // Objective：以分镜提示词为本段目标事件底稿。
    buf.writeln('Objective: 完成本段画面事件——${shot.prompt.isEmpty ? shot.globalSeq : shot.prompt}');

    // Reference binding：AssetRefs 顺序 → {{ref N}}。
    buf.writeln('Reference binding:');
    for (var i = 0; i < refs.length; i++) {
      final asset = assetById[refs[i].assetId];
      final name = asset?.name ?? '未知';
      final type = asset?.type ?? '资产';
      buf.writeln('- {{ref${i + 1}}}：$name（$type 参考）');
    }
    if (refs.isEmpty) buf.writeln('- 无');

    // Immutable locks：从出镜状态提取主要角色与场景（静态锁定项）。
    buf.writeln('Immutable locks: 保持人物身份与外观锚点不变，'
        '道具持有状态与本段开头一致，不出现画面外的角色');

    buf.writeln('Target duration: ${targetSec}s');

    // Timeline：按帧列出时间轴；多帧时帧间 HARD CUT。
    buf.writeln('Timeline:');
    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      final parts = [
        f.timeRange,
        '镜头${f.seq}',
        [f.subject, f.shotSize, f.angle].where((p) => p.isNotEmpty).join('·'),
        f.camera.isEmpty ? '固定' : f.camera,
        f.performance,
        if (f.dialogue != null && f.dialogue!.isNotEmpty) f.dialogue!,
      ];
      buf.writeln('- ${parts.where((p) => p.isNotEmpty).join(' | ')}');
      if (i < frames.length - 1) buf.writeln('- HARD CUT');
    }

    buf.writeln('Visual direction: $artStyle');
    buf.writeln('Audio direction: 同期对白与环境音，不加 BGM 与后期字幕');
    buf.writeln('Preserve: 不新增、不删除、不替换、不改顺序剧情事件');
    buf.writeln('Avoid: 不叠化、不闪白、不甩镜，无水印');

    return buf.toString();
  }
}
