import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// 分镜图文件存储：应用私有目录 `files/shots/`。
class ShotFileStore {
  /// 返回并创建分镜图根目录。
  Future<Directory> _baseDir() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory('${doc.path}/shots');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 保存分镜生成图，返回文件绝对路径。
  Future<String> save(int shotId, Uint8List bytes) async {
    final dir = await _baseDir();
    final file = File('${dir.path}/shot_$shotId.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// 删除单个分镜图文件。
  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
