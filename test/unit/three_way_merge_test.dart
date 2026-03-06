import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:cipherowl/features/sync/domain/three_way_merge.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';

/// Helper to create a simple VaultEntry for merge testing.
VaultEntry _entry({
  String id = 'item-1',
  String title = 'Test',
  String? username,
  String? url,
  bool isFavorite = false,
  int strengthScore = 3,
  VaultCategory category = VaultCategory.login,
  Uint8List? encryptedPassword,
  Uint8List? encryptedNotes,
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime(2025, 1, 1);
  return VaultEntry(
    id: id,
    userId: 'user-1',
    title: title,
    username: username,
    url: url,
    isFavorite: isFavorite,
    strengthScore: strengthScore,
    category: category,
    encryptedPassword: encryptedPassword,
    encryptedNotes: encryptedNotes,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: now,
  );
}

void main() {
  const engine = ThreeWayMergeEngine();

  group('ThreeWayMergeEngine.merge', () {
    test('no changes → resolved with base values', () {
      final base = _entry(title: 'Gmail', username: 'me@g.com');
      final result = engine.merge(base: base, local: base, remote: base);

      expect(result, isA<MergeResolved>());
      final merged = (result as MergeResolved).merged;
      expect(merged.title, 'Gmail');
      expect(merged.username, 'me@g.com');
    });

    test('only local changed → take local', () {
      final base = _entry(title: 'Gmail');
      final local = base.copyWith(title: 'Gmail Pro');
      final remote = base;

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeResolved>());
      expect((result as MergeResolved).merged.title, 'Gmail Pro');
    });

    test('only remote changed → take remote', () {
      final base = _entry(username: 'old@mail.com');
      final local = base;
      final remote = base.copyWith(username: 'new@mail.com');

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeResolved>());
      expect((result as MergeResolved).merged.username, 'new@mail.com');
    });

    test('both changed same field to same value → resolved', () {
      final base = _entry(title: 'Old');
      final local = base.copyWith(title: 'New');
      final remote = base.copyWith(title: 'New');

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeResolved>());
      expect((result as MergeResolved).merged.title, 'New');
    });

    test('both changed same string field to different values → conflict', () {
      final base = _entry(title: 'Base');
      final local = base.copyWith(title: 'Local Title');
      final remote = base.copyWith(title: 'Remote Title');

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeConflict>());
      final conflict = result as MergeConflict;
      expect(conflict.conflictingFields, contains('title'));
    });

    test('different fields changed → auto resolved', () {
      final base = _entry(title: 'Base', username: 'base@mail.com');
      final local = base.copyWith(title: 'New Title');
      final remote = base.copyWith(username: 'new@mail.com');

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeResolved>());
      final merged = (result as MergeResolved).merged;
      expect(merged.title, 'New Title');
      expect(merged.username, 'new@mail.com');
    });

    test('favorite toggled only on local → resolved', () {
      final base = _entry(isFavorite: false);
      final local = base.copyWith(isFavorite: true);
      final remote = base;

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeResolved>());
      expect((result as MergeResolved).merged.isFavorite, true);
    });

    test('strength score conflict', () {
      final base = _entry(strengthScore: 2);
      final local = base.copyWith(strengthScore: 4);
      final remote = base.copyWith(strengthScore: 1);

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeConflict>());
      expect(
          (result as MergeConflict).conflictingFields, contains('strengthScore'));
    });

    test('category conflict', () {
      final base = _entry(category: VaultCategory.login);
      final local = base.copyWith(category: VaultCategory.card);
      final remote = base.copyWith(category: VaultCategory.identity);

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeConflict>());
      expect((result as MergeConflict).conflictingFields, contains('category'));
    });

    test('blob fields — both changed to same bytes → resolved', () {
      final base = _entry(encryptedPassword: Uint8List.fromList([1, 2, 3]));
      final newPw = Uint8List.fromList([4, 5, 6]);
      final local = base.copyWith(encryptedPassword: newPw);
      final remote = base.copyWith(encryptedPassword: Uint8List.fromList([4, 5, 6]));

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeResolved>());
    });

    test('blob fields — both changed to different bytes → conflict', () {
      final base = _entry(encryptedPassword: Uint8List.fromList([1, 2, 3]));
      final local = base.copyWith(encryptedPassword: Uint8List.fromList([4, 5, 6]));
      final remote = base.copyWith(encryptedPassword: Uint8List.fromList([7, 8, 9]));

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeConflict>());
      expect((result as MergeConflict).conflictingFields,
          contains('encryptedPassword'));
    });

    test('multiple conflicts are all reported', () {
      final base = _entry(title: 'A', username: 'a@a.com', url: 'http://a.com');
      final local = base.copyWith(
          title: 'Local', username: 'local@a.com', url: 'http://local.com');
      final remote = base.copyWith(
          title: 'Remote', username: 'remote@a.com', url: 'http://remote.com');

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeConflict>());
      final conflicts = (result as MergeConflict).conflictingFields;
      expect(conflicts, containsAll(['title', 'username', 'url']));
    });

    test('updatedAt takes latest on resolve', () {
      final base = _entry(updatedAt: DateTime(2025, 1, 1));
      final local = base.copyWith(
          title: 'L', updatedAt: DateTime(2025, 6, 1));
      final remote = base.copyWith(
          username: 'r', updatedAt: DateTime(2025, 3, 1));

      final result = engine.merge(base: base, local: local, remote: remote);
      expect(result, isA<MergeResolved>());
      final merged = (result as MergeResolved).merged;
      expect(merged.updatedAt, DateTime(2025, 6, 1));
    });
  });

  group('ThreeWayMergeEngine.mergeBatch', () {
    test('local-only items are auto-resolved', () {
      final localOnly = _entry(id: 'new-local', title: 'New Local');
      final result = engine.mergeBatch(
        bases: {},
        local: [localOnly],
        remote: [],
      );

      expect(result.resolved, hasLength(1));
      expect(result.resolved.first.title, 'New Local');
      expect(result.hasConflicts, false);
    });

    test('remote-only items are auto-resolved', () {
      final remoteOnly = _entry(id: 'new-remote', title: 'New Remote');
      final result = engine.mergeBatch(
        bases: {},
        local: [],
        remote: [remoteOnly],
      );

      expect(result.resolved, hasLength(1));
      expect(result.resolved.first.title, 'New Remote');
    });

    test('no base snapshot → falls back to last-write-wins', () {
      final local = _entry(
          title: 'Local', updatedAt: DateTime(2025, 6, 1));
      final remote = _entry(
          title: 'Remote', updatedAt: DateTime(2025, 1, 1));

      final result = engine.mergeBatch(
        bases: {}, // no base
        local: [local],
        remote: [remote],
      );

      expect(result.resolved, hasLength(1));
      expect(result.resolved.first.title, 'Local'); // local is newer
    });

    test('with base snapshot → proper 3-way merge', () {
      final base = _entry(title: 'Base', username: 'user@mail.com');
      final local = base.copyWith(title: 'Updated Title');
      final remote = base.copyWith(username: 'new@mail.com');

      final result = engine.mergeBatch(
        bases: {base.id: base},
        local: [local],
        remote: [remote],
      );

      expect(result.resolved, hasLength(1));
      expect(result.hasConflicts, false);
      expect(result.resolved.first.title, 'Updated Title');
      expect(result.resolved.first.username, 'new@mail.com');
    });

    test('batch with mix of resolved and conflicting items', () {
      final baseA = _entry(id: 'a', title: 'A');
      final baseB = _entry(id: 'b', title: 'B');

      final localA = baseA.copyWith(url: 'http://local-a.com');
      final remoteA = baseA; // no change

      final localB = baseB.copyWith(title: 'Local B');
      final remoteB = baseB.copyWith(title: 'Remote B');

      final result = engine.mergeBatch(
        bases: {'a': baseA, 'b': baseB},
        local: [localA, localB],
        remote: [remoteA, remoteB],
      );

      expect(result.resolved, hasLength(1));
      expect(result.resolved.first.id, 'a');
      expect(result.conflicts, hasLength(1));
      expect(result.conflicts.first.conflictingFields, contains('title'));
    });
  });
}
