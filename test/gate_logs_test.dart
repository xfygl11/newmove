import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/gate_codes.dart';
import 'package:newmove/core/gate_issue.dart';
import 'package:newmove/data/app_database.dart';

void main() {
  late AppDatabase db;
  late int projectId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
  });

  tearDown(() async {
    await db.close();
  });

  GateIssue issue(
    String code, {
    GateSeverity severity = GateSeverity.warn,
    String locator = '-',
    String message = '测试问题',
  }) =>
      GateIssue(code: code, severity: severity, locator: locator, message: message);

  group('GateLogDao.recordValidation', () {
    test('每道命中的门码写一行，同码多条问题合并成一条摘要', () async {
      final ok = await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.assets,
        subjectLabel: '资产提示词体检',
        gates: const ['提示词门'],
        issues: [
          issue(GateCodes.sceneNotEmpty, severity: GateSeverity.error, locator: '金銮殿'),
          issue(GateCodes.sceneNotEmpty, severity: GateSeverity.error, locator: '藏书阁'),
          issue(GateCodes.lightingMissing, locator: '主角'),
        ],
        projectId: projectId,
      );

      expect(ok, isTrue);
      final rows = await db.gateLogDao.all();
      expect(rows, hasLength(2));

      final rowsByCode = {for (final r in rows) r.gateId: r};
      expect(rowsByCode[GateCodes.sceneNotEmpty]!.subjectLabel, '资产提示词体检');
      expect(rowsByCode[GateCodes.sceneNotEmpty]!.subjectType, GateSubjects.assets);
      expect(rowsByCode[GateCodes.sceneNotEmpty]!.projectId, projectId);
      expect(rowsByCode[GateCodes.sceneNotEmpty]!.ok, 0);
      // 两条例子合并成一条，摘要里带上两条 locator 与门族名。
      expect(rowsByCode[GateCodes.sceneNotEmpty]!.detail, contains('金銮殿'));
      expect(rowsByCode[GateCodes.sceneNotEmpty]!.detail, contains('藏书阁'));
      expect(rowsByCode[GateCodes.sceneNotEmpty]!.detail, contains('提示词门'));
      expect(rowsByCode[GateCodes.lightingMissing]!.detail, contains('主角'));
    });

    test('无问题时不落任何行，直接返回 true', () async {
      final ok = await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.script,
        subjectLabel: '剧本台词体检',
        gates: const ['台词门'],
        issues: const [],
        projectId: projectId,
      );
      expect(ok, isTrue);
      expect(await db.gateLogDao.countRuns(), 0);
    });

    test('不传 projectId 时记为跨项目校验', () async {
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.characters,
        subjectLabel: '全局体检',
        gates: const ['角色门'],
        issues: [issue(GateCodes.tierCap)],
      );
      final row = (await db.gateLogDao.all()).single;
      expect(row.projectId, isNull);
    });

    test('subjectId 可空，用于定位单个体检对象', () async {
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.shots,
        subjectLabel: '分镜镜头',
        gates: const ['镜头门'],
        issues: [issue(GateCodes.frameEmpty)],
        subjectId: 'shot-12',
      );
      expect((await db.gateLogDao.all()).single.subjectId, 'shot-12');
    });
  });

  group('命中统计', () {
    test('hitsByGate 只统计 ok = 0 的行，按命中数降序', () async {
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.assets,
        subjectLabel: '体检 A',
        gates: const ['提示词门'],
        issues: [
          issue(GateCodes.sceneNotEmpty),
          issue(GateCodes.lightingMissing),
        ],
      );
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.assets,
        subjectLabel: '体检 B',
        gates: const ['提示词门'],
        issues: [issue(GateCodes.sceneNotEmpty)],
      );

      final hits = await db.gateLogDao.hitsByGate();
      expect(hits[GateCodes.sceneNotEmpty], 2);
      expect(hits[GateCodes.lightingMissing], 1);
      // 降序：命中最多的在前。
      expect(hits.keys.first, GateCodes.sceneNotEmpty);
    });

    test('seenGateIds 覆盖 ok = 1 与 ok = 0 两种行', () async {
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.script,
        subjectLabel: '体检',
        gates: const ['台词门'],
        issues: [issue(GateCodes.lineTooLong)],
      );
      final seen = await db.gateLogDao.seenGateIds();
      expect(seen, {GateCodes.lineTooLong});
    });

    test('可按 projectId 过滤，跨项目行只在全量统计里出现', () async {
      final otherProjectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '另一个项目'),
      );
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.assets,
        subjectLabel: '体检 A',
        gates: const ['提示词门'],
        issues: [issue(GateCodes.sceneNotEmpty)],
        projectId: projectId,
      );
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.assets,
        subjectLabel: '体检 B',
        gates: const ['提示词门'],
        issues: [issue(GateCodes.propHasHand)],
        projectId: otherProjectId,
      );
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.characters,
        subjectLabel: '体检 C',
        gates: const ['角色门'],
        issues: [issue(GateCodes.tierMissing)],
      );

      expect((await db.gateLogDao.hitsByGate(projectId: projectId)).keys, {
        GateCodes.sceneNotEmpty,
      });
      expect(await db.gateLogDao.countRuns(projectId: projectId), 1);
      expect(await db.gateLogDao.countRuns(), 3);
    });

    test('all 按时间倒序返回', () async {
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.script,
        subjectLabel: '先写的一条',
        gates: const ['台词门'],
        issues: [issue(GateCodes.lineTooLong)],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.script,
        subjectLabel: '后写的一条',
        gates: const ['台词门'],
        issues: [issue(GateCodes.speakerUnknown)],
      );

      final rows = await db.gateLogDao.all();
      expect(rows, hasLength(2));
      expect(rows.first.subjectLabel, '后写的一条');
    });
  });

  group('级联清理', () {
    test('deleteByProject 只删本项目记录，跨项目行保留', () async {
      final otherProjectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '另一个项目'),
      );
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.assets,
        subjectLabel: '体检 A',
        gates: const ['提示词门'],
        issues: [issue(GateCodes.sceneNotEmpty)],
        projectId: projectId,
      );
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.assets,
        subjectLabel: '体检 B',
        gates: const ['提示词门'],
        issues: [issue(GateCodes.propHasHand)],
        projectId: otherProjectId,
      );
      await db.gateLogDao.recordValidation(
        subjectType: GateSubjects.characters,
        subjectLabel: '体检 C',
        gates: const ['角色门'],
        issues: [issue(GateCodes.tierMissing)],
      );

      await db.gateLogDao.deleteByProject(projectId);

      final rows = await db.gateLogDao.all();
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.projectId).toSet(), {otherProjectId, null});
    });
  });

  group('GateCodes 登记表', () {
    test('all 无重复', () {
      expect(GateCodes.all.length, GateCodes.all.toSet().length);
      expect(GateCodes.all, isNotEmpty);
    });

    test('all 与常量一一对应，新增常量必须同步进 all', () {
      const declared = [
        GateCodes.overLimit,
        GateCodes.underLimit,
        GateCodes.dialogueOverflow,
        GateCodes.totalMismatch,
        GateCodes.tooFewSegments,
        GateCodes.batchTooLarge,
        GateCodes.lineTooLong,
        GateCodes.totalOverBudget,
        GateCodes.totalUnderBudget,
        GateCodes.hasAction,
        GateCodes.actionProse,
        GateCodes.speakerUnknown,
        GateCodes.crowdCheck,
        GateCodes.segmentSeq,
        GateCodes.frameEmpty,
        GateCodes.phraseMissing,
        GateCodes.videoNoNames,
        GateCodes.costumeOrphan,
        GateCodes.costumeDuplicate,
        GateCodes.costumeUnknown,
        GateCodes.promptSimilar,
        GateCodes.anchorCount,
        GateCodes.lightingMissing,
        GateCodes.propStates,
        GateCodes.propScale,
        GateCodes.propWhiteBg,
        GateCodes.sceneNotEmpty,
        GateCodes.propHasHand,
        GateCodes.sceneNamedCharacter,
        GateCodes.styleConflict,
        GateCodes.coverage,
        GateCodes.tierMissing,
        GateCodes.tierCap,
        GateCodes.evidenceUnverified,
        GateCodes.relationSelf,
        GateCodes.relationOrphan,
      ];
      expect(GateCodes.all, declared);
    });

    test('未登记的门码在构造 GateIssue 时抛 ArgumentError', () {
      expect(
        () => GateIssue(
          code: 'not_registered',
          severity: GateSeverity.warn,
          locator: '-',
          message: 'x',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message.toString(),
          'message',
          contains('not_registered'),
        )),
      );
    });
  });

  group('GateIssue', () {
    test('noteLine 给确认框用的一行紧凑文案', () {
      expect(
        issue(
          GateCodes.sceneNotEmpty,
          severity: GateSeverity.error,
          locator: '金銮殿',
          message: '无空景标记',
        ).noteLine,
        '[error] 金銮殿 无空景标记',
      );
      expect(
        issue(GateCodes.anchorCount, locator: '主角', message: '锚点 2 条').noteLine,
        '[warn] 主角 锚点 2 条',
      );
    });

    test('isError 区分两级严重度', () {
      expect(issue(GateCodes.sceneNotEmpty, severity: GateSeverity.error).isError, isTrue);
      expect(issue(GateCodes.anchorCount).isError, isFalse);
    });
  });
}
