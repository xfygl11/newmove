import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';

/// 项目列表（DB 实时监听，更新时间倒序）。
final projectListProvider = StreamProvider<List<Project>>(
  (ref) => ref.watch(projectDaoProvider).watchAll(),
);
