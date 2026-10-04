/// 供应商协议常量（单一来源）。
///
/// 此前协议字符串散落在预设、编辑页下拉、适配器各自硬编码，两侧字符串一旦
/// 不匹配就静默落到默认分支，LLM 侧的 `protocol` 更是死字段。现统一在此定义，
/// 适配器入口用 [require] 校验，未知协议显式抛错。
abstract final class Protocols {
  /// LLM：OpenAI Chat Completions 兼容协议（含 Agnes 等代理）。
  static const openaiCompletions = 'openai-completions';

  /// LLM：OpenAI 兼容（历史别名，等价 openai-completions）。
  static const openaiChat = 'openai-chat';

  /// LLM：Anthropic Messages 协议（仅用于模型列表拉取探测）。
  static const anthropicMessages = 'anthropic-messages';

  /// 图片：OpenAI Images 兼容协议（`/images/generations`、`/images/edits`）。
  static const openaiImages = 'openai-images';

  /// 视频/图片：异步任务协议（提交 + 轮询查询）。
  static const asyncTask = 'async-task';

  /// 视频：OpenAI Videos 兼容协议（Agnes：`/videos` + host 根路径查询）。
  static const openaiVideos = 'openai-videos';

  static const llm = <String>[openaiCompletions, openaiChat];

  static const image = <String>[openaiImages];

  static const video = <String>[asyncTask, openaiVideos];

  static const byGroup = <String, List<String>>{
    'llm': llm,
    'image': image,
    'video': video,
  };

  /// 某分组支持的协议列表；未知分组返回空列表。
  static List<String> optionsFor(String group) =>
      byGroup[group] ?? const <String>[];

  /// 某分组是否支持该协议。
  static bool isSupported(String group, String? protocol) =>
      optionsFor(group).contains(protocol ?? '');

  /// 校验协议属于对应分组；不匹配抛 [ArgumentError]，避免静默落到默认分支。
  static void require(String group, String protocol) {
    final allowed = optionsFor(group);
    if (!allowed.contains(protocol)) {
      throw ArgumentError.value(
        protocol,
        'protocol',
        '协议「$protocol」不支持分组「$group」，可选：${allowed.join(' / ')}',
      );
    }
  }
}
