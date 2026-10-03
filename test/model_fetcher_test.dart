import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/features/provider_config/model_fetcher.dart';
import 'package:newmove/features/provider_config/provider_models.dart';

void main() {
  group('ModelFetcher.endpoint', () {
    test('根路径自动补 /v1', () {
      expect(ModelFetcher.endpoint('https://api.example.com'),
          'https://api.example.com/v1/models');
    });

    test('带路径的 baseUrl 直接拼 /models', () {
      expect(ModelFetcher.endpoint('https://api.example.com/v1'),
          'https://api.example.com/v1/models');
    });

    test('尾部斜杠去除', () {
      expect(ModelFetcher.endpoint('https://api.example.com/'),
          'https://api.example.com/v1/models');
      expect(ModelFetcher.endpoint('https://api.example.com/v1/'),
          'https://api.example.com/v1/models');
    });

    test('媒体组追加 type 过滤参数', () {
      expect(
        ModelFetcher.endpoint('https://api.example.com/v1',
            mediaType: true, type: 'video'),
        'https://api.example.com/v1/models?type=video',
      );
    });

    test('已是 /models 的 URL 不重复拼接', () {
      expect(ModelFetcher.endpoint('https://api.example.com/v1/models'),
          'https://api.example.com/v1/models');
    });
  });

  group('ModelFetcher.fetch', () {
    late ModelFetcher fetcher;

    setUp(() {
      fetcher = ModelFetcher(
        dio: Dio()
          ..httpClientAdapter = _MockAdapter({
            'https://api.example.com/v1/models': jsonEncode({
              'data': [
                {'id': 'model-a', 'display_name': '模型 A'},
                {'id': 'model-b', 'displayName': '模型 B'},
                {'id': 'model-c', 'name': '模型 C'},
                {'id': 'model-a'},
                {'id': ''},
                'junk',
              ],
            }),
            'https://media.example.com/v1/models?type=video': jsonEncode({
              'data': [
                {'id': 'video-1'},
                {'id': 'video-2', 'display_name': '视频二号'},
              ],
            }),
          }),
      );
    });

    test('LLM：解析 data、label 回退、去重、跳过无效条目', () async {
      final models = await fetcher.fetch(
        baseUrl: 'https://api.example.com',
        apiKey: 'sk-test',
        protocol: 'openai-completions',
        group: ProviderGroup.llm,
      );
      expect(models.map((m) => m.id), ['model-a', 'model-b', 'model-c']);
      expect(models[0].label, '模型 A');
      expect(models[1].label, '模型 B');
      expect(models[2].label, '模型 C');
    });

    test('媒体组带 type 查询参数', () async {
      final models = await fetcher.fetch(
        baseUrl: 'https://media.example.com',
        apiKey: 'sk-test',
        protocol: 'openai-images',
        group: ProviderGroup.video,
      );
      expect(models.map((m) => m.id), ['video-1', 'video-2']);
      expect(models[1].label, '视频二号');
    });
  });

  group('ModelFetcher.mergeFetched', () {
    test('新模型默认不勾选，同 id 保留勾选态与能力字段', () {
      final existing = [
        const ProviderModel(
          id: 'model-a',
          label: 'A（手填名）',
          enabled: true,
          imageRatios: ['16:9'],
        ),
      ];
      final merged = ModelFetcher.mergeFetched(
        existing: existing,
        fetched: [
          (id: 'model-a', label: 'Fetched A'),
          (id: 'model-new', label: 'New'),
        ],
      );
      expect(merged.length, 2);
      // 同 id：保留勾选态与能力字段；已有非空 label 优先。
      expect(merged[0].id, 'model-a');
      expect(merged[0].enabled, isTrue);
      expect(merged[0].imageRatios, ['16:9']);
      expect(merged[0].label, 'A（手填名）');
      // 新模型：默认未勾选。
      expect(merged[1].id, 'model-new');
      expect(merged[1].enabled, isFalse);
    });

    test('同 id 且原 label 为空时用拉取的 label 补齐', () {
      final merged = ModelFetcher.mergeFetched(
        existing: const [ProviderModel(id: 'm1', label: '')],
        fetched: [(id: 'm1', label: '补齐名')],
      );
      expect(merged.single.label, '补齐名');
      expect(merged.single.enabled, isTrue);
    });

    test('保留拉取结果之外的手填模型', () {
      final merged = ModelFetcher.mergeFetched(
        existing: const [
          ProviderModel(id: 'manual-1', label: '手填', enabled: true),
        ],
        fetched: [(id: 'remote-1', label: '远端')],
      );
      expect(merged.map((m) => m.id), containsAll(['remote-1', 'manual-1']));
      expect(merged.firstWhere((m) => m.id == 'manual-1').enabled, isTrue);
    });
  });

  group('ProviderModelCodec 勾选态兼容', () {
    test('旧数据（无 enabled 字段）解码默认启用', () {
      final models = ProviderModelCodec.decode(
        jsonEncode([
          {'id': 'a', 'label': 'A'},
        ]),
      );
      expect(models.single.enabled, isTrue);
    });

    test('新数据含勾选态与能力字段往返', () {
      final models = ProviderModelCodec.decode(
        ProviderModelCodec.encode([
          const ProviderModel(id: 'a', label: 'A', enabled: false),
          const ProviderModel(
            id: 'b',
            label: 'B',
            imageRatios: ['16:9', '9:16'],
            durationResolutions: [
              (duration: [4, 8], resolution: ['720p', '1080p']),
            ],
            contextWindow: 128000,
          ),
        ]),
      );
      expect(models[0].enabled, isFalse);
      expect(models[1].enabled, isTrue);
      expect(models[1].imageRatios, ['16:9', '9:16']);
      expect(models[1].durationResolutions?.single.duration, [4, 8]);
      expect(models[1].durationResolutions?.single.resolution, ['720p', '1080p']);
      expect(models[1].contextWindow, 128000);
    });

    test('未勾选模型序列化为 enabled:false', () {
      final raw = ProviderModelCodec.encode([
        const ProviderModel(id: 'a', label: 'A', enabled: false),
      ]);
      expect(raw, contains('"enabled":false'));
      // 启用态不序列化 enabled 字段（省缺省）。
      final rawEnabled = ProviderModelCodec.encode([
        const ProviderModel(id: 'b', label: 'B'),
      ]);
      expect(rawEnabled, isNot(contains('"enabled"')));
    });
  });
}

/// 按 URL 返回固定响应体的假适配器。
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._routes);

  final Map<String, String> _routes;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = options.uri.toString();
    final body = _routes[key];
    if (body == null) {
      return ResponseBody.fromString('not found', 404);
    }
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}
