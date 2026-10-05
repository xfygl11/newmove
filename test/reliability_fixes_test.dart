import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/network/protocols.dart';
import 'package:newmove/core/text/text_util.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/provider_dao.dart';
import 'package:newmove/features/provider_config/agnes_presets.dart';
import 'package:newmove/features/shot/shot_models.dart';
import 'package:newmove/widgets/image_version_panel.dart';

void main() {
  group('TextUtil.clip', () {
    test('未超限原样返回', () {
      expect(TextUtil.clip('你好', 4), '你好');
      expect(TextUtil.clip('你好', 2), '你好');
      expect(TextUtil.clip('', 10), '');
    });

    test('按码元截断', () {
      expect(TextUtil.clip('abcd', 2), 'ab');
      expect(TextUtil.clip('你好世界', 3), '你好世');
      // emoji 占两个码元：切点正好落进代理对必须回退一位。
      expect(TextUtil.clip('你好😀', 3), '你好');
      expect(TextUtil.clip('你😀', 2), '你');
    });

    test('切点落在代理对中间时回退，不留孤立低代理', () {
      // emoji 占两个码元：limit 落在中间必须回退一位。
      final emoji = '\u{1F600}';
      expect(TextUtil.clip('abc$emoji', 4), 'abc');
      expect(TextUtil.clip(emoji, 1), '');
      expect(TextUtil.clip('$emoji😀', 2), emoji);
      // 截断结果不能含孤立代理，否则 utf8.encode 抛 FormatException。
      for (final clipped in [
        TextUtil.clip('前缀$emoji后缀', 4),
        TextUtil.clip('前缀$emoji后缀', 5),
      ]) {
        expect(utf8.encode(clipped), isA<List<int>>(), reason: clipped);
      }
    });

    test('limit 为 0 或负数返回空串', () {
      expect(TextUtil.clip('abc', 0), '');
      expect(TextUtil.clip('abc', -3), '');
    });
  });

  group('imagePathOfSnapshot', () {
    test('兼容 imagePath 与 outputPath 两种快照键', () {
      // 资产快照写 imagePath，镜头快照写 outputPath；两者都必须能取到。
      final items = [
        ImageVersionItem(
          label: '资产版本',
          path: imagePathOfSnapshot('{"imagePath":"/a/asset_1.png"}'),
        ),
        ImageVersionItem(
          label: '镜头版本',
          path: imagePathOfSnapshot('{"outputPath":"/b/shot_1.png"}'),
        ),
        ImageVersionItem(label: '损坏快照', path: imagePathOfSnapshot('not json')),
      ];

      // 历史版本曾全部取不到路径：path 为 null 时点击条目会在 item.path! 崩。
      expect(items.map((i) => i.path), [
        '/a/asset_1.png',
        '/b/shot_1.png',
        isNull,
      ]);
    });

    test('快照无图片路径时返回 null', () {
      expect(imagePathOfSnapshot('{}'), isNull);
      expect(imagePathOfSnapshot('{"status":"成功"}'), isNull);
    });
  });

  group('ShotFrameDraft.normalizeAngle', () {
    test('容错词表归一化', () {
      expect(ShotFrameDraft.normalizeAngle('平视'), '平视');
      expect(ShotFrameDraft.normalizeAngle('镜头角度：平视'), '平视');
      expect(ShotFrameDraft.normalizeAngle('俯视'), '俯视');
      expect(ShotFrameDraft.normalizeAngle('overhead'), '俯视');
      expect(ShotFrameDraft.normalizeAngle('仰视'), '仰视');
      expect(ShotFrameDraft.normalizeAngle('低角度仰拍'), '仰视');
      expect(ShotFrameDraft.normalizeAngle('背面'), '背面');
      expect(ShotFrameDraft.normalizeAngle('侧面'), '侧面');
      expect(ShotFrameDraft.normalizeAngle('未知角度'), '平视');
    });

    test('空串回落平视', () {
      expect(ShotFrameDraft.normalizeAngle(''), '平视');
      expect(ShotFrameDraft.normalizeAngle('   '), '平视');
    });
  });

  group('ShotModels 从 JSON 解析角度', () {
    test('LLM 给的非词表角度也被归一化落库', () {
      final frame = ShotFrameDraft.fromJson(
        json.decode(
          '{"seq":1,"timeRange":"00:00-00:06","subject":"阿青",'
          '"shotSize":"中景","angle":"overhead shot"}',
        ) as Map<String, dynamic>,
      );
      expect(frame.angle, '俯视');
    });
  });

  group('AgnesPresets.apply', () {
    late AppDatabase db;
    late ProviderDao dao;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.providerDao;
    });

    tearDown(() async {
      await db.close();
    });

    test('三条预设按协议落库，Base URL 一致', () async {
      await AgnesPresets.apply(
        dao: dao,
        apiKey: 'sk-test',
        keyWriter: (_, _) async {},
      );
      final rows = await dao.listAll();

      expect(rows, hasLength(3));
      expect(rows.map((r) => r.id), {'agnes-llm', 'agnes-image', 'agnes-video'});
      expect(rows.map((r) => r.protocol), {
        Protocols.openaiChat,
        Protocols.openaiImages,
        Protocols.openaiVideos,
      });
      expect(rows.every((r) => r.baseUrl == AgnesPresets.baseUrl), isTrue);
    });

    test('Key 写入失败必须抛出让 UI 可见', () async {
      // keyWriter 声明为 Future<void> 并被 await：写入失败不能变成
      // fire-and-forget 后「条目已建但无 Key、后续静默 401」。
      await expectLater(
        AgnesPresets.apply(
          dao: dao,
          apiKey: 'sk-test',
          keyWriter: (_, _) async => throw StateError('Keystore 不可用'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('后续条目已建但 Key 缺失时同样抛错，便于用户重试', () async {
      await expectLater(
        AgnesPresets.apply(
          dao: dao,
          apiKey: 'sk-test',
          keyWriter: (id, _) async {
            if (id == 'agnes-image') throw StateError('Keystore 不可用');
          },
        ),
        throwsA(isA<StateError>()),
      );
      // 失败点之前的条目已经落库：这是可接受的中间态，
      // 只要错误能传到 UI，用户重跑就是幂等 upsert。
      final rows = await dao.listAll();
      expect(rows.map((r) => r.id), {'agnes-llm', 'agnes-image'});
    });
  });
}
