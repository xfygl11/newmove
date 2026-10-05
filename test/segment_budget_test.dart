import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/provider_config/provider_models.dart';
import 'package:newmove/features/shot/segment_budget.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<Script> script({
    int? episodeNo,
    int targetDurationMs = 0,
    String? modelVersion,
  }) async {
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '项目'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '书'),
    );
    final id = await db.scriptDao.insert(
      ScriptsCompanion.insert(
        bookId: bookId,
        title: '剧本',
        episodeNo: Value(episodeNo),
        targetDurationMs: Value(targetDurationMs),
        modelVersion: Value(modelVersion),
      ),
    );
    return (await db.scriptDao.find(id))!;
  }

  List<SegmentBudgetIssue> validate(
    Script script,
    List<Shot> segments,
    List<Beat> beats, [
    ProviderModel? model,
  ]) {
    return SegmentBudget(
      script: script,
      segments: segments,
      beats: beats,
      videoModel: model,
    ).validate();
  }

  Set<String> codesOf(List<SegmentBudgetIssue> issues) => {
    for (final issue in issues) issue.code,
  };

  ProviderModel modelWithDurations(List<int> seconds) => ProviderModel(
    id: 'm',
    label: 'm',
    durationResolutions: [
      (duration: seconds, resolution: ['1080p']),
    ],
  );

  Future<Script> emptyScript({String? modelVersion}) =>
      script(modelVersion: modelVersion);

  Future<List<Shot>> insertSegments(Script script, Map<String, int> durations) {
    return Future(() async {
      for (final entry in durations.entries) {
        await db.shotDao.insert(
          ShotsCompanion.insert(
            scriptId: script.id,
            globalSeq: entry.key,
            durationMs: Value(entry.value),
            globalTimeRange: '00:00-00:05',
          ),
        );
      }
      return db.shotDao.listByScript(script.id);
    });
  }

  Future<List<Beat>> insertBeats(
    Script script,
    Map<String, int> durations,
  ) async {
    final sceneId = await db.sceneDao.insert(
      ScenesCompanion.insert(
        scriptId: script.id,
        seq: 1,
        location: '场',
        time: '日',
      ),
    );
    var i = 0;
    for (final entry in durations.entries) {
      i++;
      await db.beatDao.insert(
        BeatsCompanion.insert(
          sceneId: sceneId,
          seq: i,
          type: '对白',
          content: entry.key,
          sourceRef: entry.key,
          estDurationMs: Value(entry.value),
        ),
      );
    }
    return db.beatDao.listByScript(script.id);
  }

  group('时长上限三级回落', () {
    test('无模型能力与无版本时取通用默认 15s', () async {
      final budget = SegmentBudget(
        script: await emptyScript(),
        segments: const [],
        beats: const [],
      );
      expect(budget.maxSegmentMs, 15000);
      expect(budget.mergeBudgetMs, 13500);
      expect(budget.maxBatchSegments, 6);
    });

    test('剧本 modelVersion 回落', () async {
      final v20 = SegmentBudget(
        script: await emptyScript(modelVersion: '2.0'),
        segments: const [],
        beats: const [],
      );
      expect(v20.maxSegmentMs, 15000);
      expect(v20.mergeBudgetMs, 13500);
      expect(v20.maxBatchSegments, 6);

      final v25 = SegmentBudget(
        script: await emptyScript(modelVersion: '2.5'),
        segments: const [],
        beats: const [],
      );
      expect(v25.maxSegmentMs, 30000);
      expect(v25.mergeBudgetMs, 27000);
      expect(v25.maxBatchSegments, 3);
    });

    test('运行时模型能力优先于剧本版本，批次容量仍由版本决定', () async {
      final budget = SegmentBudget(
        script: await emptyScript(modelVersion: '2.0'),
        segments: const [],
        beats: const [],
        videoModel: modelWithDurations([10, 15, 20]),
      );
      expect(budget.maxSegmentMs, 20000);
      expect(budget.maxBatchSegments, 6);
    });

    test('理论最少段数只作下限', () async {
      final budget = SegmentBudget(
        script: await emptyScript(),
        segments: const [],
        beats: const [],
      );
      expect(budget.theoreticalMinSegments(45000), 3);
      expect(budget.theoreticalMinSegments(16000), 2);
      expect(budget.theoreticalMinSegments(0), 1);
    });
  });

  group('五条校验', () {
    test('段时长超上限 → over_limit(error)', () async {
      final s = await emptyScript(modelVersion: '2.0');
      final segs = await insertSegments(s, {'G01': 16000});
      final issues = validate(s, segs, const []);
      expect(codesOf(issues), {'over_limit'});
      expect(issues.single.severity, SegmentBudgetSeverity.error);
      expect(issues.single.seq, 'G01');
    });

    test('引用节拍时长求和超段时长 → dialogue_overflow(error)', () async {
      final s = await emptyScript(modelVersion: '2.0');
      final beats = await insertBeats(s, {'E1': 6000, 'E2': 10000});
      await db.shotDao.insert(
        ShotsCompanion.insert(
          scriptId: s.id,
          globalSeq: 'G01',
          durationMs: const Value(12000),
          beatRefs: const Value('["E1","E2"]'),
          globalTimeRange: '00:00-00:12',
        ),
      );
      final issues = validate(s, await db.shotDao.listByScript(s.id), beats);
      expect(codesOf(issues), {'dialogue_overflow'});
      expect(issues.single.severity, SegmentBudgetSeverity.error);
    });

    test('总量偏差超过 10% → total_mismatch(warn)', () async {
      final s = await script(modelVersion: '2.5', targetDurationMs: 60000);
      final segs = await insertSegments(s, {'G01': 25000, 'G02': 25000});
      final issues = validate(s, segs, const []);
      expect(codesOf(issues), {'total_mismatch'});
      expect(issues.single.severity, SegmentBudgetSeverity.warn);
    });

    test('段数低于理论最少 → too_few_segments(warn，与总量偏差同现)', () async {
      final s = await script(modelVersion: '2.5', targetDurationMs: 60000);
      final segs = await insertSegments(s, {'G01': 25000});
      final issues = validate(s, segs, const []);
      expect(codesOf(issues), contains('too_few_segments'));
      for (final issue in issues) {
        expect(issue.severity, SegmentBudgetSeverity.warn);
        expect(issue.isError, isFalse);
      }
    });

    test('单批段数超上限 → batch_too_large(warn)', () async {
      final s = await emptyScript(modelVersion: '2.5');
      for (var i = 1; i <= 4; i++) {
        await db.shotDao.insert(
          ShotsCompanion.insert(
            scriptId: s.id,
            globalSeq: 'G0$i',
            batch: const Value(1),
            durationMs: const Value(20000),
            globalTimeRange: '00:00-00:20',
          ),
        );
      }
      final issues = validate(s, await db.shotDao.listByScript(s.id), const []);
      expect(codesOf(issues), {'batch_too_large'});
      expect(issues.single.severity, SegmentBudgetSeverity.warn);
      expect(issues.single.seq, 'batch 1');
    });
  });

  group('边界', () {
    test('目标总时长为 0 时跳过总量与段数校验', () async {
      final s = await emptyScript(modelVersion: '2.0');
      final segs = await insertSegments(s, {'G01': 10000});
      final issues = validate(s, segs, const []);
      expect(issues, isEmpty);
    });

    test('全部合规时返回空列表', () async {
      final s = await script(modelVersion: '2.5', targetDurationMs: 50000);
      final beats = await insertBeats(s, {'E1': 15000});
      await db.shotDao.insert(
        ShotsCompanion.insert(
          scriptId: s.id,
          globalSeq: 'G01',
          durationMs: const Value(25000),
          beatRefs: const Value('["E1"]'),
          globalTimeRange: '00:00-00:25',
        ),
      );
      await db.shotDao.insert(
        ShotsCompanion.insert(
          scriptId: s.id,
          globalSeq: 'G02',
          durationMs: const Value(25000),
          globalTimeRange: '00:25-00:50',
        ),
      );
      final issues = validate(s, await db.shotDao.listByScript(s.id), beats);
      expect(issues, isEmpty);
    });

    test('error 判定与 note 文案', () async {
      final s = await emptyScript(modelVersion: '2.0');
      final segs = await insertSegments(s, {'G01': 20000});
      final issues = validate(s, segs, const []);
      final errors = issues.where((i) => i.isError).toList();
      expect(errors, hasLength(1));
      expect(errors.single.noteLine, contains('[error]'));
      expect(errors.single.noteLine, contains('G01'));
    });
  });
}
