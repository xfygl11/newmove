import 'dart:convert';

import '../../core/json_values.dart';
import '../../data/app_database.dart';
import '../script/script_models.dart';

/// 视频生成参数快照（提交前构造，随任务持久化）。
class VideoGenParams {
  const VideoGenParams({
    required this.modelId,
    required this.durationSec,
    required this.ratio,
    required this.resolution,
    required this.generateAudio,
    required this.referenceCount,
    this.useFirstFrame = false,
  });

  final String modelId;
  final int durationSec;
  final String ratio;
  final String resolution;
  final bool generateAudio;
  final int referenceCount;

  /// 是否把分镜图作为首帧通道提交（A9.2，仅模型支持时开启）。
  final bool useFirstFrame;

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'durationSec': durationSec,
    'ratio': ratio,
    'resolution': resolution,
    'generateAudio': generateAudio,
    'referenceCount': referenceCount,
    if (useFirstFrame) 'useFirstFrame': true,
  };

  factory VideoGenParams.fromJson(Map<String, dynamic> json) {
    return VideoGenParams(
      modelId: jsonString(json['modelId']),
      durationSec: jsonInt(json['durationSec'], 5),
      ratio: jsonString(json['ratio'], '16:9'),
      resolution: jsonString(json['resolution'], '480p'),
      generateAudio: jsonBool(json['generateAudio']),
      referenceCount: jsonInt(json['referenceCount']),
      useFirstFrame: jsonBool(json['useFirstFrame']),
    );
  }

  String encode() => jsonEncode(toJson());

  static VideoGenParams decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return VideoGenParams.fromJson(decoded);
      }
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
    String artStyle = defaultArtStyle,
    int? durationSec,
  }) {
    final targetSec = durationSec ?? (shot.durationMs / 1000).round();
    final buf = StringBuffer();

    // Objective：以分镜提示词为本段目标事件底稿。
    buf.writeln(
      'Objective: 完成本段画面事件——${shot.prompt.isEmpty ? shot.globalSeq : shot.prompt}',
    );

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
    buf.writeln(
      'Immutable locks: 保持人物身份与外观锚点不变，'
      '道具持有状态与本段开头一致，不出现画面外的角色',
    );

    buf.writeln('Target duration: ${targetSec}s');

    // Camera spec：段级结构化摄影参数（M19 T21.12）。
    // 提示词里出现结构化字段后，不再靠自由正文描述构图，模型可直接按项执行。
    final spec = shot.cinemaSpec;
    if (spec.isNotEmpty) buf.writeln('Camera spec: $spec');

    // Timeline：A9.2.1「时间块 + 连续自然语言」——每帧一个时间块，
    // 把主体/景别/角度/运镜/站位/表演/对白组织成一段成片式画面描述，
    // 不拆「镜头N | 主体 | 表演」之类的子标题（docs/03 §6.3 差距①）。
    buf.writeln('Timeline:');
    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      buf.writeln();
      buf.writeln('【${_normalizeTimeRange(f.timeRange, frames, i)}】');
      buf.writeln(_naturalTimelineBlock(f));
      if (frames.length > 1 && i < frames.length - 1) {
        buf.writeln('（${f.timeRange} 结束，HARD CUT）');
      }
    }
    if (frames.isEmpty) {
      // 无帧数据时退回 Objective 底稿描述，保证 Timeline 非空。
      buf.writeln();
      buf.writeln('【0:00-0:${targetSec.toString().padLeft(2, '0')}】');
      buf.writeln(shot.prompt.isEmpty ? '完成本段画面事件。' : shot.prompt);
    }

    buf.writeln('Visual direction: $artStyle');
    buf.writeln('Audio direction: 同期对白与环境音，不加 BGM 与后期字幕');
    buf.writeln(
      'Preserve: 不新增、不删除、不替换、不改顺序剧情事件；'
      '人物位置与道具持有状态保持本段开头登记',
    );
    buf.writeln(
      'Avoid: 不叠化、不闪白、不甩镜，无水印，'
      '不出现画面外的角色',
    );

    return buf.toString();
  }

  /// 把帧字段拼成一段连续自然语言的画面描述（A9.2.1 Timeline 写法）。
  ///
  /// 只组织 ShotFrame 已落库的信息，不编造剧情；空字段自然跳过。
  String _naturalTimelineBlock(ShotFrame f) {
    final parts = <String>[];

    // 景别 + 角度 + 主体：画面的观察方式。
    final view = [
      if (f.shotSize.isNotEmpty) f.shotSize,
      if (f.angle.isNotEmpty) f.angle,
    ].join('，');
    if (view.isNotEmpty) {
      parts.add(f.subject.isNotEmpty ? '画面为$view，主体是${f.subject}' : '画面为$view');
    } else if (f.subject.isNotEmpty) {
      parts.add('主体是${f.subject}');
    }

    // 站位：世界坐标 + 画面位置（自包含，不写「延续上一段」）。
    if (f.blocking.isNotEmpty) parts.add(f.blocking);

    // 运镜：仅在与固定不同时写出（固定是默认，不必声明）。
    final camera = f.camera.trim();
    if (camera.isNotEmpty && camera != '固定') {
      parts.add('镜头$camera');
    }

    // 表演：可见行为。
    if (f.performance.isNotEmpty) parts.add(f.performance);

    // 台词原文直接嵌在动作发生位置（A9.2.1：不在 Timeline 后重复）。
    final dialogue = f.dialogue?.trim() ?? '';
    if (dialogue.isNotEmpty) {
      parts.add('同期对白「$dialogue」');
    }

    return '${parts.join('；')}。';
  }

  /// 时间块头部：帧的 timeRange 形如 00:00-00:06，转为 Toonflow 2.5
  /// 风格 0:00-0:06；解析失败时原样返回。
  String _normalizeTimeRange(String timeRange, List<ShotFrame> frames, int i) {
    final m = RegExp(r'(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})')
        .firstMatch(timeRange);
    if (m == null) return timeRange;
    String fmt(int group, int g2) {
      final min = int.parse(m.group(group)!);
      final sec = int.parse(m.group(g2)!);
      return '$min:${sec.toString().padLeft(2, '0')}';
    }

    return '${fmt(1, 2)}-${fmt(3, 4)}';
  }
}

/// M19 T21.12 段级摄影参数拼成一行可执行描述；全缺省时返回空串。
extension ShotCinemaSpec on Shot {
  String get cinemaSpec {
    final items = <String>[
      if (composition != null) '构图：$composition',
      if (lens != null) '焦距：$lens',
      if (cameraPosition != null) '机位：$cameraPosition',
      if (eyeline != null) '视线：$eyeline',
      if (focus != null) '焦点：$focus',
      if (stability != null) '稳定性：$stability',
      if (blocking != null) '走位：$blocking',
    ];
    return items.join('，');
  }
}
