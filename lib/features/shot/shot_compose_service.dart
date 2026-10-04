import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/app_database.dart';
import 'shot_models.dart';

/// 视频合成成片服务（M8：FFmpeg 拼接，借鉴 Toonflow 合成流程）。
///
/// 策略：优先 concat demuxer（同编码零损失快拼）；失败或帧参数不一致时
/// 回落统一重编码 720p/24fps。manifest（json）落私有目录留档，不建表。
class ShotComposeService {
  ShotComposeService({required this.appDatabase});

  final AppDatabase appDatabase;

  /// 合成剧本全部「视频完成」镜头为成片，返回成片路径。
  ///
  /// 按 globalSeq 顺序拼接；无可合成镜头时抛 [StateError]。
  Future<String> composeScript({
    required int scriptId,
    required String outputName,
  }) async {
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
    final outPath = '$outDir/$outputName';
    final manifestPath = '$outDir/manifest_$outputName.json';

    var method = 'concat-copy';
    // 1) 快拼（concat demuxer，要求各段编码一致）。
    try {
      final listFile = await _writeConcatList(outDir, [
        for (final s in completed) s.outputPath!,
      ]);
      final session = await FFmpegKit.execute(
        '-f concat -safe 0 -i "$listFile" -c copy "$outPath"',
      );
      if (!await _isSuccess(session)) {
        throw StateError('快拼失败');
      }
    } on StateError {
      // 2) 快拼失败回落：统一重编码 720p/24fps（逐段滤镜 + concat）。
      method = 'reencode-720p';
      await _reencode(completed, outPath);
    }

    // 3) manifest 留档。
    await File(manifestPath).writeAsString(
      jsonEncode({
        'scriptId': scriptId,
        'output': outPath,
        'method': method,
        'shotCount': completed.length,
        'shots': [
          for (final s in completed) {'seq': s.globalSeq, 'path': s.outputPath},
        ],
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    return outPath;
  }

  /// 判断同步执行的 session 是否成功（ReturnCode 成功码 0）。
  Future<bool> _isSuccess(FFmpegSession session) async {
    final rc = await session.getReturnCode();
    return rc != null && ReturnCode.isSuccess(rc);
  }

  /// 逐段重编码后拼接（容错：分辨率/帧率/音频不一致也能合成）。
  Future<void> _reencode(List<Shot> completed, String outPath) async {
    final filter = _buildFilter(completed.length);
    final session = await FFmpegKit.executeWithArguments([
      for (final s in completed) ...['-i', s.outputPath!],
      '-filter_complex',
      filter,
      '-map',
      '[vc]',
      '-map',
      '[ac]',
      '-c:v',
      'libx264',
      '-preset',
      'fast',
      '-c:a',
      'aac',
      outPath,
    ]);
    if (!await _isSuccess(session)) {
      final output = await session.getOutput();
      throw StateError(
        '重编码合成失败：${output?.substring(0, output.length < 400 ? output.length : 400)}',
      );
    }
  }

  /// 构造 filter_complex：各段缩放 720p/24fps，再成对进 concat。
  String _buildFilter(int n) {
    final parts = <String>[
      for (var i = 0; i < n; i++) ...[
        '[$i:v]scale=1280:720:force_original_aspect_ratio=decrease,'
            'pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=24[v$i]',
        '[$i:a]aresample=48000,apad[a$i]',
      ],
    ];
    parts.add(
      '${[for (var i = 0; i < n; i++) 'v$i'].join('')}'
      '${[for (var i = 0; i < n; i++) 'a$i'].join('')}'
      'concat:n=$n:v=1:a=1[vc][ac]',
    );
    return parts.join(';');
  }

  /// 写 concat demuxer 清单文件。
  Future<String> _writeConcatList(String dir, List<String> paths) async {
    final listFile =
        '$dir/concat_list_${DateTime.now().millisecondsSinceEpoch}.txt';
    await File(listFile).writeAsString(
      [for (final p in paths) 'file ${Uri.encodeComponent(p)}\n'].join(),
    );
    return listFile;
  }
}
