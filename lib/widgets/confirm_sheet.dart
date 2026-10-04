import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/app_settings.dart';

/// 算力生成的统一确认 Sheet（对齐 Toonflow `canvasExecution.md` 的临执行复核）。
///
/// 此前确认散落在 4 处且标准不一：有的带完整参数、有的无视
/// [AppSettings.confirmBeforeGenerate] 无条件弹框、有的完全不弹框直接调 LLM。
/// 所有消耗算力的操作一律走 [ConfirmSheet.show]，保证对象 / 数量 / 完整提示词 /
/// 参数 / 参考文件与用途 / 执行次数 / 费用性质 七项齐备；
/// 费用无法查询时明确「未知」，不得留空让 UI 看起来像免费。
///
/// 临执行复核：主按钮第一下只进入「已复核」态，第二下才执行，
/// 供用户在按下执行前再扫一遍参考文件顺序与执行次数。
class ConfirmSheet {
  const ConfirmSheet._();

  /// 确认对话框默认标题。
  static const String defaultTitle = '确认生成';

  /// 主按钮第一下文案。
  static const String confirmLabel = '开始生成';

  /// 主按钮「已复核」态文案。
  static const String reviewLabel = '已复核 · 执行';

  /// 值里出现这些词时高亮，防止用户扫读时漏掉风险提示。
  static const List<String> attentionWords = ['超限', '裁剪', '覆盖', '丢失', '计费'];

  /// 弹确认框；用户点击执行返回 true。
  ///
  /// [refs] 传「用途：文件名」形式，顺序即上传顺序；
  /// [cost] 无法查询时传 '未知'。
  static Future<bool> show(
    BuildContext context, {
    required String objectName,
    String quantity = '1 个对象',
    required String promptPreview,
    List<String> params = const [],
    List<String> refs = const [],
    String note = '',
    String cost = '未知',
    String title = defaultTitle,
    String confirmLabel = ConfirmSheet.confirmLabel,
    bool confirmedByDefault = false,
    bool dismissible = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: title,
        objectName: objectName,
        quantity: quantity,
        promptPreview: promptPreview,
        params: params,
        refs: refs,
        note: note,
        cost: cost,
        confirmLabel: confirmLabel,
        confirmedByDefault: confirmedByDefault,
        dismissible: dismissible,
      ),
    );
    return confirmed ?? false;
  }

  /// 按「生成前确认」开关决定是否弹框：关闭时直接放行，开启时走 [show]。
  static Future<bool> confirm(
    BuildContext context, {
    required String objectName,
    String quantity = '1 个对象',
    required String promptPreview,
    List<String> params = const [],
    List<String> refs = const [],
    String note = '',
    String cost = '未知',
    String title = defaultTitle,
    String confirmLabel = ConfirmSheet.confirmLabel,
    bool confirmedByDefault = false,
  }) async {
    if (!ProviderScope.containerOf(context)
        .read(appSettingsProvider)
        .confirmBeforeGenerate) {
      return true;
    }
    return show(
      context,
      objectName: objectName,
      quantity: quantity,
      promptPreview: promptPreview,
      params: params,
      refs: refs,
      note: note,
      cost: cost,
      title: title,
      confirmLabel: confirmLabel,
      confirmedByDefault: confirmedByDefault,
    );
  }

  /// 一行「标签：值」。
  static Widget row(
    BuildContext context,
    String label,
    String value, {
    bool attention = false,
  }) {
    final theme = Theme.of(context);
    final emphasis = attention || attentionWords.any(value.contains);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: emphasis ? FontWeight.w600 : FontWeight.normal,
                color: emphasis ? theme.colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.title,
    required this.objectName,
    required this.quantity,
    required this.promptPreview,
    required this.params,
    required this.refs,
    required this.note,
    required this.cost,
    required this.confirmLabel,
    required this.confirmedByDefault,
    required this.dismissible,
  });

  final String title;
  final String objectName;
  final String quantity;
  final String promptPreview;
  final List<String> params;
  final List<String> refs;
  final String note;
  final String cost;
  final String confirmLabel;
  final bool confirmedByDefault;
  final bool dismissible;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _reviewed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canExecute = _reviewed || widget.confirmedByDefault;
    return PopScope(
      canPop: widget.dismissible,
      child: AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(widget.title)),
            if (widget.dismissible)
              IconButton(
                tooltip: '关闭',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConfirmSheet.row(
                  context,
                  '对象',
                  '${widget.objectName} · ${widget.quantity}',
                ),
                ConfirmSheet.row(context, '提示词', widget.promptPreview),
                if (widget.refs.isNotEmpty)
                  ConfirmSheet.row(
                    context,
                    '参考',
                    widget.refs.join('\n'),
                    attention: true,
                  ),
                for (final p in widget.params)
                  ConfirmSheet.row(context, '参数', p),
                if (widget.note.trim().isNotEmpty)
                  ConfirmSheet.row(context, '说明', widget.note.trim()),
                ConfirmSheet.row(context, '费用', widget.cost),
                if (widget.confirmedByDefault)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '本次为免确认执行（已在「设置」关闭生成前确认）。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          if (!_reviewed)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '请核对提示词、参考文件顺序与执行次数后再执行。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: canExecute
                      ? () => Navigator.of(context).pop(true)
                      : () => setState(() => _reviewed = true),
                  child: Text(
                    canExecute ? ConfirmSheet.reviewLabel : widget.confirmLabel,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
