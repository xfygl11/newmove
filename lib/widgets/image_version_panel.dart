import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// 一条图片版本：标题（版本序号 + 时间）+ 独立落盘路径 + 可选副标题。
class ImageVersionItem {
  const ImageVersionItem({
    required this.label,
    required this.path,
    this.subtitle = '',
  });

  final String label;
  final String? path;
  final String subtitle;
}

/// 图片历史版本面板（M17 T19.1）：展示快照表里的历史图片，
/// 点击条目即把对象指针切回该版本，不重建对象、不重跑生成。
///
/// 资产图与分镜图共用：两者的快照表都存 `imagePath`，
/// 面板只负责展示与回调，数据的读取与解析由调用方做。
class ImageVersionPanel extends StatelessWidget {
  const ImageVersionPanel({
    super.key,
    required this.items,
    required this.currentPath,
    required this.onSelect,
    required this.onReplace,
    this.title = '图片版本',
    this.emptyHint = '暂无历史版本，重新生成或替换后会写入快照',
    this.working = false,
  });

  final List<ImageVersionItem> items;
  final String? currentPath;
  final ValueChanged<String> onSelect;
  final VoidCallback onReplace;
  final String title;
  final String emptyHint;
  final bool working;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$title（${items.length}）',
                  style: theme.textTheme.titleSmall,
                ),
                TextButton.icon(
                  onPressed: working ? null : onReplace,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('替换'),
                ),
              ],
            ),
            if (items.isEmpty)
              Text(emptyHint, style: theme.textTheme.bodySmall)
            else
              for (final item in items) _tile(theme, item),
          ],
        ),
      ),
    );
  }

  Widget _tile(ThemeData theme, ImageVersionItem item) {
    final isActive = item.path != null && item.path == currentPath;
    final preview = item.path != null && File(item.path!).existsSync()
        ? File(item.path!)
        : null;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: preview == null
          ? const Icon(Icons.broken_image_outlined, size: 40)
          : ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.file(preview, fit: BoxFit.cover),
              ),
            ),
      title: Text(item.label),
      subtitle: isActive
          ? const Text('当前采用')
          : (item.subtitle.isEmpty ? null : Text(item.subtitle)),
      trailing: isActive ? const Icon(Icons.check_circle, size: 20) : null,
      enabled: !isActive && !working,
      onTap: isActive ? null : () => onSelect(item.path!),
    );
  }
}

/// 从快照 JSON 里取图片路径：宽容解析，快照损坏返回 null。
String? imagePathOfSnapshot(String snapshot) {
  if (snapshot.isEmpty) return null;
  try {
    final decoded = json.decode(snapshot);
    if (decoded is! Map) return null;
    final p = decoded['imagePath'];
    if (p is String && p.isNotEmpty) return p;
    return null;
  } on FormatException {
    return null;
  }
}

/// 快照时间格式化：只显示月-日 时:分，列表里够用。
String formatSnapshotTime(DateTime time) {
  final t = time.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}
