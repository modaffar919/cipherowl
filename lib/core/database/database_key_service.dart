import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the SQLCipher database encryption key.
///
/// Architecture:
/// - Phase 1 (current): Random 32-byte key stored encrypted in flutter_secure_storage.
/// - Phase 2 (EPIC-2): Key derived from master password via Argon2id in Rust core.
///
/// The key is stored as a hex string in secure storage under [_storageKey].
class DatabaseKeyService {
  static const _storageKey = 'cipherowl_db_key_v1';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  /// Returns the SQLCipher hex key, creating one if this is first launch.
  static Future<String> getDatabaseKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // First launch: generate a cryptographically random 32-byte key
    final key = _generateHexKey(32);
    await _storage.write(key: _storageKey, value: key);
    return key;
  }

  /// Re-keys the database with an Argon2id-derived key from the master password.
  /// Called by AuthBloc after successful setup / login (EPIC-2 hook).
  static Future<void> rekeySeedFromMasterPassword(String derivedHexKey) async {
    // Validate it looks like a 64-char hex key (32 bytes)
    if (derivedHexKey.length != 64) {
      throw ArgumentError('Expected 64-char hex key, got ${derivedHexKey.length}');
    }
    await _storage.write(key: _storageKey, value: derivedHexKey);
  }

  /// Removes the stored key — clears on logout / factory reset.
  static Future<void> clearKey() async {
    await _storage.delete(key: _storageKey);
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  static String _generateHexKey(int bytes) {
    final rng = Random.secure();
    final data = Uint8List.fromList(
      List<int>.generate(bytes, (_) => rng.nextInt(256)),
    );
    return data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
