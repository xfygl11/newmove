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
import 'novel_setup_catalog.dart';
import 'novel_setup_draft.dart';
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
    String workType = NovelSetupCatalog.defaultWorkForm,
    String brief = '',
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
        bookId: bookId,
        brief: brief,
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

      // 初始化角色矩阵 TruthFile：先读同一行取 revision 再带锁写入，
      // 与其他 TruthFile 写入口一致，避免并发固化时静默覆盖。
      final store = storeFor(bookId);
      final matrixRow = await store.readRow(TruthFileKind.characterMatrix);
      await store.write(
        TruthFileKind.characterMatrix,
        {'characters': [for (final c in result.characters) c.toJson()]},
        expectedRevision: matrixRow?.revision,
      );

      await _finish(attempt, AttemptStatuses.succeeded);
      return result;
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
  }

  /// 创作前「AI 帮写」单个基础设置字段。
  ///
  /// 此时作品行可能还没落库（[bookId] 为 null），台账照常登记，
  /// 项目归属缺失属预期——创作前没有可归属的项目。
  Future<String> generateSetupField({
    required SetupField field,
    required String brief,
    required ActiveLlm llm,
    int? bookId,
  }) async {
    final params = _paramsOf(llm);
    final attempt = await _start(
      subjectType: AttemptSubjects.novelPlan,
      subjectLabel: '基础设置 · ${field.label}',
      prompt: 'field=${field.label}; $brief',
      params: params,
      bookId: bookId,
    );
    try {
      final text = await agents.generateSetupField(
        field: field,
        brief: brief,
        llm: llm,
        bookId: bookId,
      );
      await _finish(attempt, AttemptStatuses.succeeded);
      return text;
    } catch (e) {
      await _finish(attempt, AttemptStatuses.failed, error: e.toString());
      rethrow;
    }
  }

  /// 基础设置里最多带入上下文的已选作品类型数，超出只影响提示词体积。
  static const int maxContextWorkGenres = 10;

  /// 基础设置里最多带入上下文的标签数。
  static const int maxContextTags = 5;

  /// 作品基调上下文：核心受众 / 作品类型 / 人设标签 / 背景标签 / 章节规划。
  ///
  /// 只输出非空项，旧数据（schema v12 及以前）没有这些列时返回空串，
  /// 提示词与升级前完全一致。列为 JSON 文本（类型是数组、标签是对象），
  /// 先解码再取值，解码失败按空处理。
  static String genreContext(NovelBook? book) {
    if (book == null) return '';
    final tags = jsonMap(book.tags != null && book.tags!.trim().isNotEmpty
        ? _decoded(book.tags)
        : null);
    final workGenres = [
      for (final g in jsonList(book.workGenre != null
          ? _decoded(book.workGenre)
          : null))
        g.toString(),
    ].take(maxContextWorkGenres).toList();
    final personas = [
      for (final t in jsonList(tags['personas'])) t.toString(),
    ].take(maxContextTags).toList();
    final backgrounds = [
      for (final t in jsonList(tags['backgrounds'])) t.toString(),
    ].take(maxContextTags).toList();
    final rows = <String>[
      if (book.workType.trim() != NovelSetupCatalog.defaultWorkForm)
        '【作品形式】${book.workType.trim()}',
      if ((book.audience ?? '').trim().isNotEmpty)
        '【核心受众】${book.audience!.trim()}',
      if (workGenres.isNotEmpty) '【作品类型】${workGenres.join(' / ')}',
      if (personas.isNotEmpty) '【人设标签】${personas.join('、')}',
      if (backgrounds.isNotEmpty) '【背景标签】${backgrounds.join('、')}',
      if (book.volumeCount > 0 && book.chaptersPerVolume > 0)
        '【章节规划】共 ${book.volumeCount} 卷、每卷 ${book.chaptersPerVolume} 章，'
            '预计 ${book.volumeCount * book.chaptersPerVolume} 章',
    ];
    return rows.isEmpty ? '' : '${rows.join('\n')}\n';
  }

  /// 解码作品行里的 JSON 文本列；空串与非法 JSON 视为无数据。
  static Object? _decoded(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  // ---- 章节写作（T1.3） ----

  /// 上一章结尾片段默认字数。
  ///
  /// 上一章未定稿时 TruthFile 里没有它，不注入这段 Writer 就完全看不到
  /// 上一章写了什么，第二章必然接不上。
  static const int previousTailChars = 1200;

  /// 上一章信息，供写作上下文注入与确认框说明。
  ///
  /// 按 seq 找小于 [chapterNumber] 的最大一章，不做内容判断——
  /// 有没有正文由 [tail] 是否为空体现。
  Future<({int seq, String title, String status, String tail})?>
      previousChapter(int bookId, int chapterNumber) async {
    Chapter? prev;
    for (final c in await novelDao.listChapters(bookId)) {
      if (c.seq < chapterNumber && (prev == null || c.seq > prev.seq)) {
        prev = c;
      }
    }
    if (prev == null) return null;
    return (
      seq: prev.seq,
      title: prev.title,
      status: prev.status,
      tail: _tailOf(prev.content ?? '', previousTailChars),
    );
  }

  /// 取正文结尾片段；切点落在代理对中间时回退，避免产出无法 UTF-8 编码的串。
  static String _tailOf(String content, int chars) {
    final text = content.trim();
    if (text.isEmpty || text.length <= chars) return text;
    var start = text.length - chars;
    final code = text.codeUnitAt(start);
    if (code >= 0xDC00 && code <= 0xDFFF) start++;
    return text.substring(start);
  }

  /// 上一章结尾提示词条块，无前文返回空串。
  static String _tailBlock(
    ({int seq, String status, String tail, String title})? previous,
  ) {
    if (previous == null || previous.tail.isEmpty) return '';
    return '【第 ${previous.seq} 章结尾（续写起点，已省略前文）】\n${previous.tail}\n\n';
  }

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
      chapterPlan: chapterPlan ?? const {},
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
    final context = genreContext(book);
    final genreBlock = context.isEmpty ? '' : '【作品基调】\n$context';
    final budget = _budgetFor(llm)
        .budgetTruthFiles(texts, fixedContext: '$head$genreBlock');
    final prompt = StringBuffer()
      ..write(head)
      ..write(genreBlock)
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
    final context = genreContext(book);
    final head = StringBuffer()
      ..writeln('【故事命题】${book?.premise ?? ''}')
      ..writeln('【世界观】${book?.world ?? ''}')
      ..writeln('【风格指南】${book?.styleGuide ?? ''}')
      ..writeln('【大纲】${book?.outline ?? ''}');
    final genreBlock = context.isEmpty ? '' : '【作品基调】\n$context';

    // 续写时 Writer 手上已有本章正文，上一章结尾是噪音，不注入。
    final resuming = existingContent != null && existingContent.trim().isNotEmpty;
    final previous = resuming ? null : await previousChapter(bookId, chapterNumber);
    final tailBlock = _tailBlock(previous);

    final budget = ContextBudget(
      maxTokens: maxTokens ?? ContextBudget.defaultMaxTokens,
    ).budgetTruthFiles(
      texts,
      fixedContext: '$head$genreBlock$tailBlock',
    );

    final buf = StringBuffer();
    buf.write(head);
    buf.write(genreBlock);
    buf.write(kindBlocks(budget));
    buf.write(tailBlock);

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
    final legacyGenre = book?.genre ?? '';
    final context = genreContext(book);
    final head = StringBuffer()
      ..writeln('【正文】$content');
    if (legacyGenre.trim().isNotEmpty) {
      head.writeln('【题材】${legacyGenre.trim()}');
    }
    final genreBlock = context.isEmpty ? '' : '【作品基调】\n$context';
    final texts = await storeFor(bookId).readAllText();
    final budget = ContextBudget(
      maxTokens: maxTokens ?? ContextBudget.defaultMaxTokens,
    ).budgetTruthFiles(texts, fixedContext: '$head$genreBlock');
    final buf = StringBuffer();
    buf.write(head);
    buf.write(genreBlock);
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
