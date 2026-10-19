import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/novel_models.dart';
import 'package:newmove/features/novel/truth_file_kinds.dart';
import 'package:newmove/features/novel/truth_file_store.dart';

void main() {
  late AppDatabase db;
  late int bookId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '测试书'),
    );
  });

  tearDown(() async => db.close());

  group('LocationDao 地点树', () {
    test('插入/查询/更新/删除', () async {
      final dao = db.locationDao;
      final rootId = await dao.insert(
        LocationsCompanion.insert(
          bookId: bookId,
          name: '王城',
          type: const Value('城市'),
        ),
      );
      await dao.insert(
        LocationsCompanion.insert(
          bookId: bookId,
          name: '王宫',
          type: const Value('建筑'),
          parentId: Value(rootId),
        ),
      );

      var all = await dao.listByBook(bookId);
      expect(all, hasLength(2));
      final root = await dao.findById(rootId);
      expect(root!.name, '王城');
      expect(all.where((l) => l.parentId == rootId), hasLength(1));

      await dao.updateById(rootId, const LocationsCompanion(name: Value('帝都')));
      final updated = await dao.findById(rootId);
      expect(updated!.name, '帝都');

      await dao.deleteById(rootId);
      all = await dao.listByBook(bookId);
      // 删根不影响子地点（软引用、无级联）。
      expect(all, hasLength(1));
      expect(all.first.parentId, rootId, reason: '子地点 parentId 悬空不自动清');
    });
  });

  group('StoryArcDao 故事弧线', () {
    test('弧线与节点 CRUD + landNode 落地', () async {
      final dao = db.storyArcDao;
      final arcId = await dao.insertArc(
        StoryArcsCompanion.insert(
          bookId: bookId,
          name: '主线',
          status: const Value('active'),
        ),
      );
      await dao.insertNode(
        ArcNodesCompanion.insert(arcId: arcId, targetSeq: 5),
      );
      await dao.insertNode(
        ArcNodesCompanion.insert(arcId: arcId, targetSeq: 6),
      );

      var nodes = await dao.listNodesByArc(arcId);
      expect(nodes, hasLength(2));
      expect(nodes.map((n) => n.chapterId).toSet(), {null});

      // 定稿第 5 章后落地：targetSeq 5 的节点标记 chapterId。
      await dao.landNode(arcId: arcId, targetSeq: 5, chapterId: 100);
      nodes = await dao.listNodesByArc(arcId);
      final landed = nodes.firstWhere((n) => n.targetSeq == 5);
      expect(landed.chapterId, 100);
      expect(nodes.firstWhere((n) => n.targetSeq == 6).chapterId, isNull);

      // 未命中的 targetSeq 不报错、不影响其它节点。
      await dao.landNode(arcId: arcId, targetSeq: 99, chapterId: 101);
      nodes = await dao.listNodesByArc(arcId);
      expect(nodes.where((n) => n.chapterId == 101), isEmpty);
    });

    test('deleteArc 级联删节点', () async {
      final dao = db.storyArcDao;
      final arcId = await dao.insertArc(
        StoryArcsCompanion.insert(bookId: bookId, name: '支线'),
      );
      await dao.insertNode(
        ArcNodesCompanion.insert(arcId: arcId, targetSeq: 1),
      );
      await dao.deleteArc(arcId);
      expect(await dao.listArcsByBook(bookId), isEmpty);
      expect(await dao.listNodesByArc(arcId), isEmpty);
    });
  });

  group('章节计划三档', () {
    test('writeChapterPlan 后 read 往返一致', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.writeChapterPlan({
        'next': '第 2 章计划',
        'near': '第 3-4 章计划',
        'far': '远期计划',
      });
      final plan = await store.readChapterPlan();
      expect(plan['next'], '第 2 章计划');
      expect(plan['near'], '第 3-4 章计划');
      expect(plan['far'], '远期计划');
    });

    test('advanceChapterPlan 滚动三档', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.writeChapterPlan({
        'next': '第 2 章计划',
        'near': '第 3 章计划',
        'far': '第 4 章计划',
      });
      await store.advanceChapterPlan();
      final plan = await store.readChapterPlan();
      expect(plan['next'], '第 3 章计划');
      expect(plan['near'], '第 4 章计划');
      expect(plan['far'], '');
    });

    test('无计划时推进不报错且三档为空', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.advanceChapterPlan();
      final plan = await store.readChapterPlan();
      expect(plan['next'], '');
      expect(plan['near'], '');
      expect(plan['far'], '');
    });
  });

  group('读者认知固化', () {
    test('applyDelta 覆盖写入 reader_knowledge 三槽位', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.applyDelta(
        const SettleDelta(
          factUpsert: [],
          factExpire: [],
          characters: [],
          resources: [],
          hookUpsert: [],
          hookResolve: [],
          chapterSummary: null,
          authorIntent: '',
          currentFocus: '',
          readerKnowledge: {
            'known': '主角能治愈',
            'waiting': '疫苗下落',
            'misconceived': '主角是医生',
          },
        ),
        1,
      );

      final content = await store.read(TruthFileKind.readerKnowledge);
      expect(content['known'], '主角能治愈');
      expect(content['waiting'], '疫苗下落');
      expect(content['misconceived'], '主角是医生');
    });

    test('readerKnowledge 空时保持现状', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.readerKnowledge, {
        'known': '已存在认知',
        'waiting': '',
        'misconceived': '',
      });
      await store.applyDelta(
        const SettleDelta(
          factUpsert: [],
          factExpire: [],
          characters: [],
          resources: [],
          hookUpsert: [],
          hookResolve: [],
          chapterSummary: null,
          authorIntent: '',
          currentFocus: '',
        ),
        1,
      );
      final content = await store.read(TruthFileKind.readerKnowledge);
      expect(content['known'], '已存在认知');
    });
  });

  group('SettleDelta 解析', () {
    test('fromJson 解析 readerKnowledge 与 arcOps', () {
      final delta = SettleDelta.fromJson({
        'factOps': {'upsert': [], 'expire': []},
        'hookOps': {'upsert': [], 'resolve': []},
        'readerKnowledge': {'known': 'k', 'waiting': 'w', 'misconceived': 'm'},
        'arcOps': [
          {'arcName': '主线', 'targetSeq': 5, 'summary': '落地'},
        ],
      });
      expect(delta.readerKnowledge['known'], 'k');
      expect(delta.arcOps, hasLength(1));
      expect(delta.arcOps.first['arcName'], '主线');
      expect(delta.arcOps.first['targetSeq'], 5);
    });

    test('fromJson 缺字段时 readerKnowledge/arcOps 为空', () {
      final delta = SettleDelta.fromJson({
        'factOps': {'upsert': [], 'expire': []},
        'hookOps': {'upsert': [], 'resolve': []},
      });
      expect(delta.readerKnowledge, isEmpty);
      expect(delta.arcOps, isEmpty);
    });
  });
}
