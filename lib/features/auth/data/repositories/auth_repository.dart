import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles master password hashing, storage, and biometric authentication.
///
/// NOTE: Password hashing currently uses PBKDF2-SHA256 (Dart-side).
/// Will be replaced by Rust Argon2id (EPIC-2 FFI integration).
class AuthRepository {
  static const String _setupDoneKey = 'cipher_setup_done';
  static const String _masterHashKey = 'cipher_master_hash';
  static const String _saltKey = 'cipher_master_salt';
  static const String _lockoutUntilKey = 'cipher_lockout_until';
  static const String _failedAttemptsKey = 'cipher_failed_attempts';

  static const int _maxAttempts = 5;
  static const int _lockoutMinutes = 5;

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  AuthRepository({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  // ── Setup Status ────────────────────────────────────────

  Future<bool> isSetupComplete() async {
    final value = await _storage.read(key: _setupDoneKey);
    return value == 'true';
  }

  // ── Master Password ─────────────────────────────────────

  /// Hash and store the master password.
  Future<void> saveMasterPassword(String password) async {
    final salt = _generateSalt();
    final hash = await _hashPassword(password, salt);
    await Future.wait([
      _storage.write(key: _saltKey, value: base64Encode(salt)),
      _storage.write(key: _masterHashKey, value: hash),
      _storage.write(key: _setupDoneKey, value: 'true'),
      _storage.write(key: _failedAttemptsKey, value: '0'),
    ]);
  }

  /// Verify master password. Returns [VerifyResult].
  Future<VerifyResult> verifyMasterPassword(String password) async {
    // Check lockout
    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutStr != null) {
      final lockoutUntil = DateTime.parse(lockoutStr);
      if (DateTime.now().isBefore(lockoutUntil)) {
        final remaining = lockoutUntil.difference(DateTime.now());
        return VerifyResult.locked(remaining);
      }
      // Lockout expired — reset
      await _storage.delete(key: _lockoutUntilKey);
      await _storage.write(key: _failedAttemptsKey, value: '0');
    }

    // Read stored hash
    final storedHash = await _storage.read(key: _masterHashKey);
    final storedSaltB64 = await _storage.read(key: _saltKey);
    if (storedHash == null || storedSaltB64 == null) {
      return VerifyResult.error('لم يتم إعداد كلمة المرور بعد');
    }

    // Compare
    final salt = base64Decode(storedSaltB64);
    final hash = await _hashPassword(password, salt);

    if (hash == storedHash) {
      // Reset failed attempts on success
      await _storage.write(key: _failedAttemptsKey, value: '0');
      return VerifyResult.success();
    }

    // Track failed attempt
    final attemptsStr = await _storage.read(key: _failedAttemptsKey) ?? '0';
    final attempts = int.parse(attemptsStr) + 1;
    await _storage.write(key: _failedAttemptsKey, value: '$attempts');

    if (attempts >= _maxAttempts) {
      final lockoutUntil = DateTime.now().add(
        Duration(minutes: _lockoutMinutes),
      );
      await _storage.write(
        key: _lockoutUntilKey,
        value: lockoutUntil.toIso8601String(),
      );
      return VerifyResult.locked(
        Duration(minutes: _lockoutMinutes),
        isNewLockout: true,
      );
    }

    return VerifyResult.failed(
      attempts: attempts,
      remainingAttempts: _maxAttempts - attempts,
    );
  }

  Future<int> getFailedAttempts() async {
    final str = await _storage.read(key: _failedAttemptsKey) ?? '0';
    return int.parse(str);
  }

  // ── Biometric ───────────────────────────────────────────

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<BiometricResult> authenticateWithBiometric() async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        return BiometricResult.unavailable('البصمة غير متاحة على هذا الجهاز');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'قم بالمصادقة للدخول إلى خزينة CipherOwl',
      );

      return authenticated
          ? BiometricResult.success()
          : BiometricResult.failed('فشلت المصادقة البيومترية');
    } catch (e) {
      return BiometricResult.unavailable('خطأ: $e');
    }
  }

  // ── Clear ────────────────────────────────────────────────

  Future<void> clearAll() async => _storage.deleteAll();

  // ── Private Helpers ──────────────────────────────────────

  /// PBKDF2-SHA256, 100,000 iterations.
  /// TODO: Replace with Rust Argon2id (EPIC-2 FFI integration — cipherowl-p6g).
  Future<String> _hashPassword(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return base64Encode(bytes);
  }

  List<int> _generateSalt() {
    final rng = Random.secure();
    return List<int>.generate(32, (_) => rng.nextInt(256));
  }
}

// ── Result Types ─────────────────────────────────────────────

enum VerifyStatus { success, failed, locked, error }

class VerifyResult {
  final VerifyStatus status;
  final int attempts;
  final int remainingAttempts;
  final Duration? lockDuration;
  final bool isNewLockout;
  final String? errorMessage;

  const VerifyResult._({
    required this.status,
    this.attempts = 0,
    this.remainingAttempts = 0,
    this.lockDuration,
    this.isNewLockout = false,
    this.errorMessage,
  });

  factory VerifyResult.success() =>
      const VerifyResult._(status: VerifyStatus.success);

  factory VerifyResult.failed({
    required int attempts,
    required int remainingAttempts,
  }) =>
      VerifyResult._(
        status: VerifyStatus.failed,
        attempts: attempts,
        remainingAttempts: remainingAttempts,
      );

  factory VerifyResult.locked(Duration duration, {bool isNewLockout = false}) =>
      VerifyResult._(
        status: VerifyStatus.locked,
        lockDuration: duration,
        isNewLockout: isNewLockout,
      );

  factory VerifyResult.error(String message) =>
      VerifyResult._(status: VerifyStatus.error, errorMessage: message);
}

enum BiometricStatus { success, failed, unavailable }

class BiometricResult {
  final BiometricStatus status;
  final String? message;

  const BiometricResult._({required this.status, this.message});

  factory BiometricResult.success() =>
      const BiometricResult._(status: BiometricStatus.success);

  factory BiometricResult.failed(String message) =>
      BiometricResult._(status: BiometricStatus.failed, message: message);

  factory BiometricResult.unavailable(String message) =>
      BiometricResult._(status: BiometricStatus.unavailable, message: message);
}
