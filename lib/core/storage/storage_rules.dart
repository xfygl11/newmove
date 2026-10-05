import 'dart:io';

/// 产物文件存储的共用规则（M17 T19.1 / T19.2）。
///
/// 三个 file store 共用命名规则，保证「生成新产物不覆盖历史字节」这一不变量
/// 只有一处定义。改动前固定名为 `前缀_${id}.扩展名`，同名覆盖会让版本快照表
/// 与视频任务表里的历史路径全部指向同一个文件。
abstract final class VersionedFileNames {
  /// 返回 `dir/prefix_${id}_${微秒戳}.${ext}`，不创建目录、不写文件。
  static String build(
    Directory dir, {
    required String prefix,
    required int id,
    required String ext,
  }) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '${dir.path}/${prefix}_${id}_$stamp.$ext';
  }
}

/// 本地产物替换的体积上限，图片与视频共用同一数字。
abstract final class StorageLimits {
  /// 100MB：超过即拒绝替换，避免把超大文件全量载入内存导致 OOM。
  static const int maxReplaceableFileBytes = 100 * 1024 * 1024;
}
