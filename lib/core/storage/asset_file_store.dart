import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// 资产图片文件存储：应用私有目录 `files/assets/`。
class AssetFileStore {
  /// 返回并创建资产图片根目录。
  Future<Directory> _baseDir() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory('${doc.path}/assets');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 保存资产生成图，返回文件绝对路径。
  Future<String> save(int assetId, Uint8List bytes) async {
    final dir = await _baseDir();
    final file = File('${dir.path}/asset_$assetId.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// 删除单个资产图片文件。
  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
