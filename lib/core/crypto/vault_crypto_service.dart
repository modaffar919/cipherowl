import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cipherowl/src/rust/frb_generated.dart/api.dart';

/// Manages field-level AES-256-GCM encryption for vault items.
///
/// Architecture:
/// - Stores a random 32-byte key in flutter_secure_storage (hex-encoded).
/// - `apiEncrypt` / `apiDecrypt` are Rust FFI calls (sync, microseconds).
/// - Phase 2 (EPIC-2): Allow re-keying from Argon2id-derived master key.
///
/// Usage:
/// ```dart
/// final svc = VaultCryptoService();
/// final blob = await svc.encrypt('secret123');        // → Uint8List
/// final text = await svc.decrypt(blob);               // → 'secret123'
/// ```
class VaultCryptoService {
  static const _keyStorageKey = 'cipherowl_vault_key_v1';

  final FlutterSecureStorage _storage;

  // Cached in-memory once loaded
  Uint8List? _key;

  VaultCryptoService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Encrypt a UTF-8 [plaintext] string. Returns `[nonce(12) || ciphertext+tag]`.
  Future<Uint8List> encrypt(String plaintext) async {
    final key = await _loadKey();
    return apiEncrypt(
      plaintext: utf8.encode(plaintext),
      key: key,
    );
  }

  /// Decrypt a blob produced by [encrypt]. Returns the original UTF-8 string.
  Future<String> decrypt(Uint8List ciphertext) async {
    final key = await _loadKey();
    final bytes = apiDecrypt(ciphertextWithNonce: ciphertext, key: key);
    return utf8.decode(bytes);
  }

  /// Encrypt raw bytes (e.g., TOTP secret, notes blob).
  Future<Uint8List> encryptBytes(List<int> plaintext) async {
    final key = await _loadKey();
    return apiEncrypt(plaintext: plaintext, key: key);
  }

  /// Decrypt to raw bytes.
  Future<Uint8List> decryptBytes(Uint8List ciphertext) async {
    final key = await _loadKey();
    return apiDecrypt(ciphertextWithNonce: ciphertext, key: key);
  }

  /// Replace the current key with [hexKey] (64 hex chars = 32 bytes).
  /// Called during EPIC-2 Phase 2 to bind vault key to master password.
  Future<void> rekeyFromDerivedKey(String hexKey) async {
    if (hexKey.length != 64) {
      throw ArgumentError('Expected 64-char hex key, got ${hexKey.length}');
    }
    _key = _hexToBytes(hexKey);
    await _storage.write(key: _keyStorageKey, value: hexKey);
  }

  /// Clear the key from memory and storage (logout / factory reset).
  Future<void> clearKey() async {
    _key = null;
    await _storage.delete(key: _keyStorageKey);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<Uint8List> _loadKey() async {
    if (_key != null) return _key!;

    final stored = await _storage.read(key: _keyStorageKey);
    if (stored != null && stored.isNotEmpty) {
      _key = _hexToBytes(stored);
    } else {
      // First launch: generate via Rust CSPRNG
      _key = apiGenerateKey();
      await _storage.write(key: _keyStorageKey, value: _bytesToHex(_key!));
    }
    return _key!;
  }

  static String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
