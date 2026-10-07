import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/storage/providers.dart';
import 'package:newmove/core/storage/secure_key_store.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/provider_config/provider_config_page.dart';

class _FakeKeyStore implements SecureKeyStore {
  final written = <String, String>{};
  @override
  Future<void> deleteKey(String providerId) async => written.remove(providerId);
  @override
  Future<String?> readKey(String providerId) async => written[providerId];
  @override
  Future<void> writeKey(String providerId, String apiKey) async {
    written[providerId] = apiKey;
  }
}

Widget _harness() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      secureKeyStoreProvider.overrideWithValue(_FakeKeyStore()),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const ProviderConfigPage(),
    ),
  );
}

void main() {
  // 回归：Agnes 预设对话框曾在「输入 Key 点确认」后，controller 在退出动画
  // 结束前被 dispose，引发 `TextEditingController used after being disposed`
  // 与 `_dependents.isEmpty` 断言（framework.dart:6281）红屏。
  testWidgets('Agnes 预设：输入 Key 点击确认不抛断言', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('一键添加 Agnes 预设'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('一键添加 Agnes 预设'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));

    await tester.enterText(find.byType(TextField), 'sk-test-123');
    await tester.tap(find.text('确认'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);

    // 卸载 widget 树取消 drift 流订阅并 flush TextField caret 闪烁计时器。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
