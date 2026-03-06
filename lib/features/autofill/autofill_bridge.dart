import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:cipherowl/core/platform/platform_info.dart';
import 'autofill_credential.dart';

/// Bridge between the Dart/Flutter vault layer and the platform AutoFill service.
///
/// **Android**: writes credentials into EncryptedSharedPreferences (via
/// MethodChannel → CipherOwlAutofillService.kt) so Android can fill fields
/// in other apps even when Flutter is not running.
///
/// **iOS**: writes credentials to the shared App Group UserDefaults
/// (`group.com.cipherowl.cipherowl`) via MethodChannel → AppDelegate.swift,
/// and refreshes ASCredentialIdentityStore so the CipherOwl AutoFill extension
/// (`AutoFillExtension`) appears in the iOS QuickType bar.
///
/// Usage — call from VaultBloc once plaintext credentials are available:
/// ```dart
/// await AutofillBridge.instance.updateCache(credentials);
/// ```
/// Call [clearCache] when the vault is locked.
class AutofillBridge {
  AutofillBridge._();

  /// Singleton instance.
  static final AutofillBridge instance = AutofillBridge._();

  static const _channel = MethodChannel('com.cipherowl/autofill');

  // ── Supported platforms ──────────────────────────────────────────────────

  static bool get _supported => PlatformInfo.isMobile;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Push [credentials] to the autofill cache (Android + iOS).
  ///
  /// No-op on unsupported platforms (desktop/web).
  Future<void> updateCache(List<AutofillCredential> credentials) async {
    if (!_supported) return;
    try {
      final json = jsonEncode(credentials.map((c) => c.toMap()).toList());
      await _channel.invokeMethod<void>('updateAutofillCache', {'cache': json});
    } on MissingPluginException {
      // MethodChannel not yet registered — silently ignore during early init
    } catch (e) {
      // Non-critical: log but don't rethrow
      // ignore: avoid_print
      print('[AutofillBridge] updateCache error: $e');
    }
  }

  /// Clear the autofill credential cache (call when vault is locked).
  ///
  /// No-op on unsupported platforms.
  Future<void> clearCache() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('clearAutofillCache');
    } on MissingPluginException {
      // Ignore — service may not be set up yet
    } catch (e) {
      // ignore: avoid_print
      print('[AutofillBridge] clearCache error: $e');
    }
  }

  /// Returns true if the autofill service/extension is available.
  ///
  /// Android: checks whether CipherOwl is selected as the system autofill provider.
  /// iOS: always true (extension is always available; user enables in Settings).
  Future<bool> isAutofillServiceEnabled() async {
    if (!_supported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('isAutofillServiceEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system autofill settings so the user can enable CipherOwl.
  ///
  /// Android: opens the autofill provider picker.
  /// iOS: opens Settings app (navigate to Passwords → AutoFill Passwords).
  Future<void> requestEnableAutofillService() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('requestEnableAutofillService');
    } catch (e) {
      // ignore: avoid_print
      print('[AutofillBridge] requestEnableAutofillService error: $e');
    }
  }
}
