import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/storage_keys.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage() : _storage = const FlutterSecureStorage();

  Future<void> setTokens(String access, String refresh) async {
    await _storage.write(key: StorageKeys.accessToken, value: access);
    await _storage.write(key: StorageKeys.refreshToken, value: refresh);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}
