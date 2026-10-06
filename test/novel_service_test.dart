import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/novel_agents.dart';
import 'package:newmove/features/novel/novel_models.dart';
import 'package:newmove/features/novel/novel_service.dart';
import 'package:newmove/features/novel/truth_file_kinds.dart';

void main() {
  late AppDatabase db;
  late int bookId;
  late NovelService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = NovelService(
      novelDao: db.novelDao,
      truthDao: db.truthFileDao,
      revisionDao: db.chapterRevisionDao,
      agents: NovelAgents(
        adapter: LlmProviderAdapter(),
        resolver: PromptResolver(db.promptOverrideDao),
      ),
      attemptDao: db.generationAttemptDao,
    );
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书',
        premise: const Value('少年在末世觉醒治愈能力'),
        world: const Value('病毒爆发后的废土'),
        styleGuide: const Value('冷峻克制'),
        outline: const Value('## 大纲\n第 1 章：觉醒'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('buildWritePrompt 注入静态设定与 TruthFile 文本', () async {
    final store = service.storeFor(bookId);
    await store.write(TruthFileKind.characterMatrix, {
      'characters': [
        {'name': '主角', 'role': '主角'},
      ],
    });

    final prompt = await service.buildWritePrompt(
      bookId: bookId,
      chapterNumber: 1,
      targetWords: 2000,
    );

    expect(prompt, contains('少年在末世觉醒治愈能力'));
    expect(prompt, contains('病毒爆发后的废土'));
    expect(prompt, contains('冷峻克制'));
    expect(prompt, contains('第 1 章：觉醒'));
    expect(prompt, contains('主角'));
    expect(prompt, contains('第 1 章'));
    expect(prompt, contains('2000'));
  });

  test('buildWritePrompt 在续写时附带已有正文', () async {
    final prompt = await service.buildWritePrompt(
      bookId: bookId,
      chapterNumber: 2,
      targetWords: 1500,
      existingContent: '他推开了门。',
    );

    expect(prompt, contains('他推开了门。'));
    expect(prompt, contains('从已有正文结尾继续'));
  });

  Future<int> insertChapter({
    required int seq,
    String? content,
    String status = '草稿',
  }) {
    return db.novelDao.insertChapter(
      ChaptersCompanion.insert(
        bookId: bookId,
        seq: seq,
        title: '第 $seq 章',
        content: Value(content),
        status: Value(status),
      ),
    );
  }

  group('上一章结尾接续（未定稿兜底）', () {
    test('按 seq 取上一章，取不到返回 null', () async {
      expect(await service.previousChapter(bookId, 1), isNull);

      await insertChapter(seq: 1, content: '他站在雨里。');
      await insertChapter(seq: 3, content: '第二天他进城了。');

      expect(await service.previousChapter(bookId, 1), isNull);
      expect((await service.previousChapter(bookId, 2))?.seq, 1);
      expect((await service.previousChapter(bookId, 4))?.seq, 3);
      expect((await service.previousChapter(bookId, 4))?.tail, '第二天他进城了。');
    });

    test('上一章无正文时 tail 为空串', () async {
      await insertChapter(seq: 1);
      final prev = await service.previousChapter(bookId, 2);
      expect(prev, isNotNull);
      expect(prev!.tail, '');
    });

    test('尾段超长按码元截断，切点落在代理对中时整体回退', () async {
      // 1199 个 BMP 字符 + 1 个 emoji（2 码元）= 1201 码元，
      // 原始切点 1 正好落在 emoji 的高位/低位代理之间。
      final content = '字' * 1199 + '\u{1F600}';
      expect(content.codeUnits.length, 1201);

      await insertChapter(seq: 1, content: content);
      final prev = await service.previousChapter(bookId, 2);
      final tail = prev!.tail;

      expect(tail.codeUnits.length, NovelService.previousTailChars);
      expect(tail, startsWith('字'));
      expect(tail, endsWith('\u{1F600}'));
    });

    test('空写时注入上一章结尾，续写时不注入', () async {
      await insertChapter(seq: 1, content: '雨停了，他把伞收了起来。');

      final fresh = await service.buildWritePrompt(
        bookId: bookId,
        chapterNumber: 2,
        targetWords: 2000,
      );
      expect(fresh, contains('第 1 章结尾'));
      expect(fresh, contains('雨停了，他把伞收了起来。'));

      final resuming = await service.buildWritePrompt(
        bookId: bookId,
        chapterNumber: 2,
        targetWords: 2000,
        existingContent: '他推开了门。',
      );
      expect(resuming, isNot(contains('第 1 章结尾')));
      expect(resuming, contains('他推开了门。'));
    });

    test('定稿的上一章同时有前情摘要与结尾片段', () async {
      await insertChapter(seq: 1, content: '他站在雨里。', status: '定稿');
      await service.storeFor(bookId).write(TruthFileKind.chapterSummaries, {
        'rows': [
          {'chapter': 1, 'title': '第 1 章', 'events': '觉醒', 'foreshadowing': '黑玉令'},
        ],
      });

      final prompt = await service.buildWritePrompt(
        bookId: bookId,
        chapterNumber: 2,
        targetWords: 2000,
      );
      expect(prompt, contains('觉醒'));
      expect(prompt, contains('他站在雨里。'));
    });
  });

  test('buildReviewPrompt 注入正文与状态', () async {
    final store = service.storeFor(bookId);
    await store.write(TruthFileKind.hooks, {
      'hooks': [
        {'id': 'h1', 'desc': '黑玉令'},
      ],
    });

    final prompt = await service.buildReviewPrompt(
      bookId: bookId,
      content: '主角拔出了刀。',
    );

    expect(prompt, contains('主角拔出了刀。'));
    expect(prompt, contains('黑玉令'));
    expect(prompt, contains('问题清单'));
  });

  group('ReviewIssue.verifyQuotes 证据引用本地裁切', () {
    final content = '第一行文字。\n第二行是主角的对话。\n第三行推进情节。';

    ReviewIssue issue({String? code, String quote = ''}) => ReviewIssue(
      type: ReviewIssueType.ooc,
      location: '第1段',
      problem: '问题',
      evidence: '依据',
      impact: '影响',
      fix: '修复',
      scope: 'local',
      code: code ?? '',
      quote: quote,
    );

    test('原文精确命中则记录偏移与段落号', () {
      final issues = ReviewIssue.verifyQuotes([
        issue(code: 'OOC-01', quote: '第二行是主角的对话。'),
      ], content);

      expect(issues, hasLength(1));
      expect(issues.single.quoteVerified, isTrue);
      expect(issues.single.quoteOffset, content.indexOf('第二行是主角的对话。'));
      expect(issues.single.paragraphIndex, 1);
    });

    test('忽略空白后仍可命中', () {
      final issues = ReviewIssue.verifyQuotes([
        issue(code: 'STYLE-01', quote: '第二行是主角的\n对话。'),
      ], content);

      expect(issues.single.quoteVerified, isTrue);
      expect(issues.single.quoteOffset, greaterThanOrEqualTo(0));
    });

    test('伪造引用不被验证且原条目保留', () {
      final issues = ReviewIssue.verifyQuotes([
        issue(code: 'HOOK-01', quote: '文中根本没有这句台词'),
      ], content);

      expect(issues, hasLength(1));
      expect(issues.single.quoteVerified, isFalse);
      expect(issues.single.quoteOffset, isNull);
      expect(issues.single.paragraphIndex, isNull);
    });

    test('空引用与过短引用不验证', () {
      final issues = ReviewIssue.verifyQuotes([
        issue(quote: ''),
        issue(quote: '第'),
      ], content);

      expect(issues.every((item) => !item.quoteVerified), isTrue);
    });

    test('引文末尾被改写时按前缀命中', () {
      final issues = ReviewIssue.verifyQuotes([
        issue(quote: '第一行文字，然后发生了别的事情。'),
      ], content);

      expect(issues.single.quoteVerified, isTrue);
      expect(issues.single.quoteOffset, 0);
    });
  });
}
