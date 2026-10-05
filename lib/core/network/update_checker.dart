import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dio_factory.dart';

/// 检查结果：有更新时附下载链接。
class UpdateCheck {
  const UpdateCheck({
    required this.latestVersion,
    required this.hasUpdate,
    this.releaseUrl,
    this.releaseNotes,
  });

  final String latestVersion;
  final bool hasUpdate;
  final String? releaseUrl;
  final String? releaseNotes;
}

/// GitHub Releases 版本检查（借鉴 Toonflow 桌面 updateServer，安卓走 GH Releases）。
class UpdateChecker {
  UpdateChecker({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  static const _defaultOwner = 'xfygl11';
  static const _defaultRepo = 'newmove';

  /// 拉取最新 release tag，与本地版本比较（仅 major.minor.patch 语义）。
  Future<UpdateCheck> checkLatest({
    String owner = _defaultOwner,
    String repo = _defaultRepo,
  }) async {
    final local = await PackageInfo.fromPlatform();
    final response = await _dio.get(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
      options: Options(
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw StateError('GitHub 返回格式异常');
    }
    final tag = (body['tag_name'] as String?)?.replaceFirst(RegExp('^v'), '');
    if (tag == null || tag.isEmpty) {
      throw StateError('未解析到版本');
    }
    final hasUpdate = _isNewer(tag, local.version);
    return UpdateCheck(
      latestVersion: tag,
      hasUpdate: hasUpdate,
      releaseUrl: body['html_url']?.toString(),
      releaseNotes: body['body']?.toString(),
    );
  }

  bool _isNewer(String remote, String local) {
    final a = _parseVersion(remote);
    final b = _parseVersion(local);
    if (a == null || b == null) return false;
    for (var i = 0; i < 3; i++) {
      if (a[i] > b[i]) return true;
      if (a[i] < b[i]) return false;
    }
    return false;
  }

  /// 解析 `major.minor.patch` 前三段；解析失败返回 null。
  List<int>? _parseVersion(String raw) {
    final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(raw.trim());
    if (m == null) return null;
    return [
      int.tryParse(m.group(1)!) ?? 0,
      int.tryParse(m.group(2)!) ?? 0,
      int.tryParse(m.group(3)!) ?? 0,
    ];
  }
}
