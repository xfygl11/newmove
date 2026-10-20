import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/shot/video_prompt_gate.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('VideoPromptGate（M45）', () {
    test('timelineEmpty 无 Timeline 块', () {
      final shot = _makeShot(id: 1, globalSeq: 'G01');
      final prompt = 'Objective: test\nReference binding:\n- 无';
      final issues = VideoPromptGate.timelineEmpty(shot, prompt);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'timeline_empty');
    });

    test('timelineEmpty 有 Timeline 块', () {
      final shot = _makeShot(id: 1, globalSeq: 'G01');
      final prompt = 'Objective: test\nTimeline:\n【0:00-0:05】\n画面描述';
      final issues = VideoPromptGate.timelineEmpty(shot, prompt);
      expect(issues, isEmpty);
    });

    test('durationMismatch 时长一致', () {
      final shot = _makeShot(id: 1, globalSeq: 'G01', durationMs: 5000);
      final prompt = 'Target duration: 5s\nTimeline:\n...';
      final issues = VideoPromptGate.durationMismatch(shot, prompt);
      expect(issues, isEmpty);
    });

    test('durationMismatch 时长不一致', () {
      final shot = _makeShot(id: 1, globalSeq: 'G01', durationMs: 5000);
      final prompt = 'Target duration: 10s\nTimeline:\n...';
      final issues = VideoPromptGate.durationMismatch(shot, prompt);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'duration_mismatch');
    });

    test('referenceEmpty 无参考图', () {
      final shot = _makeShot(id: 1, globalSeq: 'G01', assetStates: '[]');
      final issues = VideoPromptGate.referenceEmpty(shot);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'reference_empty');
    });

    test('referenceEmpty 有参考图', () {
      final shot = _makeShot(
        id: 1,
        globalSeq: 'G01',
        assetStates: '[{"assetId":1,"role":"character"}]',
      );
      final issues = VideoPromptGate.referenceEmpty(shot);
      expect(issues, isEmpty);
    });

    test('missingDialogue 台词缺失', () {
      final shot = _makeShot(id: 1, globalSeq: 'G01', beatRefs: '["E001"]');
      final beats = [_makeBeat(sourceRef: 'E001', content: '你好世界，这是一段很长的台词')];
      final prompt = 'Timeline:\n【0:00-0:05】\n画面描述';
      final issues = VideoPromptGate.missingDialogue(shot, beats, prompt);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'missing_dialogue');
    });

    test('missingDialogue 台词包含', () {
      final shot = _makeShot(id: 1, globalSeq: 'G01', beatRefs: '["E001"]');
      final beats = [_makeBeat(sourceRef: 'E001', content: '你好世界')];
      final prompt = 'Timeline:\n【0:00-0:05】\n同期对白「你好世界」';
      final issues = VideoPromptGate.missingDialogue(shot, beats, prompt);
      expect(issues, isEmpty);
    });

    test('validate 全部检查', () {
      final shot = _makeShot(
        id: 1,
        globalSeq: 'G01',
        durationMs: 5000,
        assetStates: '[]',
        beatRefs: '["E001"]',
      );
      final beats = [_makeBeat(sourceRef: 'E001', content: '测试台词')];
      final prompt =
          'Objective: test\nReference binding:\n- 无\nTarget duration: 10s\nTimeline:\n【0:00-0:05】\n画面';
      final issues = VideoPromptGate.validate(
        shot: shot,
        prompt: prompt,
        beats: beats,
      );
      expect(issues.length, greaterThanOrEqualTo(2));
      final codes = issues.map((i) => i.code).toSet();
      expect(codes, contains('duration_mismatch'));
      expect(codes, contains('reference_empty'));
      expect(codes, contains('missing_dialogue'));
    });
  });
}

Shot _makeShot({
  required int id,
  required String globalSeq,
  int durationMs = 5000,
  String assetStates = '[]',
  String beatRefs = '[]',
}) {
  return Shot(
    id: id,
    scriptId: 1,
    globalSeq: globalSeq,
    batch: 1,
    durationMs: durationMs,
    globalTimeRange: '00:00-00:05',
    beatRefs: beatRefs,
    assetStates: assetStates,
    prompt: 'test prompt',
    status: 'draft',
    outputType: 'image',
    isStale: 0,
  );
}

Beat _makeBeat({
  required String sourceRef,
  String content = '',
}) {
  return Beat(
    id: 1,
    sceneId: 1,
    seq: 1,
    type: 'dialogue',
    who: '角色A',
    content: content,
    sourceRef: sourceRef,
    estDurationMs: 3000,
    tags: '[]',
  );
}
