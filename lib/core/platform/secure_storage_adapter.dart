import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform-aware secure storage.
///
/// Delegates to [FlutterSecureStorage] on all platforms:
/// - **Native** (iOS/Android/desktop): Keychain / Keystore / platform secure storage
/// - **Web**: Web Crypto API (AES-GCM) via flutter_secure_storage_web
abstract class SecureStorageAdapter {
  factory SecureStorageAdapter() => _SecureStorageImpl();

  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
  Future<Map<String, String>> readAll();
  Future<void> deleteAll();
  Future<bool> containsKey({required String key});
}

class _SecureStorageImpl implements SecureStorageAdapter {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  @override
  Future<bool> containsKey({required String key}) =>
      _storage.containsKey(key: key);
}
