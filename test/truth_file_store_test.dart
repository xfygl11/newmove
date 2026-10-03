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
}
