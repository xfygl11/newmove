import 'dart:developer';

/// 应用内诊断日志（M18 T20.18）。
///
/// 台账与快照属于「辅助能力不得阻塞主流程」的旁路写入，历史上五处
/// `catch (_) {}` 把磁盘满、外键冲突、JSON 编码异常全部静默吞掉，
/// 结果是「台账少一行」而 UI 与数据侧都无痕迹。这里保留不阻塞语义，
/// 但把失败原因落到 logcat，让盲区可见。
///
/// 只输出异常类型与截断后的消息，禁止把提示词、正文、API Key 传入 [message]。
void appLog(String tag, String message, {Object? error, StackTrace? stackTrace}) {
  log(
    message.length > 300 ? message.substring(0, 300) : message,
    name: 'newmove-$tag',
    error: error,
    stackTrace: stackTrace,
    level: 900,
  );
}
