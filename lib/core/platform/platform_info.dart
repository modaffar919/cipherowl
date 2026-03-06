import 'package:flutter/foundation.dart';

/// Platform capability detection for cross-platform feature gating.
///
/// Use this instead of `dart:io` `Platform.isX` which doesn't compile on web.
class PlatformInfo {
  PlatformInfo._();

  /// True when running in a browser (dart2js / dart2wasm).
  static bool get isWeb => kIsWeb;

  /// True on Android (native, not web).
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True on iOS (native, not web).
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// True on any mobile native platform.
  static bool get isMobile => isAndroid || isIOS;

  /// True on Windows (native, not web).
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// True on macOS (native, not web).
  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// True on Linux (native, not web).
  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// True on any desktop native platform.
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  // ── Feature availability ──────────────────────────────────────────

  /// Camera (face enrollment, intruder photos, QR scan).
  static bool get hasCamera => isMobile;

  /// Device biometrics (fingerprint, Face ID, Windows Hello).
  static bool get hasBiometrics => isMobile || isWindows || isMacOS;

  /// Geofencing / GPS location services.
  static bool get hasGeofencing => isMobile;

  /// Native file system (dart:io File).
  static bool get hasFileSystem => !isWeb;

  /// Native push notifications (Firebase Cloud Messaging).
  static bool get hasPushNotifications => isMobile;

  /// Native autofill service integration.
  static bool get hasAutofill => isMobile;

  /// SQLCipher encrypted database.
  static bool get hasSqlCipher => !isWeb;

  /// Secure hardware-backed key storage (Keychain / Keystore).
  static bool get hasSecureStorage => !isWeb;

  /// Native share sheet.
  static bool get hasShareSheet => isMobile;
}
