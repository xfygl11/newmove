import 'package:flutter/material.dart';

import '../core/gate_issue.dart';

/// 质量门结果的只读展示。
///
/// 默认折叠成一行入口（标题 + 数量徽章），点开才展开详情：门只提示、不改
/// 数据，常驻铺开会挤占正文操作区。无问题时不占位（`showEmpty` 关闭时）。
/// 传入 [onRecord] 时展开区会多出「记一次」，把当前结果写入质量门日志表
/// （`GateLogs`），报表页可以回看最常响的门。
class GateIssueList extends StatelessWidget {
  const GateIssueList({
    super.key,
    required this.issues,
    required this.title,
    this.showEmpty = false,
    this.onRecord,
  });

  final List<GateIssue> issues;

  /// 面板标题，如「提示词体检」「时长体检」「台词体检」。
  final String title;

  /// 无问题时是否仍显示空提示；默认不占位。
  final bool showEmpty;

  /// 返回是否写入成功，决定确认提示文案。
  final Future<bool> Function()? onRecord;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty && !showEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final errorCount = issues.where((i) => i.isError).length;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Row(
        children: [
          Expanded(
            child: Text(
              issues.isEmpty ? '$title · 未发现问题' : title,
              style: theme.textTheme.titleSmall,
            ),
          ),
          _CountBadge(count: issues.length, errorCount: errorCount),
          const SizedBox(width: 8),
        ],
      ),
      children: [
        if (issues.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('未发现问题', style: theme.textTheme.bodySmall),
            ),
          )
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '以下问题需手动调整，门只提示、不自动修改。',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          for (final issue in issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SelectableText(
                issue.noteLine,
                style: TextStyle(
                  color: issue.isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          if (onRecord != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _record(context, onRecord!),
                child: const Text('记一次'),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _record(
    BuildContext context,
    Future<bool> Function() onRecord,
  ) async {
    final ok = await onRecord();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? '已记录一次校验' : '校验记录写入失败')));
  }
}

/// 数量徽章：有错误时红色强调，否则中性色。
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.errorCount});

  final int count;
  final int errorCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorCount > 0;
    final color = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.outline;
    final text = hasError ? '$count 条 · $errorCount 错误' : '$count 条';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
