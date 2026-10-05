import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/shot/shot_models.dart';
import 'package:newmove/features/shot/video_prompt.dart';

void main() {
  group('ShotDraft 段级摄影参数解析（T21.12）', () {
    test('九个字段全部解析成功，数值字段取整', () {
      final draft = ShotDraft.fromJson({
        'globalSeq': 'G01',
        'shotType': '近景',
        'prompt': '提示词',
        'composition': '三分法，主体位于画面左三分之一',
        'lens': '短焦肖像感，背景轻度虚化',
        'cameraPosition': '平视低位，离主体约两米',
        'eyeline': '看向画外右侧',
        'focus': '锁主角面部',
        'stability': '三脚架固定',
        'blocking': '从画面右侧入画，横移至左三分之一处停步',
        'dialogueStartRatio': 20.4,
        'dialogueEndRatio': '75',
        'frames': [],
        'refs': [],
      });

      expect(draft.composition, '三分法，主体位于画面左三分之一');
      expect(draft.lens, '短焦肖像感，背景轻度虚化');
      expect(draft.cameraPosition, '平视低位，离主体约两米');
      expect(draft.eyeline, '看向画外右侧');
      expect(draft.focus, '锁主角面部');
      expect(draft.stability, '三脚架固定');
      expect(draft.blocking, '从画面右侧入画，横移至左三分之一处停步');
      expect(draft.dialogueStartRatio, 20);
      expect(draft.dialogueEndRatio, 75);
    });

    test('占位词与空白一律视为未指定', () {
      final draft = ShotDraft.fromJson({
        'globalSeq': 'G02',
        'shotType': '中景',
        'prompt': '提示词',
        'composition': '无',
        'lens': '   ',
        'cameraPosition': '同上',
        'eyeline': 'N/A',
        'focus': '',
        'stability': '-',
        'blocking': '未指定',
        'frames': [],
        'refs': [],
      });

      expect(draft.composition, isNull);
      expect(draft.lens, isNull);
      expect(draft.cameraPosition, isNull);
      expect(draft.eyeline, isNull);
      expect(draft.focus, isNull);
      expect(draft.stability, isNull);
      expect(draft.blocking, isNull);
      expect(draft.dialogueStartRatio, isNull);
      expect(draft.dialogueEndRatio, isNull);
    });

    test('对白占比越界与不可解析视为未指定，边界值保留', () {
      ShotDraft parse(Object? start, Object? end) => ShotDraft.fromJson({
            'globalSeq': 'G03',
            'shotType': '中景',
            'prompt': '提示词',
            'dialogueStartRatio': start,
            'dialogueEndRatio': end,
            'frames': [],
            'refs': [],
          });

      expect(parse(-1, 200).dialogueStartRatio, isNull);
      expect(parse(0, 200).dialogueEndRatio, isNull);
      expect(parse('abc', null).dialogueStartRatio, isNull);
      expect(parse(0, 100).dialogueStartRatio, 0);
      expect(parse(0, 100).dialogueEndRatio, 100);
    });

    test('缺字段的旧输出照常解析，全部回落 null', () {
      final draft = ShotDraft.fromJson({
        'globalSeq': 'G04',
        'shotType': '中景',
        'prompt': '提示词',
        'frames': [],
        'refs': [],
      });

      expect(draft.composition, isNull);
      expect(draft.blocking, isNull);
      expect(draft.dialogueStartRatio, isNull);
      expect(draft.dialogueEndRatio, isNull);
      expect(draft.frames, isEmpty);
    });

    test('景别与角度归一化不受新增字段影响', () {
      final draft = ShotDraft.fromJson({
        'globalSeq': 'G05',
        'shotType': '大特写',
        'prompt': '提示词',
        'frames': [
          {
            'seq': 1,
            'timeRange': '00:00-00:05',
            'subject': '阿青',
            'shotSize': '近景',
            'angle': '镜头角度：俯视',
            'camera': '固定',
            'blocking': '',
            'performance': '',
          },
        ],
        'refs': [],
      });

      expect(draft.shotType, '特写');
      expect(draft.frames.single.angle, '俯视');
    });
  });

  group('段级摄影参数进视频提示词', () {
    Shot shot({
      String? composition,
      String? lens,
      String? cameraPosition,
      String? eyeline,
      String? focus,
      String? stability,
      String? blocking,
    }) {
      return Shot(
        id: 1,
        scriptId: 1,
        globalSeq: 'G01',
        batch: 1,
        durationMs: 12000,
        globalTimeRange: '00:00-00:12',
        beatRefs: '[]',
        assetStates: '{}',
        prompt: '本段目标事件',
        status: '已确认',
        isStale: 0,
        outputType: 'image',
        composition: composition,
        lens: lens,
        cameraPosition: cameraPosition,
        eyeline: eyeline,
        focus: focus,
        stability: stability,
        blocking: blocking,
      );
    }

    test('cinemaSpec 按项拼接，缺项跳过', () {
      expect(shot().cinemaSpec, '');
      expect(
        shot(
          composition: '三分法，主体位于画面左三分之一',
          focus: '锁主角面部',
        ).cinemaSpec,
        '构图：三分法，主体位于画面左三分之一，焦点：锁主角面部',
      );
    });

    test('cinemaSpec 覆盖全部六项文本字段', () {
      final spec = shot(
        composition: '中心构图',
        lens: '中焦平面感',
        cameraPosition: '平视，离主体约两米',
        eyeline: '看向画外右侧',
        focus: '锁主角面部',
        stability: '手持微晃',
        blocking: '从右侧入画后停步',
      ).cinemaSpec;

      expect(spec, contains('构图：中心构图'));
      expect(spec, contains('焦距：中焦平面感'));
      expect(spec, contains('机位：平视，离主体约两米'));
      expect(spec, contains('视线：看向画外右侧'));
      expect(spec, contains('焦点：锁主角面部'));
      expect(spec, contains('稳定性：手持微晃'));
      expect(spec, contains('走位：从右侧入画后停步'));
    });

    test('有参数时提示词含 Camera spec 行，无参数时不出现该行', () {
      ShotFrame frame() => ShotFrame(
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
            dialogue: null,
          );

      const builder = VideoPromptBuilder();

      final withSpec = builder.build(
        shot: shot(
          composition: '三分法，主体位于画面左三分之一',
          focus: '锁主角面部',
        ),
        frames: [frame()],
        refs: const [],
        assetById: const {},
      );
      expect(
        withSpec,
        contains('Camera spec: 构图：三分法，主体位于画面左三分之一，焦点：锁主角面部'),
      );
      expect(withSpec, contains('Target duration: 12s'));

      final withoutSpec = builder.build(
        shot: shot(),
        frames: [frame()],
        refs: const [],
        assetById: const {},
      );
      expect(withoutSpec, isNot(contains('Camera spec')));
    });
  });
}
