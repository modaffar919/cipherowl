import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'autofill_credential.dart';

/// Bridge between the Dart/Flutter vault layer and the Android AutofillService.
///
/// Writes a JSON credential cache into SharedPreferences (via a MethodChannel)
/// so that [CipherOwlAutofillService] (Kotlin) can read it when filling
/// username/password fields in other apps — even when the Flutter engine is
/// not running.
///
/// Usage — call from VaultBloc (or any BLoC) once plaintext credentials are
/// available:
/// ```dart
/// await AutofillBridge.instance.updateCache(credentials);
/// ```
/// Call [clearCache] when the vault is locked.
class AutofillBridge {
  AutofillBridge._();

  /// Singleton instance.
  static final AutofillBridge instance = AutofillBridge._();

  /// Channel name — must match the Kotlin side if a MethodChannel
  /// implementation is added there. Currently the bridge writes directly
  /// to SharedPreferences via the platform channel helper below.
  static const _channel = MethodChannel('com.cipherowl/autofill');

  // ── Public API ───────────────────────────────────────────────────────────

  /// Push [credentials] to the Android autofill cache.
  ///
  /// No-op on non-Android platforms.
  Future<void> updateCache(List<AutofillCredential> credentials) async {
    if (!Platform.isAndroid) return;
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
  /// No-op on non-Android platforms.
  Future<void> clearCache() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('clearAutofillCache');
    } on MissingPluginException {
      // Ignore — service may not be set up yet
    } catch (e) {
      // ignore: avoid_print
      print('[AutofillBridge] clearCache error: $e');
    }
  }

  /// Returns true if the current device has an autofill service enabled.
  ///
  /// Useful for showing an "Enable autofill" prompt in Settings.
  Future<bool> isAutofillServiceEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('isAutofillServiceEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Android system autofill picker so the user can select
  /// CipherOwl as the active autofill provider.
  Future<void> requestEnableAutofillService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('requestEnableAutofillService');
    } catch (e) {
      // ignore: avoid_print
      print('[AutofillBridge] requestEnableAutofillService error: $e');
    }
  }
}
