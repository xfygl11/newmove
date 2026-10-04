import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/app_database.dart';
import 'shot_models.dart';

/// 合成阶段回调：UI 据此更新文案，避免「正在合成」永久悬挂。
typedef ComposeProgress = void Function(String phase);

/// 合成取消令牌：置位后取消正在运行的 FFmpeg session。
class ComposeCancelToken {
  bool _cancelled = false;
  FFmpegSession? _session;

  bool get cancelled => _cancelled;

  void bind(FFmpegSession session) => _session = session;

  /// 幂等：重复调用安全。
  Future<void> cancel() async {
    _cancelled = true;
    await _session?.cancel();
  }

  void throwIfCancelled() {
    if (_cancelled) throw StateError('合成已取消');
  }
}

/// 视频合成成片服务（M8：FFmpeg 拼接，借鉴 Toonflow 合成流程）。
///
/// 策略：优先 concat demuxer（同编码零损失快拼）；失败或帧参数不一致时
/// 回落统一重编码 720p/24fps；再失败回落纯视频（丢弃音轨）。
/// manifest（json）落私有目录留档，不建表；临时文件用完即删。
class ShotComposeService {
  ShotComposeService({required this.appDatabase});

  final AppDatabase appDatabase;

  /// 单次 FFmpeg 执行上限：超时判失败，避免合成卡死永久占住 UI。
  static const composeTimeout = Duration(minutes: 15);

  /// 保留的 manifest 上限，超出按时间清理，防止私有目录无限增长。
  static const maxManifests = 20;

  /// 不安全的文件名字符：Dart RegExp 不支持 `\p{L}` 属性转义，须写显式范围。
  static final RegExp _unsafeChars = RegExp(
    r'[^0-9A-Za-z'
    r'\u3400-\u4dbf' // CJK 扩展 A
    r'\u4e00-\u9fff' // CJK 基本区
    r'\uf900-\ufaff' // CJK 兼容表意文字
    r'\u3040-\u30ff' // 假名
    r'\uac00-\ud7af' // 谚文
    r'\u0400-\u04ff' // 西里尔
    r'\u00c0-\u024f' // 拉丁扩展
    r'._-]',
  );

  /// 文件名白名单：仅保留字母、数字、中文/日文/韩文、点、下划线、连字符，
  /// 其余替换为下划线，避免剧本标题中的引号、空格、路径分隔符影响输出路径。
  static String safeOutputName(String name) {
    final n = name
        .replaceAll(_unsafeChars, '_')
        .replaceAll(RegExp(r'^[._]+'), '')
        .replaceAll(RegExp(r'\.mp4$', caseSensitive: false), '');
    return '${n.isEmpty ? 'compose' : n}.mp4';
  }

