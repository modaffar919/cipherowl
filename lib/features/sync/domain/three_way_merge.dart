import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../../vault/domain/entities/vault_entry.dart';

/// Result of a 3-way merge for a single vault item.
sealed class MergeResult {
  const MergeResult();
}

/// Both sides changed the same fields to the same values (or only one
/// side changed). A merged entry is produced automatically.
class MergeResolved extends MergeResult {
  final VaultEntry merged;
  const MergeResolved(this.merged);
}

/// Both sides changed the same field(s) to *different* values.
/// The user must pick which version to keep for each conflicting field.
class MergeConflict extends MergeResult {
  final VaultEntry local;
  final VaultEntry remote;
  final VaultEntry base;
  final Set<String> conflictingFields;
  const MergeConflict({
    required this.local,
    required this.remote,
    required this.base,
    required this.conflictingFields,
  });
}

/// Field-level 3-way merge engine for [VaultEntry].
///
/// Given a **base** (common ancestor), **local** (current device) and
/// **remote** (server copy), this engine compares each field independently:
///
///  - If neither side changed the field → keep base.
///  - If only one side changed it → take that side's value.
///  - If both sides changed it to the **same** value → take either (identical).
///  - If both sides changed it to **different** values → **conflict**.
///
/// This avoids the data-loss that last-write-wins causes.
class ThreeWayMergeEngine {
  const ThreeWayMergeEngine();

  static const _bytesEq = ListEquality<int>();

  /// Merge one item. [base] is the common ancestor (the state at last sync).
  MergeResult merge({
    required VaultEntry base,
    required VaultEntry local,
    required VaultEntry remote,
  }) {
    final conflicts = <String>{};

    // ── String fields ────────────────────────────────────────────────────
    final title =
        _mergeField('title', base.title, local.title, remote.title, conflicts);
    final username = _mergeField(
        'username', base.username, local.username, remote.username, conflicts);
    final url =
        _mergeField('url', base.url, local.url, remote.url, conflicts);
    final categoryName = _mergeField('category', base.category.name,
        local.category.name, remote.category.name, conflicts);
    final category = VaultCategory.values
        .firstWhere((c) => c.name == categoryName, orElse: () => base.category);

    // ── Bool fields ─────────────────────────────────────────────────────
    final isFavorite = _mergeField(
        'isFavorite', base.isFavorite, local.isFavorite, remote.isFavorite,
        conflicts);

    // ── Int fields ──────────────────────────────────────────────────────
    final strengthScore = _mergeField('strengthScore', base.strengthScore,
        local.strengthScore, remote.strengthScore, conflicts);

    // ── Blob fields (encrypted — compare bytes) ─────────────────────────
    final encPw = _mergeBlobField('encryptedPassword', base.encryptedPassword,
        local.encryptedPassword, remote.encryptedPassword, conflicts);
    final encNotes = _mergeBlobField('encryptedNotes', base.encryptedNotes,
        local.encryptedNotes, remote.encryptedNotes, conflicts);
    final encTotp = _mergeBlobField('encryptedTotpSecret',
        base.encryptedTotpSecret, local.encryptedTotpSecret,
        remote.encryptedTotpSecret, conflicts);

    if (conflicts.isNotEmpty) {
      return MergeConflict(
        local: local,
        remote: remote,
        base: base,
        conflictingFields: conflicts,
      );
    }

    // ── Timestamps: always take the latest ──────────────────────────────
    final updatedAt = local.updatedAt.isAfter(remote.updatedAt)
        ? local.updatedAt
        : remote.updatedAt;

    final lastAccessed = _latestNullable(
        local.lastAccessedAt, remote.lastAccessedAt);

    return MergeResolved(VaultEntry(
      id: base.id,
      userId: base.userId,
      title: title,
      username: username,
      encryptedPassword: encPw,
      url: url,
      encryptedNotes: encNotes,
      encryptedTotpSecret: encTotp,
      category: category,
      isFavorite: isFavorite,
      strengthScore: strengthScore,
      createdAt: base.createdAt,
      updatedAt: updatedAt,
      lastAccessedAt: lastAccessed,
      syncedAt: DateTime.now(),
    ));
  }

  /// Merge all items from local and remote using base snapshots.
  ///
  /// [bases] — the state at last sync (keyed by item id).
  /// Items that exist only on one side are auto-resolved (new or deleted).
  MergeBatchResult mergeBatch({
    required Map<String, VaultEntry> bases,
    required List<VaultEntry> local,
    required List<VaultEntry> remote,
  }) {
    final localMap = {for (final e in local) e.id: e};
    final remoteMap = {for (final e in remote) e.id: e};
    final allIds = {...localMap.keys, ...remoteMap.keys};

    final resolved = <VaultEntry>[];
    final conflicts = <MergeConflict>[];

    for (final id in allIds) {
      final l = localMap[id];
      final r = remoteMap[id];
      final b = bases[id];

      if (l != null && r == null) {
        // Local only — new item or remote deleted
        resolved.add(l);
        continue;
      }
      if (r != null && l == null) {
        // Remote only — new item or local deleted
        resolved.add(r.copyWith(syncedAt: DateTime.now()));
        continue;
      }
      if (l == null || r == null) continue; // shouldn't happen

      // Both exist — if no base snapshot, fall back to last-write-wins
      if (b == null) {
        resolved.add(
            l.updatedAt.isAfter(r.updatedAt) ? l : r.copyWith(syncedAt: DateTime.now()));
        continue;
      }

      final result = merge(base: b, local: l, remote: r);
      switch (result) {
        case MergeResolved(:final merged):
          resolved.add(merged);
        case MergeConflict():
          conflicts.add(result);
      }
    }

    return MergeBatchResult(resolved: resolved, conflicts: conflicts);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  T _mergeField<T>(String name, T base, T local, T remote,
      Set<String> conflicts) {
    final localChanged = local != base;
    final remoteChanged = remote != base;

    if (!localChanged && !remoteChanged) return base;
    if (localChanged && !remoteChanged) return local;
    if (!localChanged && remoteChanged) return remote;
    // Both changed
    if (local == remote) return local; // same change
    conflicts.add(name);
    return local; // placeholder — caller will handle conflict
  }

  Uint8List? _mergeBlobField(String name, Uint8List? base, Uint8List? local,
      Uint8List? remote, Set<String> conflicts) {
    final localChanged = !_blobEq(local, base);
    final remoteChanged = !_blobEq(remote, base);

    if (!localChanged && !remoteChanged) return base;
    if (localChanged && !remoteChanged) return local;
    if (!localChanged && remoteChanged) return remote;
    // Both changed
    if (_blobEq(local, remote)) return local; // same change
    conflicts.add(name);
    return local; // placeholder
  }

  bool _blobEq(Uint8List? a, Uint8List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return _bytesEq.equals(a, b);
  }

  DateTime? _latestNullable(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}

/// Result of merging multiple items.
class MergeBatchResult {
  final List<VaultEntry> resolved;
  final List<MergeConflict> conflicts;
  const MergeBatchResult({required this.resolved, required this.conflicts});

  bool get hasConflicts => conflicts.isNotEmpty;
}
