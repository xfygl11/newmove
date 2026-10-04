import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/settings/app_settings.dart';

void main() {
  // 全局兜底：Release 下未捕获异常会直接崩进程，这里只上报并尝试恢复。
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      details.exceptionAsString(),
      name: 'newmove-uncaught',
      error: details.exception,
      stackTrace: details.stack,
      level: 1000,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      error.toString(),
      name: 'newmove-zone-error',
      error: error,
      stackTrace: stack,
      level: 1000,
    );
    return true;
  };
  runApp(ProviderScope(child: _AppBootstrap(child: const NewmoveApp())));
}

/// 启动时初始化通用设置（shared_preferences 异步读取后注入 store）。
class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ProviderScope.containerOf 需要 Element 就绪，放 didChangeDependencies；
    // 只初始化一次。
    if (_inited) return;
    _inited = true;
    initAppSettings(ProviderScope.containerOf(context, listen: false));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
