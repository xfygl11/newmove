import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/storage/providers.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/outline_editor_page.dart';

void main() {
  testWidgets('大纲编辑页保存后 outline 正确落库', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书',
        outline: const Value('第 1 章：觉醒\n主角醒来'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: OutlineEditorPage(projectId: projectId),
        ),
      ),
    );
    await tester.pump();

    // 明细输入框应显示已解析的明细。
    expect(find.text('主角醒来'), findsOneWidget);

    // 标题输入框应显示已解析的标题「觉醒」。
    expect(find.widgetWithText(TextField, '觉醒'), findsOneWidget);

    // 编辑标题与明细。
    await tester.enterText(find.widgetWithText(TextField, '觉醒'), '重生');
    await tester.enterText(find.byType(TextField).last, '主角醒来\n获得治愈能力');
    await tester.pump();

    // 点保存。
    await tester.tap(find.text('保存大纲'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 直接读 DB 验证。
    final book = await db.novelDao.findBookByProject(projectId);
    expect(book, isNotNull);
    expect(book!.outline, contains('获得治愈能力'));
    expect(book.outline, contains('第 1 章 重生'));

    // 卸载以取消 drift 流订阅。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
