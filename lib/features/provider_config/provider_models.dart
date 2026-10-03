import 'dart:convert';

/// 供应商分组。
enum ProviderGroup {
  llm('LLM 文本'),
  image('图片'),
  video('视频');

  const ProviderGroup(this.label);

  final String label;

  static ProviderGroup fromValue(String value) {
    return ProviderGroup.values.firstWhere(
      (g) => g.name == value,
      orElse: () => ProviderGroup.llm,
    );
  }
}

/// 模型条目（仅展示用，序列化在 [ProviderModelCodec]）。
class ProviderModel {
  const ProviderModel({required this.id, required this.label});

  final String id;
  final String label;

  Map<String, String> toJson() => {'id': id, 'label': label};

  static ProviderModel fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? json['id'] as String? ?? '',
    );
  }
}

/// 模型列表与 JSON 字符串之间的编解码。
class ProviderModelCodec {
  const ProviderModelCodec._();

  static String encode(List<ProviderModel> models) {
    return jsonEncode([for (final m in models) m.toJson()]);
  }

  static List<ProviderModel> decode(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          ProviderModel.fromJson(item as Map<String, dynamic>),
      ];
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }
}
