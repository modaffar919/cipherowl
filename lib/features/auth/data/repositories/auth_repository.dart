import 'package:cipherowl/src/rust/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles master password hashing, storage, and biometric authentication.
///
/// Password hashing: Argon2id via Rust FFI (t=3, m=64MiB, p=4 — OWASP MASVS L2).
/// The stored PHC string includes the salt, so no separate salt storage needed.
class AuthRepository {
  static const String _setupDoneKey = 'cipher_setup_done';
  static const String _masterHashKey = 'cipher_master_hash'; // PHC string from Argon2id
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

  /// Hash and store the master password using Rust Argon2id (async, non-blocking).
  Future<void> saveMasterPassword(String password) async {
    // Rust computes Argon2id(t=3, m=64MiB) with a random salt, returns PHC string
    final phcHash = await apiHashPassword(password: password);
    await Future.wait([
      _storage.write(key: _masterHashKey, value: phcHash),
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

    // Read stored Argon2id PHC hash
    final storedHash = await _storage.read(key: _masterHashKey);
    if (storedHash == null) {
      return VerifyResult.error('لم يتم إعداد كلمة المرور بعد');
    }

    // Verify via Rust Argon2id (async, non-blocking)
    final isMatch = await apiVerifyPassword(password: password, hash: storedHash);

    if (isMatch) {
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
