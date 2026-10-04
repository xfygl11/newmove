import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// 视频文件存储：应用私有目录 `files/videos/`。
class VideoFileStore {
  /// 返回并创建视频根目录。
  Future<Directory> _baseDir() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory('${doc.path}/videos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 保存视频文件，返回文件绝对路径。
  Future<String> save(int shotId, Uint8List bytes) async {
    final dir = await _baseDir();
    final file = File('${dir.path}/shot_$shotId.mp4');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// 从源文件复制视频（流式复制，不整包载入内存），返回目标绝对路径。
  Future<String> saveFromPath(int shotId, String sourcePath) async {
    final dir = await _baseDir();
    final target = File('${dir.path}/shot_$shotId.mp4');
    if (await target.exists()) {
      await target.delete();
    }
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  /// 删除单个视频文件。
  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
