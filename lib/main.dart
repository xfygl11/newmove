import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/settings/app_settings.dart';

void main() {
  runApp(
    ProviderScope(
      child: _AppBootstrap(child: const NewmoveApp()),
    ),
  );
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
