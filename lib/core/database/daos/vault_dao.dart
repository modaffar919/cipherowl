import 'package:drift/drift.dart';

import '../smartvault_database.dart';

part 'vault_dao.g.dart';

/// Data Access Object for [VaultItems] table.
///
/// All write operations bump [VaultItem.updatedAt] so incremental sync works.
@DriftAccessor(tables: [VaultItems, VaultItemVersions, VaultAttachments])
class VaultDao extends DatabaseAccessor<SmartVaultDatabase>
    with _$VaultDaoMixin {
  VaultDao(super.db);

  // ── Streams (real-time) ─────────────────────────────────────────────────

  /// Watch all non-deleted items for a user, sorted by title.
  Stream<List<VaultItem>> watchAllItems(String userId) =>
      (select(vaultItems)
            ..where(
                (t) => t.userId.equals(userId) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .watch();

  /// Watch only favourite items.
  Stream<List<VaultItem>> watchFavoriteItems(String userId) =>
      (select(vaultItems)
            ..where((t) =>
                t.userId.equals(userId) &
                t.isDeleted.equals(false) &
                t.isFavorite.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .watch();

  // ── Queries ─────────────────────────────────────────────────────────────

  /// Get all non-deleted items once (no live updates).
  Future<List<VaultItem>> getAllItems(String userId) =>
      (select(vaultItems)
            ..where(
                (t) => t.userId.equals(userId) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();

  /// Find a single vault item by UUID. Returns null if not found.
  Future<VaultItem?> findItemById(String id) =>
      (select(vaultItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Full-text search across title, username, and url.
  Future<List<VaultItem>> searchItems(String userId, String query) {
    final q = '%$query%';
    return (select(vaultItems)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              (t.title.like(q) | t.username.like(q) | t.url.like(q))))
        .get();
  }

  /// Filter items by category string (e.g. 'login', 'card').
  Future<List<VaultItem>> itemsByCategory(
          String userId, String category) =>
      (select(vaultItems)
            ..where((t) =>
                t.userId.equals(userId) &
                t.isDeleted.equals(false) &
                t.category.equals(category))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();

  /// Items modified after [since] — used for incremental cloud sync.
  Future<List<VaultItem>> itemsModifiedAfter(
          String userId, DateTime since) =>
      (select(vaultItems)
            ..where((t) =>
                t.userId.equals(userId) &
                t.updatedAt.isBiggerThanValue(since)))
          .get();

  /// Count of non-deleted items for a user.
  Future<int> countItems(String userId) async {
    final count = countAll(
      filter: vaultItems.userId.equals(userId) &
          vaultItems.isDeleted.equals(false),
    );
    final query = selectOnly(vaultItems)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count)!;
  }

  // ── Mutations ───────────────────────────────────────────────────────────

  /// Insert or replace a vault item (upsert semantics for sync).
  Future<void> upsertItem(VaultItemsCompanion item) =>
      into(vaultItems).insertOnConflictUpdate(item);

  /// Soft-delete an item (keeps row for cloud sync / undo).
  Future<void> softDeleteItem(String id) =>
      (update(vaultItems)..where((t) => t.id.equals(id))).write(
        VaultItemsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Permanently delete a row (use only after confirmed cloud sync).
  Future<int> hardDeleteItem(String id) =>
      (delete(vaultItems)..where((t) => t.id.equals(id))).go();

  /// Toggle the favourite flag on a single item.
  Future<void> setFavorite(String id, {required bool value}) =>
      (update(vaultItems)..where((t) => t.id.equals(id))).write(
        VaultItemsCompanion(
          isFavorite: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Cache the zxcvbn strength score (0–4) on an item.
  Future<void> updateStrengthScore(String id, int score) =>
      (update(vaultItems)..where((t) => t.id.equals(id))).write(
        VaultItemsCompanion(
          strengthScore: Value(score),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Stamp [lastAccessedAt] to track recency.
  Future<void> recordAccess(String id) =>
      (update(vaultItems)..where((t) => t.id.equals(id))).write(
        VaultItemsCompanion(lastAccessedAt: Value(DateTime.now())),
      );

  // ── Version History ─────────────────────────────────────────────────────

  /// Save an encrypted snapshot of an item before mutation.
  Future<void> saveVersion({
    required String itemId,
    required int version,
    required Uint8List encryptedSnapshot,
    String changeType = 'update',
  }) =>
      into(vaultItemVersions).insert(VaultItemVersionsCompanion(
        itemId: Value(itemId),
        version: Value(version),
        encryptedSnapshot: Value(encryptedSnapshot),
        changeType: Value(changeType),
        changedAt: Value(DateTime.now()),
      ));

  /// Get the next version number for an item.
  Future<int> nextVersion(String itemId) async {
    final maxVersion = vaultItemVersions.version.max();
    final query = selectOnly(vaultItemVersions)
      ..addColumns([maxVersion])
      ..where(vaultItemVersions.itemId.equals(itemId));
    final row = await query.getSingle();
    return (row.read(maxVersion) ?? 0) + 1;
  }

  /// Get all versions for an item, newest first.
  Future<List<VaultItemVersion>> getVersions(String itemId) =>
      (select(vaultItemVersions)
            ..where((t) => t.itemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.desc(t.version)]))
          .get();

  /// Delete versions older than [cutoff] for an item.
  Future<int> pruneVersions(String itemId, DateTime cutoff) =>
      (delete(vaultItemVersions)
            ..where((t) =>
                t.itemId.equals(itemId) &
                t.changedAt.isSmallerThanValue(cutoff)))
          .go();

  // ── Attachments ─────────────────────────────────────────────────────────

  /// Insert a new attachment record.
  Future<void> insertAttachment(VaultAttachmentsCompanion attachment) =>
      into(vaultAttachments).insert(attachment);

  /// Get all attachments for a vault item.
  Future<List<VaultAttachment>> getAttachments(String itemId) =>
      (select(vaultAttachments)
            ..where((t) => t.itemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Delete a single attachment by ID.
  Future<int> deleteAttachment(String attachmentId) =>
      (delete(vaultAttachments)..where((t) => t.id.equals(attachmentId)))
          .go();

  /// Delete all attachments for a vault item.
  Future<int> deleteAttachmentsForItem(String itemId) =>
      (delete(vaultAttachments)..where((t) => t.itemId.equals(itemId)))
          .go();
}
