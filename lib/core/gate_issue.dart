/// 本地质量门的统一结果类型（M19）。
///
/// 门一律只提示不阻塞：结果进 UI 面板与确认框，不自动改数据。
/// 与 `SegmentBudgetIssue` 结构同型但字段语义不同（`locator` 覆盖资产名 /
/// 场次号 / 节拍号），故独立成类，不复用分段预算的类型。
library;

import 'gate_codes.dart';

/// 门项严重度。
enum GateSeverity { error, warn }

/// 校验对象类型常量，与 `GateLogs.subjectType` 的取值域一致。
abstract final class GateSubjects {
  static const characters = 'characters';
  static const assets = 'assets';
  static const shots = 'shots';
  static const script = 'script';
  static const skeleton = 'skeleton';
}

/// 一条本地质量门结果。
class GateIssue {
  GateIssue({
    required this.code,
    required this.severity,
    required this.locator,
    required this.message,
  }) {
    // 门码必须在登记表内：登记表是 GateLogs 报表「从没响」榜单的对照面，
    // 未登记的码会漏出榜单，写错码在测试里立刻炸。
    if (!GateCodes.all.contains(code)) {
      throw ArgumentError('未登记的质量门码：$code');
    }
  }

  /// 稳定机器码，日志与下游对账用它，不要改。取值见各门实现文件头注释。
  final String code;
  final GateSeverity severity;

  /// 定位信息：资产名 / S 场次号 / E 节拍号 / '-'（全片级）。
  final String locator;
  final String message;

  bool get isError => severity == GateSeverity.error;

  /// 写入确认框 note 的紧凑一行。
  String get noteLine =>
      '[${severity == GateSeverity.error ? 'error' : 'warn'}] $locator $message';
}
