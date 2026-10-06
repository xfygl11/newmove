import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show
        FlutterQuillLocalizations,
        QuillController,
        QuillEditor,
        QuillSimpleToolbar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/storage/providers.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/chapter_editor_page.dart';
import 'package:newmove/features/novel/novel_providers.dart';

Chapter _chapter({String? content}) => Chapter(
  id: 1,
  bookId: 1,
  seq: 1,
  title: '第一章',
  content: content ?? '第一段正文内容。',
  wordCount: 8,
  status: '草稿',
  revision: 1,
  createdAt: DateTime(2026, 10, 4),
  updatedAt: DateTime(2026, 10, 4),
);

/// 与 lib/app.dart 的 MaterialApp 配置对齐的测试外壳。
Widget _harness(Chapter chapter) {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      chapterProvider(1).overrideWith((ref) => Stream<Chapter?>.value(chapter)),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      home: const ChapterEditorPage(chapterId: 1),
    ),
  );
}

/// 测试中捕获全部构建/布局异常（binding 默认只留第一条）。
Future<List<Object>> _capture(Future<void> Function() body) async {
  final caught = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => caught.add(details.exception);
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return caught;
}

Future<void> _showEditor(WidgetTester tester, {int keyboardInset = 0}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.viewInsets = FakeViewPadding(
    bottom: keyboardInset.toDouble() * tester.view.devicePixelRatio,
  );
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(_harness(_chapter()));
  await tester.pump();
  // 单行工具栏走 QuillToolbarArrowIndicatedButtonList，其 initState 里
  // `Timer.run(_handleScroll)` 的零时长 timer 只在 elapse 后触发；无参 pump
  // 仅 flush 微任务，会让 timer 挂到测试结束触发 pending timer 断言。
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  // 无结尾换行的正文（LLM 常返回）曾触发 flutter_quill 的
  // endsWith('\n') 断言，这里保证编辑器仍可正常构建。
  testWidgets('章节编辑器 可渲染无结尾换行的正文', (tester) async {
    await _showEditor(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(QuillEditor), findsOneWidget);
  });

  // 键盘弹出压缩可用高度时，工具栏 + 编辑器 + 底部操作栏不应纵向溢出。
  for (final inset in const [0, 260, 320, 380]) {
    testWidgets('章节编辑器 键盘 ${inset}px 无溢出', (tester) async {
      await _showEditor(tester, keyboardInset: inset);
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  // 反例：lib/app.dart 必须注册 FlutterQuillLocalizations delegate。
  // 缺失时 QuillSimpleToolbar 的 undo/redo 按钮 tooltip 读取 context.loc 直接中断构建。
  testWidgets('QuillSimpleToolbar 需要 FlutterQuillLocalizations delegate', (
    tester,
  ) async {
    final controller = QuillController.basic();
    addTearDown(controller.dispose);

    final errors = await _capture(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuillSimpleToolbar(controller: controller)),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    });
    tester.takeException();

    expect(
      errors,
      contains(
        predicate(
          (e) => e.toString().contains(
            'FlutterQuillLocalizations instance is required',
          ),
        ),
      ),
    );
    expect(find.byType(QuillSimpleToolbar), findsNothing);
  });
}
