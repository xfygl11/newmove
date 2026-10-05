import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../agent/active_llm.dart';
import '../../core/json_values.dart';
import '../../core/text/chapter_import.dart';
import '../../data/app_database.dart';
import '../../data/daos/chapter_revision_dao.dart';
import '../../data/daos/generation_attempt_dao.dart';
import '../../data/daos/novel_dao.dart';
import '../../data/daos/truth_file_dao.dart';
import 'novel_agents.dart';
import 'context_budget.dart';
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
    required GenerationAttemptDao attemptDao,
  }) : _attempts = AttemptRecorder(attemptDao);

  final NovelDao novelDao;
  final TruthFileDao truthDao;
  final ChapterRevisionDao revisionDao;
  final NovelAgents agents;

  /// 生成尝试台账（M18 T20.1 起必填，见 [AttemptRecorder]）。
  final AttemptRecorder _attempts;

  static String _paramsOf(ActiveLlm llm) => jsonEncode({
    'model': llm.modelId,
    'provider': llm.provider.label,
    'maxToken': llm.model.maxOutputTokens,
    'budgetTokens': llm.budgetTokens,
  });

  Future<int?> _start({
    required String subjectType,
    int? subjectId,
    required String subjectLabel,
    required String prompt,
    required String params,
    Map<String, dynamic> before = const {},
    int? bookId,
  }) {
    return _attempts.start(
      subjectType: subjectType,
      subjectId: subjectId,
      subjectLabel: subjectLabel,
      prompt: prompt,
      params: params,
      before: before,
      bookId: bookId,
    );
  }

  Future<void> _finish(
    int? id,
    String status, {
    String? error,
    int? subjectId,
  }) async {
    await _attempts.finish(
      id: id,
      status: status,
      error: error,
      subjectId: subjectId,
    );
  }

  TruthFileStore storeFor(int bookId) =>
      TruthFileStore(dao: truthDao, bookId: bookId);

  // ---- 设定生成（T1.2） ----

  Future<SetupResult> generateSetup({
    required int bookId,
    required String idea,
    required String genre,
    required ActiveLlm llm,
    String workType = '长篇',
  }) async {
    final params = _paramsOf(llm);
    final attempt = await _start(
      subjectType: AttemptSubjects.novelPlan,
      subjectId: bookId,
      subjectLabel: '设定生成',
      prompt: 'idea=$idea; genre=$genre; workType=$workType',
      params: params,
      bookId: bookId,
    );
    try {
      final result = await agents.generateSetup(
        idea: idea,
        genre: genre,
        llm: llm,
        workType: workType,
        bookId: bookId,
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
      await store.write(TruthFileKind.characterMatrix, {
        'characters': [for (final c in result.characters) c.toJson()],
      });

      await _finish(attempt, AttemptStatuses.succeeded);
      return result;
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
  }

  // ---- 章节写作（T1.3） ----

  /// 构建写作 prompt 并返回流式正文。
  ///
  /// [chapterPlan] 为 P3-13 多 Agent 协作的 Planner 产出（可选），
  /// 注入后 Writer 按规划写正文，而非自由发挥。
  Stream<String> writeChapter({
    required int bookId,
    required int chapterNumber,
    required int targetWords,
    required ActiveLlm llm,
    String? existingContent,
    Map<String, dynamic>? chapterPlan,
    int? chapterId,
  }) async* {
    final prompt = await buildWritePrompt(
      bookId: bookId,
      chapterNumber: chapterNumber,
      targetWords: targetWords,
      existingContent: existingContent,
      chapterPlan: chapterPlan,
      maxTokens: llm.budgetTokens,
    );
    final params = _paramsOf(llm);
    final attempt = await _start(
      subjectType: AttemptSubjects.novelWrite,
      subjectId: chapterId,
      subjectLabel: '第 $chapterNumber 章',
      prompt: prompt,
      params: params,
      bookId: bookId,
    );
    try {
      yield* agents.writeChapter(prompt: prompt, llm: llm, bookId: bookId);
      await _finish(attempt, AttemptStatuses.succeeded);
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
  }

  /// Planner 步骤（P3-13）：为指定章节生成写作规划。
  ///
  /// 调用 [agents.planChapter]，产出目标/关键事件/结尾变化/伏笔操作，
  /// 供后续 Writer 注入使用。
  Future<Map<String, dynamic>> planChapter({
    required int bookId,
    required int chapterNumber,
    required ActiveLlm llm,
    int? chapterId,
  }) async {
    final book = await novelDao.findBook(bookId);
    final texts = await storeFor(bookId).readAllText();
    final head = StringBuffer()
      ..writeln('【故事命题】${book?.premise ?? ''}')
      ..writeln('【世界观】${book?.world ?? ''}')
      ..writeln('【大纲】${book?.outline ?? ''}');
    final budget = _budgetFor(llm)
        .budgetTruthFiles(texts, fixedContext: head.toString());
    final prompt = StringBuffer()
      ..write(head)
      ..write(kindBlocks(budget))
      ..writeln('请为第 $chapterNumber 章输出规划 JSON。');
    final params = _paramsOf(llm);
    final attempt = await _start(
      subjectType: AttemptSubjects.novelPlan,
      subjectId: chapterId,
      subjectLabel: '第 $chapterNumber 章 规划',
      prompt: prompt.toString(),
      params: params,
      bookId: bookId,
    );
    try {
      final plan = await agents.planChapter(
        prompt: prompt.toString(),
        llm: llm,
        bookId: bookId,
      );
      await _finish(attempt, AttemptStatuses.succeeded);
      return plan;
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
  }

  Future<String> buildWritePrompt({
    required int bookId,
    required int chapterNumber,
    required int targetWords,
    String? existingContent,
    Map<String, dynamic>? chapterPlan,
    int? maxTokens,
  }) async {
    final book = await novelDao.findBook(bookId);
    final texts = await storeFor(bookId).readAllText();
    final head = StringBuffer()
      ..writeln('【故事命题】${book?.premise ?? ''}')
      ..writeln('【世界观】${book?.world ?? ''}')
      ..writeln('【风格指南】${book?.styleGuide ?? ''}')
      ..writeln('【大纲】${book?.outline ?? ''}');
    final budget = ContextBudget(
      maxTokens: maxTokens ?? ContextBudget.defaultMaxTokens,
    ).budgetTruthFiles(texts, fixedContext: head.toString());

    final buf = StringBuffer();
    buf.write(head);
    buf.write(kindBlocks(budget));

    // P3-13：Planner 产出注入，Writer 按规划写。
    if (chapterPlan != null && chapterPlan.isNotEmpty) {
      buf.writeln('');
      buf.writeln('【本章规划（Planner 产出，请严格遵循）】');
      buf.writeln('目标：${chapterPlan['chapterGoal'] ?? ''}');
      final events = jsonList(chapterPlan['keyEvents']);
      buf.writeln('关键事件：${events.join(' → ')}');
      buf.writeln('结尾变化：${chapterPlan['endingChange'] ?? ''}');
      final styleNotes = chapterPlan['styleNotes']?.toString() ?? '';
      if (styleNotes.isNotEmpty) {
        buf.writeln('文风注意：$styleNotes');
      }
    }

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
    int? maxTokens,
  }) async {
    final book = await novelDao.findBook(bookId);
    final genre = book?.genre ?? '';
    final workType = book?.workType ?? '';
    final head = StringBuffer()
      ..writeln('【正文】$content')
      ..writeln('【题材】${genre.isEmpty ? '未设定' : genre}')
      ..writeln('【作品类型】${workType.isEmpty ? '未设定' : workType}');
    final texts = await storeFor(bookId).readAllText();
    final budget = ContextBudget(
      maxTokens: maxTokens ?? ContextBudget.defaultMaxTokens,
    ).budgetTruthFiles(texts, fixedContext: head.toString());
    final buf = StringBuffer();
    buf.write(head);
    buf.write(kindBlocks(budget));
    buf.writeln('请审校并输出问题清单 JSON。');
    return buf.toString();
  }

  Future<List<ReviewIssue>> reviewChapter({
    required int bookId,
    required String content,
    required ActiveLlm llm,
    int? chapterId,
  }) async {
    final prompt = await buildReviewPrompt(
      bookId: bookId,
      content: content,
      maxTokens: llm.budgetTokens,
    );
    final params = _paramsOf(llm);
    final attempt = await _start(
      subjectType: AttemptSubjects.novelReview,
      subjectId: chapterId,
      subjectLabel: '章节审校',
      prompt: prompt,
      params: params,
      bookId: bookId,
    );
    try {
      final issues = await agents.review(prompt: prompt, llm: llm, bookId: bookId);
      await _finish(attempt, AttemptStatuses.succeeded);
      // 证据引用一律由本地正文重新裁切，不直接采信 LLM 自报的位置与引文。
      return ReviewIssue.verifyQuotes(issues, content);
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
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
    final params = _paramsOf(llm);
    final attempt = await _start(
      subjectType: AttemptSubjects.novelWrite,
      subjectId: chapter.id,
      subjectLabel: '第 ${chapter.seq} 章 修订',
      prompt: prompt,
      params: params,
      before: {'contentRevision': chapter.revision},
      bookId: chapter.bookId,
    );
    try {
      final revised = await agents.revise(
        prompt: prompt,
        llm: llm,
        bookId: chapter.bookId,
      );

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
          wordCount: ChapterImport.countWords(revised),
          revision: chapter.revision + 1,
        ),
      );

      await _finish(attempt, AttemptStatuses.succeeded);
      return revised;
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
  }

  // ---- 状态固化（T1.4/T1.6） ----

  Future<void> settleChapter({
    required int bookId,
    required Chapter chapter,
    required ActiveLlm llm,
  }) async {
    final store = storeFor(bookId);
    final texts = await store.readAllText();
    final head = StringBuffer()
      ..writeln('【正文】${chapter.content ?? ''}')
      ..writeln('【章节号】${chapter.seq}')
      ..writeln('【标题】${chapter.title}');
    // 固化需要看到现有状态才能避免重复；超预算时按分级裁剪，并在提示词里说明。
    final budget = _budgetFor(llm)
        .budgetTruthFiles(texts, fixedContext: head.toString());
    final state = <String, dynamic>{};
    for (final entry in budget.texts.entries) {
      try {
        state[entry.key] = jsonDecode(entry.value);
      } on FormatException {
        state[entry.key] = <String, dynamic>{};
      }
    }
    final prompt = StringBuffer()
      ..write(head)
      ..writeln('【现有状态（7 类 JSON）】${jsonEncode(state)}')
      ..writeln(budget.note.isEmpty ? '' : '【预算说明】${budget.note}，请勿重复合并已有条目。')
      ..writeln('请输出固化 delta JSON。');

    final params = _paramsOf(llm);
    final attempt = await _start(
      subjectType: AttemptSubjects.novelSettle,
      subjectId: chapter.id,
      subjectLabel: '第 ${chapter.seq} 章 固化',
      prompt: prompt.toString(),
      params: params,
      bookId: chapter.bookId,
    );
    try {
      final delta = await agents.settle(
        prompt: prompt.toString(),
        llm: llm,
        bookId: chapter.bookId,
      );
      await store.applyDelta(delta, chapter.seq);
      await _finish(attempt, AttemptStatuses.succeeded);
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
  }

  // ---- 内部辅助 ----

  ContextBudget _budgetFor(ActiveLlm llm) =>
      ContextBudget(maxTokens: llm.budgetTokens);

  /// TruthFile 在提示词中的中文标签（与既有措辞保持一致）。
  static const Map<String, String> _kindLabels = {
    TruthFileKind.characterMatrix: '角色矩阵',
    TruthFileKind.worldFacts: '世界事实',
    TruthFileKind.hooks: '未闭合伏笔',
    TruthFileKind.resources: '资源状态',
    TruthFileKind.chapterSummaries: '前情摘要',
    TruthFileKind.currentFocus: '当前焦点',
    TruthFileKind.authorIntent: '作者意图',
  };

  static const List<String> _kindOrder = [
    TruthFileKind.characterMatrix,
    TruthFileKind.worldFacts,
    TruthFileKind.hooks,
    TruthFileKind.resources,
    TruthFileKind.chapterSummaries,
    TruthFileKind.currentFocus,
    TruthFileKind.authorIntent,
  ];

  /// 把预算裁剪结果写成带标签的提示词条块，供各构建方法复用。
  static String kindBlocks(Budgeted budget) {
    final buf = StringBuffer();
    for (final kind in _kindOrder) {
      final v = budget.texts[kind];
      if (v == null || v.trim().isEmpty) continue;
      buf.writeln('【${_kindLabels[kind] ?? TruthFileKind.label(kind)}】$v');
    }
    if (budget.note.isNotEmpty) {
      buf.writeln('【预算说明】${budget.note}');
    }
    return buf.toString();
  }

  String _revisePrompt({
    required String content,
    required String instruction,
    required RevisionMode mode,
  }) {
    return '【正文】$content\n【修订模式】${mode.label}\n【修订要求】$instruction\n'
        '请输出修订后的完整正文，不输出解释。';
  }
}
