import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform-aware secure storage.
///
/// On native platforms, delegates to [FlutterSecureStorage] (Keychain / Keystore).
/// On web, uses an in-memory map (session-scoped, cleared on page refresh).
///
/// Production web builds should integrate Web Crypto API + IndexedDB
/// for persistent encrypted storage.
abstract class SecureStorageAdapter {
  factory SecureStorageAdapter() {
    if (kIsWeb) return _WebSecureStorage();
    return _NativeSecureStorage();
  }

  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
  Future<Map<String, String>> readAll();
  Future<void> deleteAll();
  Future<bool> containsKey({required String key});
}

class _NativeSecureStorage implements SecureStorageAdapter {
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

/// In-memory fallback for web. Data is lost on page refresh.
class _WebSecureStorage implements SecureStorageAdapter {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> write({required String key, required String value}) async =>
      _store[key] = value;

  @override
  Future<void> delete({required String key}) async => _store.remove(key);

  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_store);

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  Future<bool> containsKey({required String key}) async =>
      _store.containsKey(key);
}
