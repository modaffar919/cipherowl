import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:cipherowl/core/database/smartvault_database.dart';
import '../../domain/entities/vault_entry.dart';

/// Repository for vault CRUD operations.
///
/// Translates between the Drift [VaultItem] row type and the
/// clean-architecture [VaultEntry] domain model.
///
/// Encryption/decryption uses AES-256-GCM via Rust FFI (EPIC-2 complete).
class VaultRepository {
  final SmartVaultDatabase _db;
  static const _uuid = Uuid();

  VaultRepository(this._db);

  // ── Streams ──────────────────────────────────────────────────────────────

  /// Live stream of all non-deleted items for [userId].
  Stream<List<VaultEntry>> watchItems(String userId) =>
      _db.vaultDao
          .watchAllItems(userId)
          .map((rows) => rows.map(_toEntry).toList());

  /// Live stream of favourite items.
  Stream<List<VaultEntry>> watchFavorites(String userId) =>
      _db.vaultDao
          .watchFavoriteItems(userId)
          .map((rows) => rows.map(_toEntry).toList());

  // ── Queries ──────────────────────────────────────────────────────────────

  Future<List<VaultEntry>> getAllItems(String userId) async {
    final rows = await _db.vaultDao.getAllItems(userId);
    return rows.map(_toEntry).toList();
  }

  Future<VaultEntry?> getItemById(String id) async {
    final row = await _db.vaultDao.findItemById(id);
    return row != null ? _toEntry(row) : null;
  }

  Future<List<VaultEntry>> searchItems(String userId, String query) async {
    final rows = await _db.vaultDao.searchItems(userId, query);
    return rows.map(_toEntry).toList();
  }

  Future<int> countItems(String userId) => _db.vaultDao.countItems(userId);

  // ── Mutations ────────────────────────────────────────────────────────────

  /// Create a new vault entry (generates a UUID if [entry.id] is empty).
  Future<VaultEntry> addItem(VaultEntry entry) async {
    final now = DateTime.now();
    final newEntry = entry.copyWith(
      id: entry.id.isEmpty ? _uuid.v4() : entry.id,
      createdAt: now,
      updatedAt: now,
    );
    await _db.vaultDao.upsertItem(_toCompanion(newEntry));
    await _db.securityLogDao.logEvent(
      eventType: 'item_created',
      description: 'أضاف: ${newEntry.title}',
      severity: 'info',
      relatedItemId: newEntry.id,
    );
    return newEntry;
  }

  /// Update an existing vault entry. Bumps [updatedAt] automatically.
  /// Saves a version snapshot of the previous state for rollback.
  Future<void> updateItem(VaultEntry entry) async {
    // Save version snapshot before overwriting
    final existing = await _db.vaultDao.findItemById(entry.id);
    if (existing != null) {
      final ver = await _db.vaultDao.nextVersion(entry.id);
      final snapshot = _serializeSnapshot(existing);
      await _db.vaultDao.saveVersion(
        itemId: entry.id,
        version: ver,
        encryptedSnapshot: Uint8List.fromList(utf8.encode(snapshot)),
        changeType: 'update',
      );
    }

    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _db.vaultDao.upsertItem(_toCompanion(updated));
    await _db.securityLogDao.logEvent(
      eventType: 'item_updated',
      description: 'حدّث: ${entry.title}',
      severity: 'info',
      relatedItemId: entry.id,
    );
  }

  /// Soft-delete an item (retains row for sync until confirmed).
  Future<void> deleteItem(String id) async {
    await _db.vaultDao.softDeleteItem(id);
    await _db.securityLogDao.logEvent(
      eventType: 'item_deleted',
      description: 'حذف العنصر: $id',
      severity: 'warning',
      relatedItemId: id,
    );
  }

  /// Toggle favourite and return the updated entry.
  Future<void> toggleFavorite(String id, {required bool value}) =>
      _db.vaultDao.setFavorite(id, value: value);

  /// Upsert an entry as-is (used by cloud sync merge — preserves updatedAt).
  Future<void> upsertItem(VaultEntry entry) =>
      _db.vaultDao.upsertItem(_toCompanion(entry));

  /// Cache the zxcvbn strength score from the Rust analyser.
  Future<void> updateStrengthScore(String id, int score) =>
      _db.vaultDao.updateStrengthScore(id, score);

  // ── Version History ──────────────────────────────────────────────────────

