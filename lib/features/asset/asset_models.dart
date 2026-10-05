import 'dart:convert';

import '../../core/json_values.dart';

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

/// 角色体型词表（M19 T21.13，DB 直接存中文）。
class BodyTypes {
  BodyTypes._();

  static const slim = '瘦长';
  static const balanced = '匀称';
  static const sturdy = '结实';
  static const burly = '魁梧';
  static const plump = '丰腴';
  static const petite = '娇小';

  static const all = [slim, balanced, sturdy, burly, plump, petite];
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
    this.heightCm,
    this.bodyType,
    this.costumeSets,
  });

  final String type;
  final String name;
  final String stableId;

  /// 变体父资产的 stableId（可空）。
  final String? variantOf;
  final Map<String, dynamic> appearanceAnchor;
  final String boardLayout;
  final String prompt;

  /// 身高厘米数（M19 T21.13，仅角色）。
  final int? heightCm;

  /// 体型：瘦长 / 匀称 / 结实 / 魁梧 / 丰腴 / 娇小。
  final String? bodyType;

  /// 服装套列表：`[{name, description}]`，基础态放第一位。
  final List<Map<String, dynamic>>? costumeSets;

  factory AssetDraft.fromJson(Map<String, dynamic> json) {
    return AssetDraft(
      type: jsonString(json['type']).trim(),
      name: jsonString(json['name']).trim(),
      stableId: jsonString(json['stableId']).trim(),
      variantOf: jsonStringOrNull(json['variantOf'])?.trim(),
      appearanceAnchor: _asStringMap(json['appearanceAnchor']),
      boardLayout: jsonString(
        json['boardLayout'],
        BoardLayouts.mainView,
      ).trim(),
      prompt: jsonString(json['prompt']).trim(),
      heightCm: _heightCm(json['heightCm']),
      bodyType: _bodyType(json['bodyType']),
      costumeSets: _costumeSets(json['costumeSets']),
    );
  }

  /// 身高容错：越界（<80 或 >230）与不可解析视为未指定。
  static int? _heightCm(Object? value) {
    final n = value is num
        ? value
        : double.tryParse(jsonString(value).trim()) ?? -1;
    if (n < 80 || n > 230) return null;
    return n.round();
  }

  /// 体型词表容错：不在词表内视为未指定，避免 UI 出现任意词。
  static String? _bodyType(Object? value) {
    final text = jsonString(value).trim();
    if (text.isEmpty || text == '未知' || !BodyTypes.all.contains(text)) {
      return null;
    }
    return text;
  }

  /// 服装套容错：只保留 name 非空且 description 为字符串的项。
  static List<Map<String, dynamic>>? _costumeSets(Object? value) {
    if (value == null) return null;
    final list = value is List ? value : const [];
    final sets = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final name = jsonString(map['name']).trim();
      if (name.isEmpty) continue;
      final desc = jsonStringOrNull(map['description'])?.trim();
      sets.add({'name': name, 'description': desc ?? ''});
    }
    return sets.isEmpty ? null : sets;
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
