import 'package:flutter/material.dart';

import '../core/gate_issue.dart';

/// 质量门结果的只读展示。
///
/// 与 [GateIssue] 的 `noteLine` 共用一套文案：门只提示、不改数据，所以这里
/// 只负责把人读得懂的一行行问题铺开。传入 [onRecord] 时会多出「记一次」，
/// 把当前结果写入生成台账（`subjectType == 'validate'`），
/// 用户改完提示词还能回看到自己踩过哪些门。
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                issues.isEmpty ? '$title · 未发现问题' : '$title · ${issues.length} 条',
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (onRecord != null && issues.isNotEmpty)
              TextButton(
                onPressed: () => _record(context, onRecord!),
                child: const Text('记一次'),
              ),
          ],
        ),
        const SizedBox(height: 4),
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
        const SizedBox(height: 4),
        Text(
          '提示：只提示，不改数据；点「记一次」留痕，改完提示词可在生成台账回看。',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _record(BuildContext context, Future<bool> Function() onRecord) async {
    final ok = await onRecord();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已记录一次校验' : '校验记录写入失败')),
    );
  }
}
