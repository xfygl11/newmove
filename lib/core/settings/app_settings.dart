import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 通用设置（借鉴 Toonflow general 面板，只做本地有实效的项，docs/04 T9.3）。
///
/// 存 shared_preferences（非敏感本地配置，不进数据库、不进备份包）。
class AppSettings {
  const AppSettings({
    this.pollIntervalSec = 10,
    this.confirmBeforeGenerate = true,
  });

  /// 视频任务轮询间隔（秒）。10 / 30 / 60 三档。
  final int pollIntervalSec;

  /// 生成前是否弹确认框（关闭后点生成直接提交）。
  final bool confirmBeforeGenerate;

  AppSettings copyWith({int? pollIntervalSec, bool? confirmBeforeGenerate}) {
    return AppSettings(
      pollIntervalSec: pollIntervalSec ?? this.pollIntervalSec,
      confirmBeforeGenerate:
          confirmBeforeGenerate ?? this.confirmBeforeGenerate,
    );
  }
}

/// 设置存取：shared_preferences 读写。
class AppSettingsStore {
  AppSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kPollInterval = 'settings.pollIntervalSec';
  static const _kConfirm = 'settings.confirmBeforeGenerate';

  AppSettings read() {
    return AppSettings(
      pollIntervalSec: _prefs.getInt(_kPollInterval) ?? 10,
      confirmBeforeGenerate: _prefs.getBool(_kConfirm) ?? true,
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setInt(_kPollInterval, s.pollIntervalSec);
    await _prefs.setBool(_kConfirm, s.confirmBeforeGenerate);
  }
}

/// 设置状态：启动时 [AppSettingsLoader] 从 shared_preferences 载入，
/// 运行期改动经 [update] 持久化并同步内存态。
class AppSettingsNotifier extends Notifier<AppSettings> {
  AppSettingsStore? _store;

  @override
  AppSettings build() {
    return _store?.read() ?? const AppSettings();
  }

  /// 注入存储（应用启动时调用一次）。
  void attach(AppSettingsStore store) {
    _store = store;
    ref.notifyListeners();
  }

  /// 更新设置并异步持久化。
  Future<void> update(AppSettings next) async {
    state = next;
    await _store?.save(next);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

/// 应用启动时调用：读取 shared_preferences 并注入 store。
///
/// [container] 由 main 的 ProviderScope 提供；读取失败不阻塞启动（落回默认值）。
Future<void> initAppSettings(ProviderContainer container) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    container
        .read(appSettingsProvider.notifier)
        .attach(AppSettingsStore(prefs));
  } catch (_) {
    // shared_preferences 不可用时保持默认设置。
  }
}
