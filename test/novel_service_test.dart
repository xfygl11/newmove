import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/novel_agents.dart';
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
      agents: NovelAgents(adapter: LlmProviderAdapter()),
    );
    bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: 1,
        title: '测试书',
        premise: Value('少年在末世觉醒治愈能力'),
        world: Value('病毒爆发后的废土'),
        styleGuide: Value('冷峻克制'),
        outline: Value('## 大纲\n第 1 章：觉醒'),
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
}
