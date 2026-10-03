import 'package:drift/native.dart';
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
    // 等待 StreamProvider 首个事件与首帧渲染。
    await tester.pumpAndSettle();

    expect(find.text('小说动漫工坊'), findsOneWidget);
    expect(find.text('项目'), findsOneWidget);
    expect(find.text('任务'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('还没有项目'), findsOneWidget);
  });
}
