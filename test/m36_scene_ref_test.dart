import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/features/shot/shot_models.dart';

void main() {
  group('ShotFrameDraft isSceneRef（M36）', () {
    test('fromJson 解析 isSceneRef=true', () {
      final json = {
        'seq': 1,
        'timeRange': '0-5s',
        'subject': '主角',
        'shotSize': '中景',
        'angle': '平视',
        'camera': '',
        'blocking': '',
        'performance': '',
        'isSceneRef': true,
      };
      final draft = ShotFrameDraft.fromJson(json);
      expect(draft.isSceneRef, isTrue);
    });

    test('fromJson 解析 isSceneRef=false', () {
      final json = {
        'seq': 1,
        'timeRange': '0-5s',
        'subject': '主角',
        'shotSize': '中景',
        'angle': '平视',
        'camera': '',
        'blocking': '',
        'performance': '',
        'isSceneRef': false,
      };
      final draft = ShotFrameDraft.fromJson(json);
      expect(draft.isSceneRef, isFalse);
    });

    test('fromJson 缺 isSceneRef 字段回落 false', () {
      final json = {
        'seq': 1,
        'timeRange': '0-5s',
        'subject': '主角',
        'shotSize': '中景',
        'angle': '平视',
        'camera': '',
        'blocking': '',
        'performance': '',
      };
      final draft = ShotFrameDraft.fromJson(json);
      expect(draft.isSceneRef, isFalse);
    });

    test('构造函数默认 isSceneRef=false', () {
      final draft = const ShotFrameDraft(
        seq: 1,
        timeRange: '0-5s',
        subject: '主角',
        shotSize: '中景',
        angle: '平视',
        camera: '',
        blocking: '',
        performance: '',
        dialogue: null,
      );
      expect(draft.isSceneRef, isFalse);
    });

    test('构造函数显式 isSceneRef=true', () {
      final draft = const ShotFrameDraft(
        seq: 1,
        timeRange: '0-5s',
        subject: '场景',
        shotSize: '全景',
        angle: '平视',
        camera: '',
        blocking: '',
        performance: '',
        dialogue: null,
        isSceneRef: true,
      );
      expect(draft.isSceneRef, isTrue);
    });
  });
}
