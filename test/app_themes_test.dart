import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/settings/app_settings.dart';
import 'package:newmove/core/theme/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemeCatalog 词表不变量', () {
    test('id 唯一且非空', () {
      final ids = AppThemeCatalog.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.every((id) => id.trim().isNotEmpty), isTrue);
    });

    test('默认 id 指向 all 首项', () {
      expect(AppThemeCatalog.defaultId, AppThemeCatalog.all.first.id);
      expect(AppThemeCatalog.defaultTheme, AppThemeCatalog.all.first);
    });

    test('resolve 命中、未知与 null 回落默认', () {
      final cyber = AppThemeCatalog.resolve('cyber_purple');
      expect(cyber.id, 'cyber_purple');
      expect(AppThemeCatalog.resolve('不存在').id, AppThemeCatalog.defaultId);
      expect(AppThemeCatalog.resolve(null).id, AppThemeCatalog.defaultId);
    });

    test('contains 只认已登记 id', () {
      expect(AppThemeCatalog.contains('aurora'), isTrue);
      expect(AppThemeCatalog.contains('aurora2'), isFalse);
    });

    test('每款主题均可构建深色 ThemeData，且主色互不相同', () {
      final primaries = <int>{};
      for (final t in AppThemeCatalog.all) {
        final data = t.build();
        expect(data.useMaterial3, isTrue);
        expect(data.colorScheme.brightness, Brightness.dark);
        // 关键角色已按主题填充，不会回落种子生成的默认色。
        expect(data.colorScheme.primary, t.primary);
        expect(data.colorScheme.surface, t.surface);
        expect(data.scaffoldBackgroundColor, t.surface);
        // onPrimary 与 primary 有对比度（不相等即视为可读的粗校验）。
        expect(data.colorScheme.onPrimary, isNot(t.primary));
        expect(data.cardTheme.elevation, 0);
        expect(data.splashFactory, InkSparkle.splashFactory);
        primaries.add(t.primary.toARGB32());
      }
      expect(primaries.length, AppThemeCatalog.all.length);
    });

    test('霓虹蓝默认主题用电光青作次强调', () {
      final neon = AppThemeCatalog.defaultTheme;
      expect(neon.id, 'neon_blue');
      expect(neon.secondary, const Color(0xFF00F0FF));
      expect(neon.surface, const Color(0xFF050814));
    });
  });

  group('AppSettings 主题持久化', () {
    test('默认 themeId 为词表默认', () {
      const s = AppSettings();
      expect(s.themeId, AppThemeCatalog.defaultId);
      expect(s.themeId, AppThemeCatalog.all.first.id);
    });

    test('store 往返保留 themeId', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AppSettingsStore(prefs);

      const next = AppSettings(themeId: 'terminal_green');
      await store.save(next);

      final loaded = store.read();
      expect(loaded.themeId, 'terminal_green');
      expect(loaded.pollIntervalSec, next.pollIntervalSec);
      expect(loaded.confirmBeforeGenerate, next.confirmBeforeGenerate);
    });

    test('未写入过时读取回落默认主题', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(
        AppSettingsStore(prefs).read().themeId,
        AppThemeCatalog.defaultId,
      );
    });
  });
}
