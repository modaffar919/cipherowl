import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cipherowl/src/rust/frb_generated.dart/api.dart';

/// Service for BIP39 12-word recovery key management.
///
/// When a user sets up the app, we:
///   1. Generate a 12-word BIP39 mnemonic (128-bit entropy).
///   2. Derive a 32-byte AES-256 recovery key from the mnemonic using
///      PBKDF2-HMAC-SHA512 (600 K iterations — matches the app KDF).
///   3. Store the recovery key encrypted with the vault key (delegated to caller).
///   4. Store a SHA-based verifier so we can confirm correct entry later.
///
/// The mnemonic is NEVER persisted — only shown once for the user to record.
class RecoveryKeyService {
  static const _verifierStorageKey = 'recovery_verifier';
  static const _kdfSalt = 'cipherowl-recovery-v1';

  final FlutterSecureStorage _storage;

  RecoveryKeyService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── Generation ─────────────────────────────────────────────────────────────

  /// Generate a fresh 12-word BIP39 mnemonic.
  ///
  /// The mnemonic is NOT stored — the caller must display it to the user and
  /// ensure they write it down before calling [deriveKey].
  String generateMnemonic() {
    return bip39.generateMnemonic(strength: 128); // 128 bits → 12 words
  }

  /// Derive a 32-byte recovery key from [mnemonic] using PBKDF2-SHA512.
  ///
  /// This is deterministic: the same mnemonic always produces the same key.
  /// Throws if [mnemonic] is not a valid BIP39 phrase.
  Future<Uint8List> deriveKey(String mnemonic) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw ArgumentError('عبارة الاسترداد غير صالحة — تأكد من الكلمات الـ 12');
    }
    final password = utf8.encode(mnemonic.trim().toLowerCase());
    final salt = utf8.encode(_kdfSalt);
    return apiDeriveKeyPbkdf2(password: password, salt: salt);
  }

  // ── Verifier (one-way confirmation) ───────────────────────────────────────

  /// Persist a verifier so the user can later confirm the mnemonic is correct
  /// without storing the key itself.
  ///
  /// The verifier is: the first 8 bytes of the derived key, base64-encoded.
  /// This is enough for confirmation without exposing the full key.
  Future<void> saveVerifier(Uint8List derivedKey) async {
    final verifier = base64.encode(derivedKey.sublist(0, 8));
    await _storage.write(key: _verifierStorageKey, value: verifier);
  }

  /// Returns `true` if [mnemonic] produces a key matching the saved verifier.
  Future<bool> verifyMnemonic(String mnemonic) async {
    final stored = await _storage.read(key: _verifierStorageKey);
    if (stored == null) return false;
    try {
      final derived = await deriveKey(mnemonic);
      final candidate = base64.encode(derived.sublist(0, 8));
      return candidate == stored;
    } catch (_) {
      return false;
    }
  }

  /// Returns `true` if a recovery key has been set up on this device.
  Future<bool> get isSetUp async {
    final v = await _storage.read(key: _verifierStorageKey);
    return v != null;
  }

  /// Clear the verifier (e.g. on vault wipe).
  Future<void> clear() => _storage.delete(key: _verifierStorageKey);

  // ── Mnemonic helpers ───────────────────────────────────────────────────────

  /// Split a mnemonic string into its individual words.
  static List<String> splitWords(String mnemonic) =>
      mnemonic.trim().split(RegExp(r'\s+'));

  /// Validate that [words] form a valid BIP39 mnemonic.
  static bool validateWords(List<String> words) =>
      bip39.validateMnemonic(words.join(' '));
}
