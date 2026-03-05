import 'package:cipherowl/src/rust/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../services/fido2_credential_service.dart';

/// Handles master password hashing, storage, and biometric authentication.
///
/// Password hashing: Argon2id via Rust FFI (t=3, m=64MiB, p=4 — OWASP MASVS L2).
/// The stored PHC string includes the salt, so no separate salt storage needed.
class AuthRepository {
  static const String _setupDoneKey = 'cipher_setup_done';
  static const String _masterHashKey = 'cipher_master_hash'; // PHC string from Argon2id
  static const String _lockoutUntilKey = 'cipher_lockout_until';
  static const String _failedAttemptsKey = 'cipher_failed_attempts';
  // ── Duress password ─────────────────────────────────────
  static const String _duressHashKey = 'cipher_duress_hash';
  // ── Intruder snapshot ────────────────────────────────────
  /// Number of cumulative failed attempts since last reset (cross-session).
  static const String _totalFailedKey = 'cipher_total_failed';
  static const int _intruderTriggerCount = 3;

  static const int _maxAttempts = 5;
  static const int _lockoutMinutes = 5;

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final Fido2CredentialService _fido2;

  AuthRepository({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    Fido2CredentialService? fido2,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication(),
        _fido2 = fido2 ?? Fido2CredentialService();

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

    // If the real password failed, check duress password
    final duressHash = await _storage.read(key: _duressHashKey);
    if (!isMatch && duressHash != null) {
      final isDuress = await apiVerifyPassword(password: password, hash: duressHash);
      if (isDuress) {
        // Duress match — report success as duress so caller can open decoy vault
        await _storage.write(key: _failedAttemptsKey, value: '0');
        return VerifyResult.duress();
      }
    }

    if (isMatch) {
      // Reset failed attempts on success
      await _storage.write(key: _failedAttemptsKey, value: '0');
      await _storage.write(key: _totalFailedKey, value: '0');
      return VerifyResult.success();
    }

    // Track failed attempt
    final attemptsStr = await _storage.read(key: _failedAttemptsKey) ?? '0';
    final attempts = int.parse(attemptsStr) + 1;
    await _storage.write(key: _failedAttemptsKey, value: '$attempts');

    // Track cumulative failed attempts for intruder snapshot trigger
    final totalStr = await _storage.read(key: _totalFailedKey) ?? '0';
    final total = int.parse(totalStr) + 1;
    await _storage.write(key: _totalFailedKey, value: '$total');

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
      shouldCaptureSnapshot: total >= _intruderTriggerCount && total % _intruderTriggerCount == 0,
    );
  }

  Future<int> getFailedAttempts() async {
    final str = await _storage.read(key: _failedAttemptsKey) ?? '0';
    return int.parse(str);
  }

  // ── Duress Password ─────────────────────────────────────

  /// Store (or clear) a duress password. Pass null to remove it.
  Future<void> saveDuressPassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _duressHashKey);
      return;
    }
    final hash = await apiHashPassword(password: password);
    await _storage.write(key: _duressHashKey, value: hash);
  }

  Future<bool> hasDuressPassword() async {
    final h = await _storage.read(key: _duressHashKey);
    return h != null && h.isNotEmpty;
  }

  // ── FIDO2 ───────────────────────────────────────────────

  /// Sign a randomly-generated challenge with the first available FIDO2
  /// credential found on this device and verify the signature locally.
  ///
  /// Returns [Fido2AuthResult.success] if verified.
  Future<Fido2AuthResult> authenticateWithFido2() async {
    try {
      final credentials = await _fido2.listCredentials();
      if (credentials.isEmpty) {
        return Fido2AuthResult.noCredentials();
      }

      // Use the most-recently-used credential
      final cred = credentials.first;

      // Generate a 32-byte random challenge via Rust CSPRNG
      final challenge = apiGenerateKey(); // 32 random bytes

      // Sign with stored private key
      final signatureB64 = await _fido2.sign(
        credentialId: cred.id,
        challenge: challenge,
      );

      // Verify signature with public key (local verification)
      final isValid = await _fido2.verify(
        credentialId: cred.id,
        challenge: challenge,
        signatureBase64: signatureB64,
      );

      if (isValid) {
        return Fido2AuthResult.success(credentialId: cred.id);
      }
      return Fido2AuthResult.failed('التحقق من التوقيع فشل');
    } catch (e) {
      return Fido2AuthResult.error('خطأ في مفتاح FIDO2: $e');
    }
  }

  Future<Fido2CredentialService> get fido2Service async => _fido2;

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

enum VerifyStatus { success, duress, failed, locked, error }

class VerifyResult {
  final VerifyStatus status;
  final int attempts;
  final int remainingAttempts;
  final Duration? lockDuration;
  final bool isNewLockout;
  final String? errorMessage;
  /// True when the total failed count reached a multiple of 3 — trigger a snapshot.
  final bool shouldCaptureSnapshot;

  const VerifyResult._({
    required this.status,
    this.attempts = 0,
    this.remainingAttempts = 0,
    this.lockDuration,
    this.isNewLockout = false,
    this.errorMessage,
    this.shouldCaptureSnapshot = false,
  });

  factory VerifyResult.success() =>
      const VerifyResult._(status: VerifyStatus.success);

  factory VerifyResult.duress() =>
      const VerifyResult._(status: VerifyStatus.duress);

  factory VerifyResult.failed({
    required int attempts,
    required int remainingAttempts,
    bool shouldCaptureSnapshot = false,
  }) =>
      VerifyResult._(
        status: VerifyStatus.failed,
        attempts: attempts,
        remainingAttempts: remainingAttempts,
        shouldCaptureSnapshot: shouldCaptureSnapshot,
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

// ─── FIDO2 result ─────────────────────────────────────────────

enum Fido2AuthStatus { success, failed, noCredentials, error }

class Fido2AuthResult {
  final Fido2AuthStatus status;
  final String? credentialId;
  final String? message;

  const Fido2AuthResult._({required this.status, this.credentialId, this.message});

  factory Fido2AuthResult.success({required String credentialId}) =>
      Fido2AuthResult._(status: Fido2AuthStatus.success, credentialId: credentialId);

  factory Fido2AuthResult.failed(String message) =>
      Fido2AuthResult._(status: Fido2AuthStatus.failed, message: message);

  factory Fido2AuthResult.noCredentials() =>
      const Fido2AuthResult._(
          status: Fido2AuthStatus.noCredentials,
          message: 'لا توجد مفاتيح FIDO2 مسجّلة على هذا الجهاز');

  factory Fido2AuthResult.error(String message) =>
      Fido2AuthResult._(status: Fido2AuthStatus.error, message: message);
}
