import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API Key 安全存储：密钥存系统 Keystore，不落明文 DB。
///
/// 键规则：`provider_api_key_<providerId>`。
class SecureKeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _prefix = 'provider_api_key_';

  String _key(String providerId) => '$_prefix$providerId';

  Future<void> writeKey(String providerId, String apiKey) {
    return _storage.write(key: _key(providerId), value: apiKey);
  }

  Future<String?> readKey(String providerId) {
    return _storage.read(key: _key(providerId));
  }

  Future<void> deleteKey(String providerId) {
    return _storage.delete(key: _key(providerId));
  }
}
