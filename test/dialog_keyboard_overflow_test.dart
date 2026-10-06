import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newmove/core/storage/providers.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/chapter_editor_page.dart';
import 'package:newmove/features/novel/novel_providers.dart';
import 'package:newmove/features/project/project_page.dart';
import 'package:newmove/widgets/confirm_sheet.dart';

/// 键盘压缩弹窗可用高度时的布局溢出回归测试。
///
/// Flutter 3.47 的 Dialog 把 MediaQuery.viewInsets 加到外边距上，弹窗可用高度
/// 随之变小；非滚动的多字段 Column 会直接溢出（底部黄黑斜纹水印）。
/// 覆盖三个含输入框的弹窗：确认弹窗、新建项目、每章目标字数。
const _viewSize = Size(1080, 1920);
const _ratio = 3.0;
const _insets = [0, 260, 320];

void _setupView(WidgetTester tester, int insetPx) {
  tester.view.physicalSize = _viewSize;
  tester.view.devicePixelRatio = _ratio;
  tester.view.viewInsets = FakeViewPadding(bottom: insetPx * _ratio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

/// 捕获全部构建/布局异常：binding 默认只留第一条，溢出警告会先被吞掉。
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

/// 只看布局相关的异常，忽略 timer/流订阅等与溢出无关的噪声。
List<FlutterError> _layoutErrors(List<Object> errors) =>
    errors.whereType<FlutterError>().toList();

Widget _harness(Widget home) {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      home: home,
    ),
  );
}

/// 弹窗内的 TextField 带 caret 闪烁 timer，无法 pumpAndSettle，用固定帧推进。
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump(const Duration(milliseconds: 150));
}

/// 卸载 widget 树以取消 drift 流订阅并 flush 其内部计时器。
Future<void> _unload(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

class _HarnessButton extends StatelessWidget {
  const _HarnessButton({required this.label, required this.onTap});

  final String label;
  final void Function(BuildContext) onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('基础设置')),
      body: Center(
        child: FilledButton(
          onPressed: () => onTap(context),
          child: Text(label),
        ),
      ),
    );
  }
}

Future<List<Object>> _confirmSheet(WidgetTester tester, int insetPx) async {
  _setupView(tester, insetPx);
  final home = _HarnessButton(
    label: '开始创作',
    onTap: (context) => ConfirmSheet.show(
      context,
      objectName: '作品设定',
      promptPreview: '【创意】一句话故事核心。\n请按规则产出设定 JSON。',
      params: [
        '供应商：Agnes LLM',
        '模型：agnes-2.5-flash',
        '作品形式：长篇',
        '核心受众：成人向',
        '作品类型：东方玄幻 / 热血',
        '角色信息将写入角色矩阵 TruthFile',
      ],
      title: '开始创作',
      gate: '作品创建（生成世界观 / 角色 / 大纲后进入书架）',
    ),
  );
  await tester.pumpWidget(_harness(home));
  await tester.pump();
  final errors = await _capture(() async {
    await tester.tap(find.text('开始创作').first);
    await _settle(tester);
    expect(find.text('开始创作'), findsWidgets);
    expect(
      find.text('请核对提示词、参考文件顺序与执行次数后再执行。'),
      findsOneWidget,
    );
  });
  await _unload(tester);
  return errors;
}

Future<List<Object>> _createProjectDialog(
  WidgetTester tester,
  int insetPx,
) async {
  _setupView(tester, insetPx);
  await tester.pumpWidget(_harness(const ProjectPage()));
  await tester.pump();
  final errors = await _capture(() async {
    await tester.tap(find.byTooltip('新建项目'));
    await _settle(tester);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('新建项目'),
      ),
      findsOneWidget,
    );
    expect(find.text('项目名称'), findsOneWidget);
  });
  await _unload(tester);
  return errors;
}

Widget _chapterHarness() {
  final chapter = Chapter(
    id: 1,
    bookId: 1,
    seq: 1,
    title: '第一章',
    content: '第一段正文内容。',
    wordCount: 8,
    status: '草稿',
    revision: 1,
    createdAt: DateTime(2026, 10, 4),
    updatedAt: DateTime(2026, 10, 4),
  );
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      chapterProvider(1).overrideWith(
        (ref) => Stream<Chapter?>.value(chapter),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      home: const ChapterEditorPage(chapterId: 1),
    ),
  );
}

/// 越过首个 500ms 字数定时器 tick，让底栏字数标签渲染出来。
Future<void> _warmChapter(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 550));
}

/// 章节编辑页自身：键盘把 body 压矮时底部工具栏不能溢出。
Future<List<Object>> _chapterPage(WidgetTester tester, int insetPx) async {
  _setupView(tester, insetPx);
  await tester.pumpWidget(_chapterHarness());
  final errors = await _capture(() => _warmChapter(tester));
  await _unload(tester);
  return errors;
}

Future<List<Object>> _targetWordsDialog(WidgetTester tester, int insetPx) async {
  _setupView(tester, insetPx);
  await tester.pumpWidget(_chapterHarness());
  await _warmChapter(tester);
  final errors = await _capture(() async {
    await tester.tap(find.text('8 字'));
    await _settle(tester);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('每章目标字数'),
      ),
      findsOneWidget,
    );
  });
  await _unload(tester);
  return errors;
}

void main() {
  for (final inset in _insets) {
    testWidgets('开始创作 确认弹窗 键盘 ${inset}px 不溢出', (tester) async {
      final errors = await _confirmSheet(tester, inset);
      expect(_layoutErrors(errors), isEmpty,
          reason: '布局溢出：${errors.join('\n')}');
    });
    testWidgets('新建项目 对话框 键盘 ${inset}px 不溢出', (tester) async {
      final errors = await _createProjectDialog(tester, inset);
      expect(_layoutErrors(errors), isEmpty,
          reason: '布局溢出：${errors.join('\n')}');
    });
    testWidgets('每章目标字数 对话框 键盘 ${inset}px 不溢出', (tester) async {
      final errors = await _targetWordsDialog(tester, inset);
      expect(_layoutErrors(errors), isEmpty,
          reason: '布局溢出：${errors.join('\n')}');
    });
    testWidgets('章节编辑器 键盘 ${inset}px 不溢出', (tester) async {
      final errors = await _chapterPage(tester, inset);
      expect(_layoutErrors(errors), isEmpty,
          reason: '布局溢出：${errors.join('\n')}');
    });
  }
}
