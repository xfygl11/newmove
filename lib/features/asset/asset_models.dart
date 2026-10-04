import 'dart:convert';

/// 资产类型常量（DB 直接存中文）。
class AssetTypes {
  AssetTypes._();

  static const character = '角色';
  static const scene = '场景';
  static const prop = '道具';

  static const all = [character, scene, prop];
}

/// 资产状态常量。
class AssetStatuses {
  AssetStatuses._();

  static const pending = '待生成';
  static const generating = '生成中';
  static const reviewing = '待验收';
  static const accepted = '已采用';
  static const discarded = '废弃';
}

/// 版式常量。
class BoardLayouts {
  BoardLayouts._();

  static const fourView = '四视图';
  static const mainView = '主视图';
  static const grid2x2 = '2x2';
}

/// AssetDesigner 从骨架提取出的单条资产草案。
class AssetDraft {
  const AssetDraft({
    required this.type,
    required this.name,
    required this.stableId,
    required this.boardLayout,
    required this.prompt,
    this.variantOf,
    this.appearanceAnchor = const {},
  });

  final String type;
  final String name;
  final String stableId;

  /// 变体父资产的 stableId（可空）。
  final String? variantOf;
  final Map<String, dynamic> appearanceAnchor;
  final String boardLayout;
  final String prompt;

  factory AssetDraft.fromJson(Map<String, dynamic> json) {
    return AssetDraft(
      type: (json['type'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      stableId: (json['stableId'] as String? ?? '').trim(),
      variantOf: (json['variantOf'] as String?)?.trim(),
      appearanceAnchor: _asStringMap(json['appearanceAnchor']),
      boardLayout: (json['boardLayout'] as String? ?? BoardLayouts.mainView)
          .trim(),
      prompt: (json['prompt'] as String? ?? '').trim(),
    );
  }

  static Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        // 忽略，保持空对象。
      }
    }
    return <String, dynamic>{};
  }
}

/// 资产清单提取结果。
class AssetExtractionResult {
  const AssetExtractionResult({required this.drafts});

  final List<AssetDraft> drafts;

  factory AssetExtractionResult.fromJson(Map<String, dynamic> json) {
    final raw = json['assets'] ?? json['drafts'] ?? const [];
    final list = raw is List ? raw : const [];
    return AssetExtractionResult(
      drafts: [
        for (final item in list)
          if (item is Map<String, dynamic>) AssetDraft.fromJson(item),
      ],
    );
  }
}
