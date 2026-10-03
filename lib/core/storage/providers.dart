import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/daos/project_dao.dart';
import '../../data/daos/provider_dao.dart';
import 'secure_key_store.dart';

/// 数据库单例（应用生命周期内复用）。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final projectDaoProvider = Provider<ProjectDao>(
  (ref) => ref.watch(databaseProvider).projectDao,
);

final providerDaoProvider = Provider<ProviderDao>(
  (ref) => ref.watch(databaseProvider).providerDao,
);

final secureKeyStoreProvider = Provider<SecureKeyStore>(
  (ref) => SecureKeyStore(),
);
