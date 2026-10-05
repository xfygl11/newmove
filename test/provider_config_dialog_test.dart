import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/storage/providers.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/provider_config/provider_config_page.dart';

const _viewSize = Size(1080, 2400);
const _ratio = 3.0;

void _setupView(WidgetTester tester, int insetPx) {
  tester.view.physicalSize = _viewSize;
  tester.view.devicePixelRatio = _ratio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.viewInsets = FakeViewPadding(bottom: insetPx * _ratio);
  addTearDown(tester.view.resetViewInsets);
}

Widget _harness() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const ProviderConfigPage(),
    ),
  );
}

Future<void> _openAgnesDialog(WidgetTester tester) async {
  await tester.pumpWidget(_harness());
  await tester.pump();

  await tester.scrollUntilVisible(
    find.text('一键添加 Agnes 预设'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('一键添加 Agnes 预设'));
  // 对话框内的 TextField 会带 caret 闪烁 timer，无法 pumpAndSettle，用固定帧推进。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  // 「添加 Agnes AI 预设」对话框含说明文字 + TextField；键盘弹出压缩可用高度时
  // 曾出现 BOTTOM OVERFLOWED BY 8.9 PIXELS 斜纹水印。
  for (final inset in const [0, 200, 320]) {
    testWidgets('Agnes 预设对话框 键盘 ${inset}px 不溢出', (tester) async {
      _setupView(tester, inset);
      await _openAgnesDialog(tester);

      expect(find.text('添加 Agnes AI 预设'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确认'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 卸载 widget 树以取消 drift 流订阅并 flush 其内部计时器。
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
  }
}
