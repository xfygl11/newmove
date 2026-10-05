import 'package:drift/drift.dart' show Value;

import '../../core/network/protocols.dart';
import '../../data/app_database.dart';
import '../../data/daos/provider_dao.dart';
import 'provider_models.dart';

/// Agnes AI 供应商一键预设（文本 + 图片 + 视频 3 条，协议：openai-chat / openai-images / openai-videos）。
///
/// 用户在设置页点「添加 Agnes 预设」，填 API Key 后即创建 3 个供应商条目；
/// 不创建时 Base URL 固定中国服务 `https://apihub.agnes-ai.cn/v1`。
class AgnesPresets {
  AgnesPresets._();

  static const String baseUrl = 'https://apihub.agnes-ai.cn/v1';

  /// 一键创建 3 条 Agnes 供应商配置（若同名条目已存在则更新）。
  ///
  /// 返回新创建的 [ProviderConfig] 条目数。
  static Future<int> apply({
    required ProviderDao dao,
    required void Function(String providerId, String apiKey) keyWriter,
    required String apiKey,
  }) async {
    final specs = [
      const _Spec(
        id: 'agnes-llm',
        group: 'llm',
        label: 'Agnes LLM',
        protocol: Protocols.openaiChat,
        models: [
          ProviderModel(
            id: 'agnes-2.5-flash',
            label: 'Agnes 2.5 Flash',
            contextWindow: 512000,
            maxOutputTokens: 65536,
          ),
        ],
        readme: 'Agnes AI 文本/视觉语言模型（OpenAI 兼容）',
      ),
      const _Spec(
        id: 'agnes-image',
        group: 'image',
        label: 'Agnes 图片',
        protocol: Protocols.openaiImages,
        models: [
          ProviderModel(
            id: 'agnes-image-2.5-flash',
            label: 'Agnes Image 2.5 Flash',
            imageSizes: ['1K', '2K', '3K', '4K'],
            imageRatios: [
              '1:1',
              '3:4',
              '4:3',
              '16:9',
              '9:16',
              '2:3',
              '3:2',
              '21:9',
            ],
          ),
        ],
        readme: 'Agnes AI 图片生成/编辑（OpenAI Images 协议）',
      ),
      const _Spec(
        id: 'agnes-video',
        group: 'video',
        label: 'Agnes 视频',
        protocol: Protocols.openaiVideos,
        models: [
          ProviderModel(
            id: 'agnes-video-2.5',
            label: 'Agnes Video 2.5',
            durationResolutions: [
              (
                duration: [4, 5, 6, 7, 8, 9, 10, 11, 12],
                resolution: ['720P', '1080P', '1K', '2K'],
              ),
            ],
            videoModes: [
              'text',
              'multiImage',
              'startFrameOptional',
              'startEndRequired',
            ],
            maxImageRefs: 8,
            audio: 'optional',
          ),
          ProviderModel(
            id: 'agnes-video-2.5-flash',
            label: 'Agnes Video 2.5 Flash（720P）',
            durationResolutions: [
              (duration: [4, 5, 6, 7, 8, 9, 10, 11, 12], resolution: ['720P']),
            ],
            videoModes: ['text', 'multiImage', 'startFrameOptional'],
            maxImageRefs: 5,
            audio: 'optional',
          ),
        ],
        readme: 'Agnes AI 视频生成（openai-videos 协议，4-12s，720P-2K）',
      ),
    ];

    for (final s in specs) {
      final id = s.id;
      await dao.upsert(
        ProviderConfigsCompanion.insert(
          id: id,
          group: s.group,
          label: s.label,
          baseUrl: baseUrl,
          protocol: s.protocol,
          models: Value(ProviderModelCodec.encode(s.models)),
          readme: Value(s.readme),
        ),
      );
      // 写入 API Key（Key 只存安全存储，不进 DB）。
      keyWriter(id, apiKey);
    }
    return specs.length;
  }
}

class _Spec {
  const _Spec({
    required this.id,
    required this.group,
    required this.label,
    required this.protocol,
    required this.models,
    this.readme,
  });

  final String id;
  final String group;
  final String label;
  final String protocol;
  final List<ProviderModel> models;
  final String? readme;
}
