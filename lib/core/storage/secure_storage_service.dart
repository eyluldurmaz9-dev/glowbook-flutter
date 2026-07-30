import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<void> clear() {
    return _storage.deleteAll();
  }

  Future<String?> getAccessToken() {
    return read(StorageKeys.accessToken);
  }

  Future<String?> getRefreshToken() {
    return read(StorageKeys.refreshToken);
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await write(StorageKeys.accessToken, accessToken);
    if (refreshToken != null) {
      await write(StorageKeys.refreshToken, refreshToken);
    }
  }

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    String? role,
    int? customerId,
    String? employeeId,
    String? fullName,
  }) async {
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    if (role != null) {
      await write(StorageKeys.role, role);
    }
    if (customerId != null) {
      await write(StorageKeys.customerId, customerId.toString());
    }
    if (employeeId != null) {
      await write(StorageKeys.employeeId, employeeId);
    }
    if (fullName != null) {
      await write(StorageKeys.fullName, fullName);
    }
  }

  Future<String?> getRole() => read(StorageKeys.role);

  Future<int?> getCustomerId() async {
    final value = await read(StorageKeys.customerId);
    return value == null ? null : int.tryParse(value);
  }

  Future<String?> getEmployeeId() => read(StorageKeys.employeeId);

  Future<String?> getFullName() => read(StorageKeys.fullName);
}
