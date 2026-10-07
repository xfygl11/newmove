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

  tearDown(() async {
    await db.close();
  });

  group('TruthFileStore 读写', () {
    test('write 后 read 往返一致', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.worldFacts, {
        'facts': [
          {'subject': '主角', 'predicate': '持有', 'object': '木剑'},
        ],
      });

      final read = await store.read(TruthFileKind.worldFacts);
      final facts = read['facts'] as List<dynamic>;
      expect(facts, hasLength(1));
      expect((facts.first as Map)['subject'], '主角');
    });

    test('重复 write 同一 kind revision 递增', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.currentFocus, {'text': 'a'});
      await store.write(TruthFileKind.currentFocus, {'text': 'b'});

      final row = await db.truthFileDao.findByKind(
        bookId,
        TruthFileKind.currentFocus,
      );
      expect(row, isNotNull);
      expect(row!.revision, 2);
    });

    test('readAllText 返回 kind -> 内容文本', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.authorIntent, {'text': '想写反转'});

      final all = await store.readAllText();
      expect(all[TruthFileKind.authorIntent], contains('反转'));
    });
  });

  group('applyDelta 固化', () {
    test('fact upsert 追加并补生效章节，expire 标记失效章节', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.worldFacts, {
        'facts': [
          {'subject': '主角', 'predicate': '持有', 'object': '旧剑'},
        ],
      });

      await store.applyDelta(
        const SettleDelta(
          factUpsert: [
            {'subject': '主角', 'predicate': '持有', 'object': '新剑'},
          ],
          factExpire: [
            {'subject': '主角', 'predicate': '持有', 'object': '旧剑'},
          ],
          characters: [],
          resources: [],
          hookUpsert: [],
          hookResolve: [],
          chapterSummary: null,
          authorIntent: '',
          currentFocus: '',
        ),
        3,
      );

      final read = await store.read(TruthFileKind.worldFacts);
      final facts = (read['facts'] as List<dynamic>).cast<Map>();
      expect(facts, hasLength(2));

      final old = facts.firstWhere((f) => f['object'] == '旧剑');
      final added = facts.firstWhere((f) => f['object'] == '新剑');
      expect(old['validUntilChapter'], 3);
      expect(added['validFromChapter'], 3);
    });

    test('character 同名合并、新名追加', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.characterMatrix, {
        'characters': [
          {'name': '阿明', 'role': '主角', 'goal': '生存'},
        ],
      });

      await store.applyDelta(
        const SettleDelta(
          factUpsert: [],
          factExpire: [],
          characters: [
            CharacterSpec(name: '阿明', role: '主角', goal: '复仇', state: '', relations: ''),
            CharacterSpec(name: '小夜', role: '配角', goal: '', state: '', relations: ''),
          ],
          resources: [],
          hookUpsert: [],
          hookResolve: [],
          chapterSummary: null,
          authorIntent: '',
          currentFocus: '',
        ),
        2,
      );

      final read = await store.read(TruthFileKind.characterMatrix);
      final chars = (read['characters'] as List<dynamic>).cast<Map>();
      expect(chars, hasLength(2));
      final aming = chars.firstWhere((c) => c['name'] == '阿明');
      expect(aming['goal'], '复仇');
    });

    test('hook resolve 置为 resolved', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.hooks, {
        'hooks': [
          {'id': 'h1', 'status': 'open', 'desc': '黑玉令'},
        ],
      });

      await store.applyDelta(
        const SettleDelta(
          factUpsert: [],
          factExpire: [],
          characters: [],
          resources: [],
          hookUpsert: [],
          hookResolve: ['h1'],
          chapterSummary: null,
          authorIntent: '',
          currentFocus: '',
        ),
        5,
      );

      final read = await store.read(TruthFileKind.hooks);
      final hooks = (read['hooks'] as List<dynamic>).cast<Map>();
      expect(hooks.first['status'], 'resolved');
    });

    test('hook upsert 状态带空格被归一化：合法转移落干净值', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.write(TruthFileKind.hooks, {
        'hooks': [
          {'id': 'h1', 'status': 'open', 'desc': '黑玉令'},
        ],
      });

      // LLM 回带空格的状态值：trim 后是合法转移 open → progressing。
      await store.applyDelta(
        const SettleDelta(
          factUpsert: [],
          factExpire: [],
          characters: [],
          resources: [],
          hookUpsert: [
            {'id': 'h1', 'status': ' progressing '},
          ],
          hookResolve: [],
          chapterSummary: null,
          authorIntent: '',
          currentFocus: '',
        ),
        5,
      );

      final read = await store.read(TruthFileKind.hooks);
      final hooks = (read['hooks'] as List<dynamic>).cast<Map>();
      expect(hooks.first['status'], 'progressing');
      // 未被拒绝，rejectedTransitions 不写入。
      expect(read.containsKey('rejectedTransitions'), isFalse);
    });

    test('hook 终态带空格不被当作 open 绕过回退约束', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      // 历史条目 status 是终态 resolved（脏值带空格）。
      await store.write(TruthFileKind.hooks, {
        'hooks': [
          {'id': 'h1', 'status': ' resolved ', 'desc': '黑玉令'},
        ],
      });

      // 终态回退到 progressing：trim 后 from=resolved 是终态，必须拒绝；
      // 未 trim 时 from 会经 containsKey 失败回落 open 而被错误放行。
      await store.applyDelta(
        const SettleDelta(
          factUpsert: [],
          factExpire: [],
          characters: [],
          resources: [],
          hookUpsert: [
            {'id': 'h1', 'status': 'progressing'},
          ],
          hookResolve: [],
          chapterSummary: null,
          authorIntent: '',
          currentFocus: '',
        ),
        5,
      );

      final read = await store.read(TruthFileKind.hooks);
      final hooks = (read['hooks'] as List<dynamic>).cast<Map>();
      // 原状态保持不变（未被非法转移覆盖）。
      expect(hooks.first['status'], ' resolved ');
      expect(read['rejectedTransitions'], isNotNull);
    });

    test('summary 按章节 upsert', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.applyDelta(
        const SettleDelta(
          factUpsert: [],
          factExpire: [],
          characters: [],
          resources: [],
          hookUpsert: [],
          hookResolve: [],
          chapterSummary: {'chapter': 1, 'summary': '初版摘要'},
          authorIntent: '伏笔主角身世',
          currentFocus: '前往北城',
        ),
        1,
      );

      final summaries = await store.read(TruthFileKind.chapterSummaries);
      final rows = (summaries['rows'] as List<dynamic>).cast<Map>();
      expect(rows.first['summary'], '初版摘要');

      final intent = await store.read(TruthFileKind.authorIntent);
      expect(intent['text'], '伏笔主角身世');
      final focus = await store.read(TruthFileKind.currentFocus);
      expect(focus['text'], '前往北城');
    });
  });

  group('relationOps 固化（T25.3）', () {
    test('追加关系行并带上章节序号，characters 为空不阻塞', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.applyDelta(
        SettleDelta.fromJson(const {
          'relationOps': [
            {
              'source': '林昭',
              'target': '苏婉',
              'description': '青梅竹马',
            },
          ],
        }),
        5,
      );

      final edges = await db.characterRelationDao.currentEdges(bookId);
      expect(edges, hasLength(1));
      expect(edges.single.source, '林昭');
      expect(edges.single.target, '苏婉');
      expect(edges.single.description, '青梅竹马');
      expect(edges.single.chapterSeq, 5);
    });

    test('同名关系二次固化追加新版本，旧版本 isCurrent 归零', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      const deltaJson = {
        'relationOps': [
          {'source': '林昭', 'target': '苏婉', 'description': '青梅'},
        ],
      };
      await store.applyDelta(SettleDelta.fromJson(deltaJson), 2);
      await store.applyDelta(
        SettleDelta.fromJson({
          'relationOps': [
            {'source': '林昭', 'target': '苏婉', 'description': '宿敌'},
          ],
        }),
        7,
      );

      final all = await db.characterRelationDao.listByBook(bookId);
      expect(all, hasLength(2));
      expect(
        (await db.characterRelationDao.currentEdges(bookId)).single.chapterSeq,
        7,
      );
    });

    test('缺 source 或 target 的关系跳过，整轮固化不回滚', () async {
      final store = TruthFileStore(dao: db.truthFileDao, bookId: bookId);
      await store.applyDelta(
        SettleDelta.fromJson(const {
          'relationOps': [
            {'target': '苏婉'},
            {'source': '林昭', 'target': ''},
            {'source': '林昭', 'target': '苏婉'},
          ],
        }),
        1,
      );

      expect(await db.characterRelationDao.countByBook(bookId), 1);
    });

    test('relationOps 缺省为空列表，存量 SettleDelta 不需要改构造', () {
      const delta = SettleDelta(
        factUpsert: [],
        factExpire: [],
        characters: [],
        resources: [],
        hookUpsert: [],
        hookResolve: [],
        chapterSummary: null,
        authorIntent: '',
        currentFocus: '',
      );
      expect(delta.relationOps, isEmpty);
    });
  });
}
