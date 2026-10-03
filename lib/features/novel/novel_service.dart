import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../agent/active_llm.dart';
import '../../data/app_database.dart';
import '../../data/daos/chapter_revision_dao.dart';
import '../../data/daos/novel_dao.dart';
import '../../data/daos/truth_file_dao.dart';
import 'novel_agents.dart';
import 'novel_models.dart';
import 'truth_file_kinds.dart';
import 'truth_file_store.dart';

/// AI 写小说的业务编排：构建上下文、调用 Agent、落库与固化。
class NovelService {
  NovelService({
    required this.novelDao,
    required this.truthDao,
    required this.revisionDao,
    required this.agents,
  });

  final NovelDao novelDao;
  final TruthFileDao truthDao;
  final ChapterRevisionDao revisionDao;
  final NovelAgents agents;

  TruthFileStore storeFor(int bookId) =>
      TruthFileStore(dao: truthDao, bookId: bookId);

  // ---- 设定生成（T1.2） ----

  Future<SetupResult> generateSetup({
    required int bookId,
    required String idea,
    required String genre,
    required ActiveLlm llm,
  }) async {
    final result = await agents.generateSetup(
      idea: idea,
      genre: genre,
      llm: llm,
    );

    final book = await novelDao.findBook(bookId);
    if (book != null) {
      await novelDao.updateBook(
        book.copyWith(
          genre: Value(genre.isEmpty ? null : genre),
          world: Value(result.world),
          premise: Value(result.premise),
          styleGuide: Value(result.styleGuide),
          outline: Value(result.outline),
        ),
      );
    }

    // 初始化角色矩阵 TruthFile。
    final store = storeFor(bookId);
    await store.write(
      TruthFileKind.characterMatrix,
      {'characters': [for (final c in result.characters) c.toJson()]},
    );

    return result;
  }

  // ---- 章节写作（T1.3） ----

  /// 构建写作 prompt 并返回流式正文。
  Stream<String> writeChapter({
    required int bookId,
    required int chapterNumber,
    required int targetWords,
    required ActiveLlm llm,
    String? existingContent,
  }) async* {
    final prompt = await buildWritePrompt(
      bookId: bookId,
      chapterNumber: chapterNumber,
      targetWords: targetWords,
      existingContent: existingContent,
    );
    yield* agents.writeChapter(prompt: prompt, llm: llm);
  }

  Future<String> buildWritePrompt({
    required int bookId,
    required int chapterNumber,
    required int targetWords,
    String? existingContent,
  }) async {
    final book = await novelDao.findBook(bookId);
    final texts = await storeFor(bookId).readAllText();
    final outline = book?.outline ?? '';

    final buf = StringBuffer();
    buf.writeln('【故事命题】${book?.premise ?? ''}');
    buf.writeln('【世界观】${book?.world ?? ''}');
    buf.writeln('【风格指南】${book?.styleGuide ?? ''}');
    buf.writeln('【大纲】$outline');
    buf.writeln('【角色矩阵】${texts[TruthFileKind.characterMatrix] ?? '{}'}');
    buf.writeln('【世界事实】${texts[TruthFileKind.worldFacts] ?? '{}'}');
    buf.writeln('【未闭合伏笔】${texts[TruthFileKind.hooks] ?? '{}'}');
    buf.writeln('【前情摘要】${texts[TruthFileKind.chapterSummaries] ?? '{}'}');
    buf.writeln('【当前焦点】${texts[TruthFileKind.currentFocus] ?? '{}'}');
    if (existingContent != null && existingContent.isNotEmpty) {
      buf.writeln('【已有正文】$existingContent');
      buf.writeln('请从已有正文结尾继续往下写，不重复已写内容。');
    }
    buf.writeln('目标字数：$targetWords 字。请写第 $chapterNumber 章正文。');
    return buf.toString();
  }

  // ---- 审校（T1.5） ----

  Future<String> buildReviewPrompt({
    required int bookId,
    required String content,
  }) async {
    final texts = await storeFor(bookId).readAllText();
    final buf = StringBuffer();
    buf.writeln('【正文】$content');
    buf.writeln('【角色矩阵】${texts[TruthFileKind.characterMatrix] ?? '{}'}');
    buf.writeln('【世界事实】${texts[TruthFileKind.worldFacts] ?? '{}'}');
    buf.writeln('【未闭合伏笔】${texts[TruthFileKind.hooks] ?? '{}'}');
    buf.writeln('【资源状态】${texts[TruthFileKind.resources] ?? '{}'}');
    buf.writeln('请审校并输出问题清单 JSON。');
    return buf.toString();
  }

  Future<List<ReviewIssue>> reviewChapter({
    required int bookId,
    required String content,
    required ActiveLlm llm,
  }) async {
    final prompt = await buildReviewPrompt(bookId: bookId, content: content);
    return agents.review(prompt: prompt, llm: llm);
  }

  // ---- 修订（T1.5/T1.6） ----

  /// 修订章节：返回新正文，并落库（旧内容存版本快照，revision 递增）。
  Future<String> reviseChapter({
    required Chapter chapter,
    required String instruction,
    required RevisionMode mode,
    required ActiveLlm llm,
  }) async {
    final prompt = _revisePrompt(
      content: chapter.content ?? '',
      instruction: instruction,
      mode: mode,
    );
    final revised = await agents.revise(prompt: prompt, llm: llm);

    // 旧内容存入版本快照。
    await revisionDao.insert(
      ChapterRevisionsCompanion.insert(
        chapterId: chapter.id,
        revision: chapter.revision,
        content: Value(chapter.content),
      ),
    );
    await novelDao.updateChapter(
      chapter.copyWith(
        content: Value(revised),
        wordCount: revised.length,
        revision: chapter.revision + 1,
      ),
    );

    return revised;
  }

  // ---- 状态固化（T1.4/T1.6） ----

  Future<void> settleChapter({
    required int bookId,
    required Chapter chapter,
    required ActiveLlm llm,
  }) async {
    final store = storeFor(bookId);
    final texts = await store.readAllText();
    final prompt = StringBuffer()
      ..writeln('【正文】${chapter.content ?? ''}')
      ..writeln('【章节号】${chapter.seq}')
      ..writeln('【标题】${chapter.title}')
      ..writeln('【现有状态（7 类 JSON）】${jsonEncode(texts)}')
      ..writeln('请输出固化 delta JSON。');

    final delta = await agents.settle(
      prompt: prompt.toString(),
      llm: llm,
    );
    await store.applyDelta(delta, chapter.seq);
  }

  // ---- 内部辅助 ----

  String _revisePrompt({
    required String content,
    required String instruction,
    required RevisionMode mode,
  }) {
    return '【正文】$content\n【修订模式】${mode.label}\n【修订要求】$instruction\n'
        '请输出修订后的完整正文，不输出解释。';
  }
}
