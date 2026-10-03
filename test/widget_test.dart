import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/app.dart';
import 'package:newmove/core/storage/providers.dart';
import 'package:newmove/data/app_database.dart';

void main() {
  testWidgets('应用启动展示三 Tab 导航与项目页空态', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const NewmoveApp(),
      ),
    );
    // 单帧渲染，等待 StreamProvider 发出首个空列表事件。
    await tester.pump();

    expect(find.text('小说动漫工坊'), findsOneWidget);
    expect(find.text('项目'), findsOneWidget);
    expect(find.text('任务'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('还没有项目'), findsOneWidget);

    // 卸载 widget 树以取消 drift 流订阅，并 flush 其内部计时器，
    // 避免测试结束时报 pending timer（drift 建议在 widget 测试中 close）。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