  /// Get all version snapshots for an item, newest first.
  Future<List<VaultItemVersionInfo>> getVersionHistory(String itemId) async {
    final rows = await _db.vaultDao.getVersions(itemId);
    return rows
        .map((r) => VaultItemVersionInfo(
              id: r.id,
              itemId: r.itemId,
              version: r.version,
              changeType: r.changeType,
              changedAt: r.changedAt,
            ))
        .toList();
  }

  /// Restore a vault item to a previous version snapshot.
  Future<VaultEntry?> restoreVersion(String itemId, int versionId) async {
    final rows = await _db.vaultDao.getVersions(itemId);
    final target = rows.where((r) => r.id == versionId).firstOrNull;
    if (target == null) return null;

    final json = utf8.decode(target.encryptedSnapshot);
    final map = jsonDecode(json) as Map<String, dynamic>;
    final restored = _entryFromSnapshot(map);

    // Save current state as a version before restoring
    await updateItem(restored);
    return restored;
  }

  /// Delete old versions beyond 90 days.
  Future<int> pruneOldVersions(String itemId, {int days = 90}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _db.vaultDao.pruneVersions(itemId, cutoff);
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────

  VaultEntry _toEntry(VaultItem row) => VaultEntry(
        id: row.id,
        userId: row.userId,
        title: row.title,
        username: row.username,
        encryptedPassword: row.encryptedPassword != null
            ? Uint8List.fromList(row.encryptedPassword!)
            : null,
        url: row.url,
        encryptedNotes: row.encryptedNotes != null
            ? Uint8List.fromList(row.encryptedNotes!)
            : null,
        encryptedTotpSecret: row.encryptedTotpSecret != null
            ? Uint8List.fromList(row.encryptedTotpSecret!)
            : null,
        category: VaultCategory.values.firstWhere(
          (c) => c.name == row.category,
          orElse: () => VaultCategory.login,
        ),
        isFavorite: row.isFavorite,
        strengthScore: row.strengthScore ?? -1,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        lastAccessedAt: row.lastAccessedAt,
        syncedAt: row.syncedAt,
      );

  VaultItemsCompanion _toCompanion(VaultEntry e) => VaultItemsCompanion(
        id: Value(e.id),
        userId: Value(e.userId),
        title: Value(e.title),
        username: Value(e.username),
        encryptedPassword: Value(e.encryptedPassword),
        url: Value(e.url),
        encryptedNotes: Value(e.encryptedNotes),
        encryptedTotpSecret: Value(e.encryptedTotpSecret),
        category: Value(e.category.name),
        isFavorite: Value(e.isFavorite),
        strengthScore: Value(e.strengthScore >= 0 ? e.strengthScore : null),
        createdAt: Value(e.createdAt),
        updatedAt: Value(e.updatedAt),
        lastAccessedAt: Value(e.lastAccessedAt),
        syncedAt: Value(e.syncedAt),
      );

  /// Serialize a VaultItem row to JSON string for version snapshots.
  String _serializeSnapshot(VaultItem row) {
    return jsonEncode({
      'id': row.id,
      'user_id': row.userId,
      'title': row.title,
      'username': row.username,
      'url': row.url,
      'category': row.category,
      'is_favorite': row.isFavorite,
      'strength_score': row.strengthScore,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'last_accessed_at': row.lastAccessedAt?.toIso8601String(),
      'synced_at': row.syncedAt?.toIso8601String(),
    });
  }

  /// Reconstruct a VaultEntry from a snapshot JSON map.
  VaultEntry _entryFromSnapshot(Map<String, dynamic> map) {
    return VaultEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      username: map['username'] as String?,
      url: map['url'] as String?,
      category: VaultCategory.values.firstWhere(
        (c) => c.name == (map['category'] as String? ?? 'login'),
        orElse: () => VaultCategory.login,
      ),
      isFavorite: map['is_favorite'] as bool? ?? false,
      strengthScore: map['strength_score'] as int? ?? -1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastAccessedAt: map['last_accessed_at'] != null
          ? DateTime.parse(map['last_accessed_at'] as String)
          : null,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
    );
  }
}

/// Lightweight info about a vault item version (no snapshot blob).
class VaultItemVersionInfo {
  final int id;
  final String itemId;
  final int version;
  final String changeType;
  final DateTime changedAt;

  const VaultItemVersionInfo({
    required this.id,
    required this.itemId,
    required this.version,
    required this.changeType,
    required this.changedAt,
  });
}
