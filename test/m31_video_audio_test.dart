import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/shot/shot_models.dart';
import 'package:newmove/features/shot/video_prompt.dart';

Shot shot({
  int durationMs = 12000,
  String? soundDesign,
  String? musicCue,
  String? videoScript,
  String? depthOfField,
  String? lens,
}) {
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
    isStale: 0,
    outputType: 'image',
    soundDesign: soundDesign,
    musicCue: musicCue,
    videoScript: videoScript,
    depthOfField: depthOfField,
    lens: lens,
  );
}

ShotFrame frame() => const ShotFrame(
  id: 1,
  shotId: 1,
  seq: 1,
  timeRange: '00:00-00:06',
  subject: '阿青',
  shotSize: '中景',
  angle: '平视',
  camera: '固定',
  blocking: '阿青位于画面左侧',
  performance: '扶起老者',
  dialogue: '快走',
);

void main() {
  group('ShotSoundDesign.decode 容错', () {
    test('空串 / null 返回空对象', () {
      expect(ShotSoundDesign.decode(null).isEmpty, isTrue);
      expect(ShotSoundDesign.decode('').isEmpty, isTrue);
    });

    test('坏 JSON 返回空对象不抛错', () {
      expect(ShotSoundDesign.decode('not-json').isEmpty, isTrue);
    });

    test('正常 JSON 解析两层字符串数组', () {
      final sound = ShotSoundDesign.decode(
        '{"ambience":["风声"],"sfx":["关门声","脚步声"]}',
      );
      expect(sound.ambience, ['风声']);
      expect(sound.sfx, ['关门声', '脚步声']);
    });
  });

  group('ShotDraft 四字段解析（M29）', () {
    test('depthOfField / musicCue / videoScript 字符串解析，空回落 null', () {
      final draft = ShotDraft.fromJson({
        'globalSeq': 'G01',
        'shotType': '中景',
        'prompt': 'p',
        'depthOfField': '背景轻度虚化',
        'musicCue': '00:00 弦乐渐入',
        'videoScript': '中景平视，人物走向前。',
      });
      expect(draft.depthOfField, '背景轻度虚化');
      expect(draft.musicCue, '00:00 弦乐渐入');
      expect(draft.videoScript, '中景平视，人物走向前。');
    });

    test('soundDesign 对象编码成 JSON 字符串，空对象回落 null', () {
      final draft = ShotDraft.fromJson({
        'globalSeq': 'G01',
        'shotType': '中景',
        'prompt': 'p',
        'soundDesign': {'ambience': ['风声'], 'sfx': ['关门声']},
      });
      expect(draft.soundDesign, isNotNull);
      expect(draft.soundDesign, contains('风声'));
      expect(draft.soundDesign, contains('关门声'));

      final empty = ShotDraft.fromJson({
        'globalSeq': 'G01',
        'shotType': '中景',
        'prompt': 'p',
        'soundDesign': <String, dynamic>{},
      });
      expect(empty.soundDesign, isNull);
    });
  });

  group('VideoPromptBuilder 音频方向（M29）', () {
    test('无音频字段回落默认「不加 BGM」', () {
      final prompt = const VideoPromptBuilder().build(
        shot: shot(),
        frames: [frame()],
        refs: const [],
        assetById: const {},
      );
      expect(
        prompt,
        contains('Audio direction: 同期对白与环境音，不加 BGM 与后期字幕'),
      );
    });

    test('有音效 + 音乐 + 集级 BGM 时输出对应层级', () {
      final prompt = const VideoPromptBuilder().build(
        shot: shot(
          soundDesign: '{"ambience":["风声"],"sfx":["关门声"]}',
          musicCue: '00:00 弦乐渐入',
        ),
        frames: [frame()],
        refs: const [],
        assetById: const {},
        bgmUrl: 'https://example.com/bgm.mp3',
      );
      expect(prompt, contains('环境音：风声'));
      expect(prompt, contains('音效：关门声'));
      expect(prompt, contains('音乐提示：00:00 弦乐渐入'));
      expect(prompt, contains('集级背景音乐：https://example.com/bgm.mp3'));
      expect(prompt, isNot(contains('不加 BGM 与后期字幕')));
    });
  });

  group('VideoPromptBuilder 视频脚本分离（M29）', () {
    test('videoScript 非空时作为 Timeline 底稿，不用逐帧拼装', () {
      final prompt = const VideoPromptBuilder().build(
        shot: shot(videoScript: '中景平视，人物从右入画走向前。'),
        frames: [frame()],
        refs: const [],
        assetById: const {},
      );
      expect(prompt, contains('中景平视，人物从右入画走向前。'));
      // 逐帧拼装不会出现「镜头」运镜词，而 videoScript 底稿只输出其本身。
      expect(prompt, contains('Timeline:'));
    });

    test('videoScript 为空回落逐帧拼装', () {
      final prompt = const VideoPromptBuilder().build(
        shot: shot(),
        frames: [frame()],
        refs: const [],
        assetById: const {},
      );
      expect(prompt, contains('画面为中景，平视，主体是阿青'));
    });
  });

  group('cinemaSpec 景深独立行（M29）', () {
    test('lens 与 depthOfField 各自成行', () {
      final s = shot(lens: '短焦肖像感', depthOfField: '背景轻度虚化');
      expect(s.cinemaSpec, contains('焦距：短焦肖像感'));
      expect(s.cinemaSpec, contains('景深：背景轻度虚化'));
    });

    test('无景深时不输出景深行', () {
      final s = shot(lens: '短焦肖像感');
      expect(s.cinemaSpec, contains('焦距：短焦肖像感'));
      expect(s.cinemaSpec, isNot(contains('景深')));
    });
  });
}
