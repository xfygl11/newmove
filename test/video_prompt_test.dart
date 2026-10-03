import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/shot/video_prompt.dart';

void main() {
  Shot shot({int durationMs = 12000}) {
    return Shot(
      id: 1,
      scriptId: 1,
      globalSeq: 'G01',
      batch: 1,
      durationMs: durationMs,
      globalTimeRange: '00:00-00:12',
      beatRefs: '[]',
      assetStates: '{}',
      prompt: '本段目标事件',
      status: '已确认',
      outputType: 'image',
    );
  }

  ShotFrame frame({
    int seq = 1,
    String timeRange = '00:00-00:06',
    String subject = '阿青',
    String shotSize = '中景',
    String angle = '平视',
    String camera = '固定',
    String blocking = '阿青位于画面左侧，老者在右侧',
    String performance = '扶起老者',
    String? dialogue,
  }) {
    return ShotFrame(
      id: seq,
      shotId: 1,
      seq: seq,
      timeRange: timeRange,
      subject: subject,
      shotSize: shotSize,
      angle: angle,
      camera: camera,
      blocking: blocking,
      performance: performance,
      dialogue: dialogue,
    );
  }

  group('VideoPromptBuilder A9.2 Timeline（时间块 + 连续自然语言）', () {
    test('单帧：时间块头部 + 成片式描述 + 台词嵌入，无 HARD CUT', () {
      final prompt = const VideoPromptBuilder().build(
        shot: shot(),
        frames: [
          frame(dialogue: '快走'),
        ],
        refs: const [],
        assetById: const {},
      );

      expect(prompt, contains('【0:00-0:06】'));
      // 连续自然语言：主体/站位/表演/台词组织成段落，无表行分隔符。
      expect(prompt, contains('画面为中景，平视，主体是阿青'));
      expect(prompt, contains('阿青位于画面左侧，老者在右侧'));
      expect(prompt, contains('扶起老者'));
      expect(prompt, contains('同期对白「快走」'));
      expect(prompt, isNot(contains('HARD CUT')));
      expect(prompt, isNot(contains(' | ')));
      // 固定运镜不显式声明。
      expect(prompt, isNot(contains('镜头固定')));
    });

    test('多帧：帧间 HARD CUT 提示 + 各自时间块', () {
      final prompt = const VideoPromptBuilder().build(
        shot: shot(),
        frames: [
          frame(timeRange: '00:00-00:06'),
          frame(
            seq: 2,
            timeRange: '00:06-00:12',
            subject: '阿青',
            shotSize: '近景',
            angle: '正面',
            camera: '推近',
            performance: '起身快步离开',
            dialogue: null,
          ),
        ],
        refs: const [],
        assetById: const {},
      );

      expect(prompt, contains('【0:00-0:06】'));
      expect(prompt, contains('【0:06-0:12】'));
      expect(prompt, contains('HARD CUT'));
      expect(prompt, contains('近景，正面'));
      expect(prompt, contains('镜头推近')); // 非固定运镜写为「镜头+动作」。
    });

    test('九字段外壳完整且顺序固定（A9.2.0 格式硬门）', () {
      final prompt = const VideoPromptBuilder().build(
        shot: shot(),
        frames: [frame()],
        refs: const [],
        assetById: const {},
      );

      final order = [
        'Objective:',
        'Reference binding:',
        'Immutable locks:',
        'Target duration: 12s',
        'Timeline:',
        'Visual direction:',
        'Audio direction:',
        'Preserve:',
        'Avoid:',
      ];
      var last = -1;
      for (final field in order) {
        final idx = prompt.indexOf(field);
        expect(idx, greaterThan(last), reason: '$field 应出现在 $field 之前之后');
        last = idx;
      }
    });

    test('空帧兜底：Objective 底稿进 Timeline', () {
      final prompt = const VideoPromptBuilder().build(
        shot: shot(),
        frames: const [],
        refs: const [],
        assetById: const {},
      );

      expect(prompt, contains('【0:00-0:12】'));
      expect(prompt, contains('本段目标事件'));
    });
  });
}
