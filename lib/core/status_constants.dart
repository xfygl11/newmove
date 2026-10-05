/// 生成类任务的中文状态字面量单一来源。
library;

/// 视频生成任务状态常量（DB 直接存中文）。
///
/// 此前这些字面量散落在 service / DAO / 两个页面共 20 处，且 `StatusKinds`
/// 登记的是「排队中」而库里存的是「排队」，排队任务因此落到灰色默认样式
/// ——「已完成」和「排队中」看起来一模一样。单一常量表杜绝拼写漂移。
///
/// 放在 core 而非 features/shot：`tables.dart` 的列默认值必须引用同一个常量，
/// 而 data 层不能反向依赖 features 层。
class VideoTaskStatuses {
  VideoTaskStatuses._();

  /// 已提交远端，等待调度。
  static const queued = '排队';

  /// 远端处理中。
  static const generating = '生成中';

  /// 已完成，产物已落盘。
  static const succeeded = '成功';

  /// 失败，`error` 列写明原因。
  static const failed = '失败';

  /// 用户取消（本地停止追踪，远端可能仍在运行并继续计费）。
  static const cancelled = '已取消';

  /// 进行中：可被取消，可被轮询。
  static const inProgress = [queued, generating];

  /// 终态：不再轮询。
  static const terminal = [succeeded, failed, cancelled];
}