  /// 合成剧本全部「视频完成」镜头为成片，返回成片路径。
  ///
  /// 按 globalSeq 顺序拼接；无可合成镜头时抛 [StateError]。
  Future<String> composeScript({
    required int scriptId,
    required String outputName,
    ComposeCancelToken? cancelToken,
    ComposeProgress? onProgress,
  }) async {
    cancelToken?.throwIfCancelled();
    onProgress?.call('准备镜头');

    final shots = await appDatabase.shotDao.listByScript(scriptId);
    final completed =
        [
            for (final s in shots)
              if (s.status == ShotStatuses.videoDone && s.outputPath != null) s,
          ]
          ..removeWhere((s) => !File(s.outputPath!).existsSync())
          ..sort((a, b) => a.globalSeq.compareTo(b.globalSeq));
    if (completed.isEmpty) {
      throw StateError('尚无「视频完成」的镜头可合成');
    }

    final outDir = (await getApplicationDocumentsDirectory()).path;
    Directory(outDir).createSync(recursive: true);
    final name = safeOutputName(outputName);
    final outPath = '$outDir/$name';
    final manifestPath = '$outDir/manifest_$name.json';
    final listFile =
        '$outDir/concat_list_${DateTime.now().millisecondsSinceEpoch}.txt';

    var method = 'concat-copy';
    var audioDropped = false;
    try {
      // 1) 快拼（concat demuxer，要求各段编码一致）。
      try {
        cancelToken?.throwIfCancelled();
        onProgress?.call('快拼中');
        await _writeConcatList(listFile, [
          for (final s in completed) s.outputPath!,
        ]);
        await _execute([
          '-f',
          'concat',
          '-safe',
          '0',
          '-i',
          listFile,
          '-c',
          'copy',
          outPath,
        ], cancelToken: cancelToken);
      } on StateError {
        // 2) 快拼失败回落：统一重编码 720p/24fps（逐段滤镜 + concat）。
        method = 'reencode-720p';
        try {
          cancelToken?.throwIfCancelled();
          onProgress?.call('重编码中');
          await _reencode(
            completed,
            outPath,
            withAudio: true,
            cancelToken: cancelToken,
          );
        } on StateError {
          // 3) 音轨滤镜失败（某段无音轨）回落纯视频。
          audioDropped = true;
          cancelToken?.throwIfCancelled();
          onProgress?.call('重编码中（无音轨）');
          await _reencode(
            completed,
            outPath,
            withAudio: false,
            cancelToken: cancelToken,
          );
        }
      }

      // 4) manifest 留档。
      await File(manifestPath).writeAsString(
        jsonEncode({
          'scriptId': scriptId,
          'output': outPath,
          'method': method,
          'audioDropped': audioDropped,
          'shotCount': completed.length,
          'shots': [
            for (final s in completed)
              {'seq': s.globalSeq, 'path': s.outputPath},
          ],
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );
      await _pruneManifests(outDir);
    } finally {
      // 临时文件即删：成片失败时同样清掉半成品，避免占盘与误导。
      await _deleteQuiet(listFile);
    }

    return outPath;
  }

  /// 执行一组参数；成功返回，失败抛 [StateError]（含日志尾部）。
  Future<void> _execute(
    List<String> args, {
    ComposeCancelToken? cancelToken,
  }) async {
    cancelToken?.throwIfCancelled();
    final session = await FFmpegKit.executeWithArguments(args);
    cancelToken?.bind(session);
    try {
      await session.getReturnCode().timeout(composeTimeout);
      cancelToken?.throwIfCancelled();
      final rc = await session.getReturnCode();
      if (rc == null || !ReturnCode.isSuccess(rc)) {
        final output = await session.getOutput() ?? '';
        throw StateError(_tail(output, 400));
      }
    } on TimeoutException {
      await session.cancel();
      throw StateError('合成超时（超过 ${composeTimeout.inMinutes} 分钟）');
    }
  }

  /// 逐段重编码后拼接（容错：分辨率/帧率不一致也能合成）。
  ///
  /// [withAudio] 为 true 时保留音轨；任一段缺失音轨会抛 [StateError]，
  /// 由调用方回落纯视频合成。
  Future<void> _reencode(
    List<Shot> completed,
    String outPath, {
    required bool withAudio,
    ComposeCancelToken? cancelToken,
  }) async {
    final filter = _buildFilter(completed.length, withAudio: withAudio);
    await _execute([
      for (final s in completed) ...['-i', s.outputPath!],
      '-filter_complex',
      filter,
      '-map',
      '[vc]',
      if (withAudio) ...['-map', '[ac]'],
      // -shortest：apad 补静音是无限的，必须显式以最短流收尾，
      // 否则成片尾部会被无限静音拖成黑帧或卡死不退出。
      '-shortest',
      '-c:v',
      'libx264',
      '-preset',
      'fast',
      if (withAudio) ...['-c:a', 'aac'],
      outPath,
    ], cancelToken: cancelToken);
  }

  /// 构造 filter_complex：各段缩放 720p/24fps，再成对进 concat。
  String _buildFilter(int n, {required bool withAudio}) {
    final parts = <String>[
      for (var i = 0; i < n; i++) ...[
        '[$i:v]scale=1280:720:force_original_aspect_ratio=decrease,'
            'pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=24[v$i]',
        if (withAudio) '[$i:a]aresample=48000,apad[a$i]',
      ],
    ];
    parts.add(
      '${[for (var i = 0; i < n; i++) 'v$i'].join('')}'
      '${withAudio ? [for (var i = 0; i < n; i++) 'a$i'].join('') : ''}'
      'concat:n=$n:v=1:a=${withAudio ? 1 : 0}[vc]${withAudio ? '[ac]' : ''}',
    );
    return parts.join(';');
  }

  /// 写 concat demuxer 清单文件，返回文件路径。
  Future<String> _writeConcatList(String path, List<String> paths) async {
    await File(path).writeAsString(
      [for (final p in paths) 'file ${_escapeConcatPath(p)}'].join('\n'),
    );
    return path;
  }

  /// concat demuxer 路径转义：单引号包裹并转义内部单引号。
  static String _escapeConcatPath(String path) {
    return "'${path.replaceAll("'", "'\\''")}'";
  }

  /// 取日志尾部作为错误信息，长度不足时不截断。
  static String _tail(String output, int maxLen) {
    final s = output.trim();
    if (s.isEmpty) return 'FFmpeg 返回失败';
    return s.length <= maxLen ? s : '…${s.substring(s.length - maxLen)}';
  }

  /// 保留最近 [maxManifests] 份 manifest，其余按修改时间删除。
  Future<void> _pruneManifests(String outDir) async {
    final dir = Directory(outDir);
    final entities = await dir.list().toList();
    final manifests = [
      for (final e in entities)
        if (e is File &&
            e.path.contains('manifest_') &&
            e.path.endsWith('.json'))
          e,
    ];
    if (manifests.length <= maxManifests) return;
    final stats = [
      for (final f in manifests)
        (file: f, mtime: await f.stat().then((s) => s.modified)),
    ]..sort((a, b) => b.mtime.compareTo(a.mtime));
    for (final e in stats.skip(maxManifests)) {
      await _deleteQuiet(e.file.path);
    }
  }

  /// 删除文件，不存在或失败均静默（清理属尽力而为）。
  Future<void> _deleteQuiet(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // 忽略清理失败，不影响合成结果。
    }
  }
}
