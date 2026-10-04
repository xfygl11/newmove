import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/features/provider_config/model_presets.dart';
import 'package:newmove/features/provider_config/provider_models.dart';

void main() {
  group('ProviderModel 能力 getter', () {
    const model = ProviderModel(
      id: 'seedance-2.5',
      label: 'Seedance 2.5',
      durationResolutions: [
        (duration: [4, 5, 6], resolution: ['480p', '720p']),
        (duration: [10, 15], resolution: ['720p', '1080p']),
      ],
      audio: 'optional',
      videoModes: ['text', 'multiImage', 'startFrameOptional'],
      maxImageRefs: 8,
    );

    test('supportedDurations 升序去重', () {
      expect(model.supportedDurations, [4, 5, 6, 10, 15]);
    });

    test('resolutionsFor 按时长取并集', () {
      expect(model.resolutionsFor(5), ['480p', '720p']);
      expect(model.resolutionsFor(10), ['720p', '1080p']);
      expect(model.resolutionsFor(7), isEmpty);
    });

    test('无能力数据时返回空，不猜测', () {
      const bare = ProviderModel(id: 'x', label: 'x');
      expect(bare.supportedDurations, isEmpty);
      expect(bare.resolutionsFor(5), isEmpty);
      expect(bare.supportsStartFrame, isFalse);
      expect(bare.audioOptional, isTrue);
    });

    test('supportsStartFrame 识别首帧类模式', () {
      expect(model.supportsStartFrame, isTrue);
      const endOnly = ProviderModel(
        id: 'y',
        label: 'y',
        videoModes: ['text', 'multiImage'],
      );
      expect(endOnly.supportsStartFrame, isFalse);
    });

    test('音频三态', () {
      expect(const ProviderModel(id: 'a', label: 'a', audio: true)
          .audioRequired, isTrue);
      expect(const ProviderModel(id: 'b', label: 'b', audio: false)
          .audioDisabled, isTrue);
      expect(model.audioOptional, isTrue);
      expect(model.audioRequired, isFalse);
    });
  });

  group('ProviderModel codec', () {
    test('新字段 round-trip', () {
      const model = ProviderModel(
        id: 'm',
        label: 'M',
        durationResolutions: [
          (duration: [5], resolution: ['720p']),
        ],
        videoModes: ['text', 'startFrameOptional'],
        maxImageRefs: 6,
      );
      final decoded = ProviderModelCodec.decode(
        ProviderModelCodec.encode([model]),
      );
      expect(decoded.single.supportedDurations, [5]);
      expect(decoded.single.videoModes, ['text', 'startFrameOptional']);
      expect(decoded.single.maxImageRefs, 6);
    });
  });

  group('ModelPresets', () {
    test('命中 Seedance 2.5 补全能力', () {
      const bare = ProviderModel(id: 'seedance-2.5', label: 'Seedance 2.5');
      final filled = ModelPresets.apply(bare);
      expect(filled.supportedDurations.first, 4);
      expect(filled.supportedDurations.last, 30);
      expect(filled.resolutionsFor(5), ['480p', '720p', '1080p']);
      expect(filled.supportsStartFrame, isTrue);
      expect(filled.maxImageRefs, 9);
    });

    test('不覆盖用户已填能力', () {
      const custom = ProviderModel(
        id: 'seedance-2.5',
        label: 'Seedance 2.5',
        durationResolutions: [
          (duration: [8], resolution: ['720p']),
        ],
        maxImageRefs: 3,
      );
      final filled = ModelPresets.apply(custom);
      expect(filled.supportedDurations, [8]);
      expect(filled.maxImageRefs, 3);
    });

    test('未知模型保持原样', () {
      const bare = ProviderModel(id: 'unknown-model', label: 'Unknown');
      final filled = ModelPresets.apply(bare);
      expect(filled.supportedDurations, isEmpty);
      expect(filled.durationResolutions, isNull);
    });

    test('图片模型命中补尺寸画幅', () {
      const bare = ProviderModel(id: 'doubao-seedream-3', label: 'Seedream');
      final filled = ModelPresets.apply(bare);
      expect(filled.durationResolutions, isNull);
      expect(filled.imageSizes, isNotEmpty);
      expect(filled.imageRatios, contains('16:9'));
    });
  });
}
