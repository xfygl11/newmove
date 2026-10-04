import 'dart:convert';

import '../../core/json_values.dart';
import 'truth_file_kinds.dart';

/// LLM 上下文预算：按可用 token 估算与分级保护裁剪上下文。
///
/// 分级对齐 InkOS 的权威状态保护：
/// - protected：作者意图 / 当前焦点 / 角色锁 / 世界规则，永不压缩；
/// - compressible：章节摘要、伏笔、资源状态，先做语义裁剪再按优先级取舍。
///
/// 此前所有调用点全量拼接 7 类 TruthFile，写到几十章后请求超长 → 400 或超时，
/// 或 LLM 在超长上下文里输出错误 JSON → `extractJsonObject` 抛异常 → 整章失败。
class ContextBudget {
  const ContextBudget({
    this.maxTokens = defaultMaxTokens,
    this.recentSummaryChapters = 8,
    this.headroom = defaultHeadroom,
  });

  /// 未配置模型窗口时的保守默认。
  static const int defaultMaxTokens = 32768;

  /// 未配置输出上限时给输出与系统提示词留的默认余量。
  static const int defaultHeadroom = 4096;

  /// 计算预算时的额外安全余量，防止估算偏低。
  static const int safety = 1024;

  /// 模型可用上下文总预算（含输出与系统提示词）。
  final int maxTokens;

  /// 前情摘要只保留最近 N 章。
  final int recentSummaryChapters;

  /// 留给输出与安全余量的 token，不进入 TruthFile 装配。
  final int headroom;

  /// 保护级 kind：永不压缩、永不丢弃。
  static const Set<String> protectedKinds = {
    TruthFileKind.authorIntent,
    TruthFileKind.currentFocus,
    TruthFileKind.characterMatrix,
    TruthFileKind.worldFacts,
  };

  /// 压缩池 kind：优先级从高到低，先加入，超出预算时从低优先级整体丢弃。
  static const List<String> compressibleKinds = [
    TruthFileKind.chapterSummaries,
    TruthFileKind.hooks,
    TruthFileKind.resources,
  ];

  static final RegExp _cjkPattern = RegExp(
    r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]',
  );

  /// token 粗估：CJK 单字按 1 token，其余按 4 字符 1 token。
  ///
  /// 与具体分词器无关的保守近似，用于提前挡住明显超长的请求。
  static int estimateTokens(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    final cjk = _cjkPattern.allMatches(t).length;
    return cjk + (t.length - cjk) ~/ 4;
  }

  /// 预算内的可用容量：扣掉输出与系统提示词的余量。
  int get limit => (maxTokens - headroom).clamp(0, 1 << 30);

  /// 按预算装配 TruthFile 上下文。
  ///
  /// [fixedContext] 是必带的固定块（作品命题 / 世界观 / 大纲 / 当前正文等），
  /// 先占用预算，剩余容量按 protected → compressible 顺序分配。
  Budgeted budgetTruthFiles(
    Map<String, String> texts, {
    required String fixedContext,
  }) {
    final fixedTokens = estimateTokens(fixedContext);
    var remaining = (limit - fixedTokens).clamp(0, 1 << 30);

    final out = <String, String>{};
    final dropped = <String>{};

    for (final kind in protectedKinds) {
      final v = texts[kind];
      if (v == null || v.trim().isEmpty) continue;
      out[kind] = v;
      remaining -= estimateTokens(v);
    }

    // 语义裁剪：伏笔只留未闭合、摘要只留近 N 章（只在内存改，不落库）。
    final pool = <String, String>{
      for (final kind in compressibleKinds)
        if (texts[kind] != null) kind: _prune(kind, texts[kind]!),
    };

    for (final kind in compressibleKinds) {
      final v = pool.remove(kind);
      if (v == null || v.trim().isEmpty) continue;
      final cost = estimateTokens(v);
      if (cost <= remaining) {
        out[kind] = v;
        remaining -= cost;
      } else {
        dropped.add(kind);
      }
    }

    final tokens = out.values.fold<int>(
      fixedTokens,
      (acc, v) => acc + estimateTokens(v),
    );
    return Budgeted(
      texts: out,
      dropped: dropped.toList(),
      tokens: tokens,
      budget: limit,
    );
  }

  /// 把改编原文列表压到预算内：按序保留，超出部分整章丢弃。
  BudgetedSource fitSourceTexts(
    List<String> texts, {
    required int reservedTokens,
  }) {
    var remaining = (limit - reservedTokens).clamp(0, 1 << 30);
    final kept = <String>[];
    for (final t in texts) {
      final cost = estimateTokens(t);
      if (kept.isEmpty || cost <= remaining) {
        kept.add(t);
        remaining -= cost;
      } else {
        break;
      }
    }
    return BudgetedSource(
      texts: kept,
      droppedCount: texts.length - kept.length,
    );
  }

  String _prune(String kind, String json) {
    try {
      switch (kind) {
        case TruthFileKind.hooks:
          return _pruneHooks(json);
        case TruthFileKind.chapterSummaries:
          return _pruneSummaries(json);
        default:
          return json;
      }
    } on FormatException {
      return json;
    }
  }

  /// 只留 `open` / `progressing` 的伏笔；无 status 的条目按未闭合保留。
  String _pruneHooks(String json) {
    final map = jsonMap(jsonDecode(json));
    final hooks = [for (final h in jsonList(map['hooks'])) jsonMap(h)];
    if (hooks.isEmpty) return json;
    const open = {'open', 'progressing'};
    final kept = [
      for (final h in hooks)
        if (open.contains(jsonString(h['status'])) || h['status'] == null) h,
    ];
    if (kept.length == hooks.length) return json;
    return jsonEncode({'hooks': kept, 'pruned': hooks.length - kept.length});
  }

  /// 只留最近 [recentSummaryChapters] 章的摘要，返回时按章号升序。
  String _pruneSummaries(String json) {
    final map = jsonMap(jsonDecode(json));
    final rows = [for (final r in jsonList(map['rows'])) jsonMap(r)];
    if (rows.length <= recentSummaryChapters) return json;
    final byChapter = [...rows]
      ..sort(
        (a, b) =>
            jsonInt(b['chapterNumber']).compareTo(jsonInt(a['chapterNumber'])),
      );
    final kept = [...byChapter.sublist(0, recentSummaryChapters)]
      ..sort(
        (a, b) =>
            jsonInt(a['chapterNumber']).compareTo(jsonInt(b['chapterNumber'])),
      );
    return jsonEncode({'rows': kept, 'pruned': rows.length - kept.length});
  }
}

/// 预算裁剪结果。
class Budgeted {
  const Budgeted({
    required this.texts,
    required this.dropped,
    required this.tokens,
    required this.budget,
  });

  /// 裁剪后各 kind 的 JSON 文本，直接注入提示词。
  final Map<String, String> texts;

  /// 被整体丢弃的 compressible kind。
  final List<String> dropped;

  /// 裁剪后的上下文 token 估算值（含固定块）。
  final int tokens;

  /// 可用容量。
  final int budget;

  bool get fits => tokens <= budget;

  /// 被裁剪时的用户提示，未裁剪返回空串。
  String get note => dropped.isEmpty
      ? ''
      : '上下文预算不足，已省略：'
            '${dropped.map((k) => TruthFileKind.label(k)).join('、')}';
}

/// 改编原文按预算保留的结果。
class BudgetedSource {
  const BudgetedSource({required this.texts, required this.droppedCount});

  final List<String> texts;
  final int droppedCount;
}
