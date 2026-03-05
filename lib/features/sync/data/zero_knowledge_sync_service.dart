import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../src/rust/frb_generated.dart/api.dart';
import '../../vault/domain/entities/vault_entry.dart';
import '../domain/sync_result.dart';

/// Zero-knowledge sync service for CipherOwl.
///
/// **How it works:**
/// 1. A 32-byte *sync key* is generated once per device and stored in
///    FlutterSecureStorage. It is NEVER sent to the server.
/// 2. To upload: the full [VaultEntry] is serialised to JSON, then the
///    entire JSON blob is encrypted with AES-256-GCM (Rust) using the
///    sync key. Only the base-64 ciphertext is sent to Supabase.
/// 3. To download: the ciphertext is fetched, decrypted locally, and
///    deserialised back to [VaultEntry].
/// 4. Conflict resolution — **last write wins** on [VaultEntry.updatedAt].
class ZeroKnowledgeSyncService {
  static const String _syncKeyStorageKey = 'cipher_sync_key';
  static const String _table = 'encrypted_vaults';
  static const String _metaTable = 'sync_metadata';

  final FlutterSecureStorage _storage;
  final SupabaseClient _client;

  ZeroKnowledgeSyncService({
    FlutterSecureStorage? storage,
    SupabaseClient? client,
  })  : _storage =
            storage ?? const FlutterSecureStorage(),
        _client = client ?? Supabase.instance.client;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Pull new/updated entries from Supabase and push local unsynced changes.
  ///
  /// [localItems]   — all local [VaultEntry] rows (from [VaultRepository]).
  /// [onMerge]      — callback to persist merged [VaultEntry] list locally.
  /// [sinceLastSync]— only fetch server rows updated after this timestamp.
  ///
  /// Returns [SyncSkipped] if the user is not signed in to cloud.
  Future<SyncResult> sync({
    required List<VaultEntry> localItems,
    required Future<void> Function(List<VaultEntry> merged) onMerge,
    DateTime? sinceLastSync,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return const SyncSkipped();

    try {
      final syncKey = await _getOrCreateSyncKey();

      // ── 1. Push: local items not yet synced (syncedAt == null or updatedAt > syncedAt)
      final toUpload = localItems
          .where((e) =>
              e.syncedAt == null ||
              e.updatedAt.isAfter(e.syncedAt!))
          .toList();

      for (final entry in toUpload) {
        await _upsertEntry(entry, syncKey, user.id);
      }

      // ── 2. Pull: remote rows updated after sinceLastSync
      final query = _client
          .from(_table)
          .select('id, encrypted_payload, updated_at, is_deleted')
          .eq('user_id', user.id)
          .eq('is_deleted', false);

      final remoteRows = sinceLastSync != null
          ? await (query as dynamic)
              .gt('updated_at', sinceLastSync.toIso8601String())
          : await query;

      final remoteEntries = <VaultEntry>[];
      for (final row in (remoteRows as List)) {
        final entry =
            await _decryptRow(row as Map<String, dynamic>, syncKey, user.id);
        if (entry != null) remoteEntries.add(entry);
      }

      // ── 3. Merge: prefer newer updatedAt
      final merged = _merge(localItems, remoteEntries);
      await onMerge(merged);

      // ── 4. Update sync_metadata
      await _updateSyncMeta(user.id, merged.length);

      return SyncSuccess(
        pushed: toUpload.length,
        pulled: remoteEntries.length,
      );
    } catch (e) {
      return SyncFailure('Sync failed', e);
    }
  }

  /// Soft-delete a vault item on the server (preserves tombstone for sync).
  Future<void> deleteEntry(String entryId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from(_table).update({
      'is_deleted': true,
      'synced_at': DateTime.now().toIso8601String(),
    }).eq('id', entryId).eq('user_id', user.id);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns the sync key, generating and storing it on first use.
  Future<Uint8List> _getOrCreateSyncKey() async {
    final stored = await _storage.read(key: _syncKeyStorageKey);
    if (stored != null) return base64Decode(stored);
    final key = apiGenerateKey(); // 32 random bytes via Rust
    await _storage.write(
        key: _syncKeyStorageKey, value: base64Encode(key));
    return key;
  }

  /// Encrypts [entry] with [syncKey] and upserts it to Supabase.
  Future<void> _upsertEntry(
      VaultEntry entry, Uint8List syncKey, String userId) async {
    final plaintext = utf8.encode(jsonEncode(_entryToJson(entry)));
    final ciphertext = apiEncrypt(plaintext: plaintext, key: syncKey);
    final payload = base64Encode(ciphertext);

    await _client.from(_table).upsert({
      'id': entry.id,
      'user_id': userId,
      'encrypted_payload': payload,
      'category': entry.category.name,
      'updated_at': entry.updatedAt.toIso8601String(),
      'synced_at': DateTime.now().toIso8601String(),
      'is_deleted': false,
    });
  }

  /// Decrypts a Supabase row back to [VaultEntry]. Returns null on failure.
  Future<VaultEntry?> _decryptRow(
      Map<String, dynamic> row, Uint8List syncKey, String userId) async {
    try {
      final ciphertext = base64Decode(row['encrypted_payload'] as String);
      final plaintext = apiDecrypt(ciphertextWithNonce: ciphertext, key: syncKey);
      final json = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
      return _entryFromJson(json, userId);
    } catch (_) {
      return null; // corrupted or encrypted with a different key
    }
  }

  /// Last-write-wins merge: for each id, keep the entry with the later updatedAt.
  List<VaultEntry> _merge(
      List<VaultEntry> local, List<VaultEntry> remote) {
    final map = <String, VaultEntry>{
      for (final e in local) e.id: e,
    };
    for (final r in remote) {
      final l = map[r.id];
      if (l == null || r.updatedAt.isAfter(l.updatedAt)) {
        map[r.id] = r;
      }
    }
    return map.values.toList();
  }

  Future<void> _updateSyncMeta(String userId, int totalItems) async {
    await _client.from(_metaTable).upsert({
      'user_id': userId,
      'last_sync_at': DateTime.now().toIso8601String(),
      'total_items': totalItems,
    });
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> _entryToJson(VaultEntry e) => {
        'id': e.id,
        'userId': e.userId,
        'title': e.title,
        'username': e.username,
        'encryptedPassword': e.encryptedPassword != null
            ? base64Encode(e.encryptedPassword!)
            : null,
        'url': e.url,
        'encryptedNotes': e.encryptedNotes != null
            ? base64Encode(e.encryptedNotes!)
            : null,
        'encryptedTotpSecret': e.encryptedTotpSecret != null
            ? base64Encode(e.encryptedTotpSecret!)
            : null,
        'category': e.category.name,
        'isFavorite': e.isFavorite,
        'strengthScore': e.strengthScore,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
        'lastAccessedAt': e.lastAccessedAt?.toIso8601String(),
      };

  VaultEntry _entryFromJson(Map<String, dynamic> j, String fallbackUserId) =>
      VaultEntry(
        id: j['id'] as String,
        userId: (j['userId'] as String?) ?? fallbackUserId,
        title: j['title'] as String,
        username: j['username'] as String?,
        encryptedPassword: j['encryptedPassword'] != null
            ? base64Decode(j['encryptedPassword'] as String)
            : null,
        url: j['url'] as String?,
        encryptedNotes: j['encryptedNotes'] != null
            ? base64Decode(j['encryptedNotes'] as String)
            : null,
        encryptedTotpSecret: j['encryptedTotpSecret'] != null
            ? base64Decode(j['encryptedTotpSecret'] as String)
            : null,
        category: VaultCategory.values.firstWhere(
          (c) => c.name == (j['category'] as String),
          orElse: () => VaultCategory.login,
        ),
        isFavorite: (j['isFavorite'] as bool?) ?? false,
        strengthScore: (j['strengthScore'] as int?) ?? -1,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        lastAccessedAt: j['lastAccessedAt'] != null
            ? DateTime.parse(j['lastAccessedAt'] as String)
            : null,
        syncedAt: DateTime.now(),
      );
}