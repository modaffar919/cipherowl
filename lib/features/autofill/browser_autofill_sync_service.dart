import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cipherowl/src/rust/api.dart';
import 'autofill_credential.dart';

/// Syncs plaintext autofill credentials to the `browser_autofill` Supabase
/// table for use by the CipherOwl Chrome/Firefox browser extension.
///
/// **Encryption**: Each credential JSON `{id, title, username, password, url}`
/// is individually encrypted with AES-256-GCM using the device sync key
/// (the same 32-byte random key managed by [ZeroKnowledgeSyncService]).
/// The browser extension decrypts by importing this key via the
/// "Link Browser Extension" pairing flow.
///
/// **Security note**: Passwords are stored plaintext inside the encrypted
/// payload.  The security boundary is the sync key — treat it like a
/// master password.
class BrowserAutofillSyncService {
  // Shared storage key with ZeroKnowledgeSyncService
  static const _syncKeyStorageKey = 'cipher_sync_key';
  static const _table = 'browser_autofill';

  final FlutterSecureStorage _storage;
  final SupabaseClient _client;

  BrowserAutofillSyncService({
    FlutterSecureStorage? storage,
    SupabaseClient? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? Supabase.instance.client;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the sync key as a 64-char hex string for pairing with the
  /// browser extension.  Returns `null` if no sync key has been generated yet
  /// (i.e., the vault has never been synced to cloud).
  Future<String?> exportSyncKeyHex() async {
    final stored = await _storage.read(key: _syncKeyStorageKey);
    if (stored == null) return null;
    final bytes = base64Decode(stored);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Upserts [credentials] (with plaintext passwords) to `browser_autofill`.
  ///
  /// Each entry is encrypted individually with the sync key so the browser
  /// extension can incrementally fetch changes.  Credentials that are not
  /// in [credentials] are NOT deleted; call [clearCredentials] for a
  /// full reset.
  Future<void> syncCredentials(List<AutofillCredential> credentials) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final syncKey = await _getSyncKey();
    if (syncKey == null) return;

    final now = DateTime.now().toIso8601String();
    for (final cred in credentials) {
      final plaintext = utf8.encode(jsonEncode({
        'id': cred.id,
        'title': cred.title,
        'username': cred.username,
        'password': cred.password,
        'url': cred.url,
      }));

      final ciphertext = apiEncrypt(plaintext: plaintext, key: syncKey);

      await _client.from(_table).upsert({
        'id': cred.id,
        'user_id': user.id,
        'encrypted_payload': base64Encode(ciphertext),
        'url_hint': _extractDomain(cred.url),
        'updated_at': now,
        'is_deleted': false,
      });
    }
  }

  /// Soft-deletes all `browser_autofill` rows for the current user.
  ///
  /// Call this when the user disables browser extension sync or logs out.
  Future<void> clearCredentials() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from(_table)
        .update({'is_deleted': true})
        .eq('user_id', user.id);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<Uint8List?> _getSyncKey() async {
    final stored = await _storage.read(key: _syncKeyStorageKey);
    if (stored == null) return null;
    return base64Decode(stored);
  }

  /// Extracts the lowercase host from [url], e.g. `"github.com"`.
  static String _extractDomain(String url) {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url.contains('://') ? url : 'https://$url');
      return uri.host.toLowerCase();
    } catch (_) {
      return url.toLowerCase();
    }
  }
}
