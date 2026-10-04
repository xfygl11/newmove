import 'package:flutter/material.dart';

/// 生成类任务的状态常量与展示元数据（单一来源）。
///
/// 此前状态徽章在四个页面各写一份，且只识别 8 个状态中的 2 个，导致
/// 「已完成」与「排队中」外观一致。这里收口为单一常量表 + 单一组件。
class StatusKinds {
  StatusKinds._();

  static const _kinds = <String, StatusKind>{
    // 镜头
    '待提示词': StatusKind(Colors.grey, Icons.edit_note, false),
    '待分镜图': StatusKind(Colors.blue, Icons.schedule, false),
    '生成中': StatusKind(Colors.blue, Icons.autorenew, true),
    '待验收': StatusKind(Colors.amber, Icons.looks_one, false),
    '分镜图已确认': StatusKind(Colors.teal, Icons.check_circle_outline, false),
    '视频生成中': StatusKind(Colors.blue, Icons.autorenew, true),
    '视频完成': StatusKind(Colors.green, Icons.movie, false),
    // 资产
    '待生成': StatusKind(Colors.grey, Icons.schedule, false),
    '已采用': StatusKind(Colors.green, Icons.check_circle_outline, false),
    '废弃': StatusKind(Colors.red, Icons.delete_outline, false),
    // 视频任务
    '排队中': StatusKind(Colors.grey, Icons.hourglass_bottom, false),
    '成功': StatusKind(Colors.green, Icons.check_circle_outline, false),
    '失败': StatusKind(Colors.red, Icons.error_outline, false),
    '已取消': StatusKind(Colors.orange, Icons.cancel_outlined, false),
    '视频生成失败': StatusKind(Colors.red, Icons.error_outline, false),
    // 章节 / 伏笔
    '草稿': StatusKind(Colors.grey, Icons.edit_note, false),
    '定稿': StatusKind(Colors.green, Icons.fact_check, false),
    '已回收': StatusKind(Colors.grey, Icons.archive_outlined, false),
  };

  static const fallback = StatusKind(Colors.grey, Icons.schedule, false);

  /// 取状态元数据；未收录的状态回落 [fallback] 而不是报错。
  static StatusKind of(String status) => _kinds[status] ?? fallback;
}

/// 单个状态的展示元数据。
class StatusKind {
  const StatusKind(this.color, this.icon, this.spinner);

  final Color color;
  final IconData icon;

  /// true 表示进行中，徽章画转圈而不是静态图标。
  final bool spinner;
}

/// 统一状态徽章：任务中心、镜头列表、资产画廊、资产详情共用。
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final String status;

  /// true 用行内「图标 + 文字」，false 用胶囊底色。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final kind = StatusKinds.of(status);
    final fontSize = compact ? 11.0 : 12.0;
    if (!compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          kind.spinner
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kind.color,
                  ),
                )
              : Icon(kind.icon, color: kind.color, size: 16),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(color: kind.color, fontSize: fontSize),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kind.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: kind.color, fontSize: fontSize),
      ),
    );
  }
}
