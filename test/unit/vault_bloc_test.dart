import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cipherowl/features/vault/data/repositories/vault_repository.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────
class MockVaultRepository extends Mock implements VaultRepository {}

class FakeVaultEntry extends Fake implements VaultEntry {}

// ── Helpers ───────────────────────────────────────────────────────────────────
VaultEntry _entry({
  String id = 'id-1',
  String title = 'Google',
  VaultCategory category = VaultCategory.login,
  int strengthScore = 3,
  bool isFavorite = false,
}) {
  final now = DateTime(2024, 1, 15);
  return VaultEntry(
    id: id,
    userId: 'local_user',
    title: title,
    category: category,
    strengthScore: strengthScore,
    isFavorite: isFavorite,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockVaultRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeVaultEntry());
  });

  setUp(() {
    mockRepo = MockVaultRepository();
  });

  // ── VaultStarted ───────────────────────────────────────────────────────────
  group('VaultStarted', () {
    blocTest<VaultBloc, VaultState>(
      'emits [VaultLoading, VaultLoaded] on first items emission',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry()]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const VaultStarted('local_user')),
      expect: () => [
        const VaultLoading(),
        isA<VaultLoaded>()
            .having((s) => s.allItems.length, 'items length', 1)
            .having((s) => s.searchQuery, 'searchQuery', ''),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      'emits [VaultLoading, VaultLoaded(empty)] when vault is empty',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const VaultStarted('local_user')),
      expect: () => [
        const VaultLoading(),
        isA<VaultLoaded>().having((s) => s.allItems, 'empty', []),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      'emits [VaultLoading, VaultLoaded(empty)] when stream throws (fallback)',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.error(Exception('DB unavailable')));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const VaultStarted('local_user')),
      expect: () => [
        const VaultLoading(),
        isA<VaultLoaded>().having((s) => s.allItems, 'fallback empty', []),
      ],
    );
  });

  // ── VaultSearchChanged ─────────────────────────────────────────────────────
  group('VaultSearchChanged', () {
    blocTest<VaultBloc, VaultState>(
      'filters items by search query (case-insensitive)',
      build: () {
        when(() => mockRepo.watchItems(any())).thenAnswer((_) => Stream.value([
              _entry(id: '1', title: 'Google'),
              _entry(id: '2', title: 'GitHub'),
              _entry(id: '3', title: 'Netflix'),
            ]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultSearchChanged('git'));
      },
      skip: 2, // skip VaultLoading + first VaultLoaded
      expect: () => [
        isA<VaultLoaded>().having(
          (s) => s.filteredItems.map((e) => e.title).toList(),
          'filteredItems',
          ['GitHub'],
        ),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      'returns all items when query cleared',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry(), _entry(id: '2')]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultSearchChanged('g'));
        bloc.add(const VaultSearchChanged(''));
      },
      skip: 2,
      expect: () => [
        isA<VaultLoaded>(),
        isA<VaultLoaded>()
            .having((s) => s.filteredItems.length, 'all items', 2),
      ],
    );
  });

  // ── VaultCategoryChanged ───────────────────────────────────────────────────
  group('VaultCategoryChanged', () {
    blocTest<VaultBloc, VaultState>(
      'filters to selected category',
      build: () {
        when(() => mockRepo.watchItems(any())).thenAnswer((_) => Stream.value([
              _entry(id: '1', category: VaultCategory.login),
              _entry(id: '2', category: VaultCategory.card),
            ]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultCategoryChanged('card'));
      },
      skip: 2,
      expect: () => [
        isA<VaultLoaded>().having(
          (s) => s.filteredItems.every((e) => e.category == VaultCategory.card),
          'only cards',
          true,
        ),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      'toggling same category again clears filter (shows all items)',
      build: () {
        when(() => mockRepo.watchItems(any())).thenAnswer((_) => Stream.value([
              _entry(id: '1', category: VaultCategory.login),
              _entry(id: '2', category: VaultCategory.card),
            ]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultCategoryChanged('card'));
        bloc.add(const VaultCategoryChanged('card')); // toggle off
      },
      skip: 3,
      expect: () => [
        isA<VaultLoaded>()
            .having((s) => s.filteredItems.length, 'all items', 2),
      ],
    );
  });

  // ── VaultItemAdded ─────────────────────────────────────────────────────────
  group('VaultItemAdded', () {
    blocTest<VaultBloc, VaultState>(
      'calls repository addItem and emits operating state',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockRepo.addItem(any()))
            .thenAnswer((_) async => _entry());
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(VaultItemAdded(_entry()));
      },
      skip: 2,
      verify: (_) => verify(() => mockRepo.addItem(any())).called(1),
    );
  });

  // ── VaultItemDeleted ───────────────────────────────────────────────────────
  group('VaultItemDeleted', () {
    blocTest<VaultBloc, VaultState>(
      'calls repository deleteItem',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry()]));
        when(() => mockRepo.deleteItem(any())).thenAnswer((_) async {});
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultItemDeleted('id-1'));
      },
      skip: 2,
      verify: (_) => verify(() => mockRepo.deleteItem('id-1')).called(1),
    );
  });

  // ── VaultItemUpdated ───────────────────────────────────────────────────────
  group('VaultItemUpdated', () {
    blocTest<VaultBloc, VaultState>(
      'calls repository updateItem',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry()]));
        when(() => mockRepo.updateItem(any())).thenAnswer((_) async {});
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(VaultItemUpdated(_entry(title: 'Google Updated')));
      },
      skip: 2,
      verify: (_) => verify(() => mockRepo.updateItem(any())).called(1),
    );
  });

  group('VaultFavoriteToggled', () {
    blocTest<VaultBloc, VaultState>(
      'calls repository toggleFavorite with correct id and value',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry(isFavorite: false)]));
        when(() => mockRepo.toggleFavorite(any(), value: any(named: 'value')))
            .thenAnswer((_) async {});
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultFavoriteToggled('id-1', isFavorite: true));
      },
      skip: 2,
      verify: (_) => verify(
        () => mockRepo.toggleFavorite('id-1', value: true),
      ).called(1),
    );
  });

  group('VaultMessageDismissed', () {
    blocTest<VaultBloc, VaultState>(
      'clears message from loaded state',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry()]));
        when(() => mockRepo.addItem(any()))
            .thenAnswer((_) async => _entry());
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(VaultItemAdded(_entry()));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultMessageDismissed());
      },
      skip: 4, // skip Loading + Loaded + isOperating + hasMessage
      expect: () => [
        isA<VaultLoaded>()
            .having((s) => s.message, 'message cleared', isNull),
      ],
    );
  });

  // ── VaultItemsImported ─────────────────────────────────────────────────────
  group('VaultItemsImported', () {
    blocTest<VaultBloc, VaultState>(
      'calls addItem for each imported entry',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockRepo.addItem(any()))
            .thenAnswer((inv) async => inv.positionalArguments[0] as VaultEntry);
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(VaultItemsImported([
          _entry(id: 'a', title: 'A'),
          _entry(id: 'b', title: 'B'),
        ]));
      },
      skip: 2,
      verify: (_) => verify(() => mockRepo.addItem(any())).called(2),
    );
  });

  // ── VaultDuressActivated ───────────────────────────────────────────────────
  group('VaultDuressActivated', () {
    blocTest<VaultBloc, VaultState>(
      'emits VaultLoaded with isDuress=true and decoy items',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry()]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultDuressActivated());
      },
      skip: 2,
      expect: () => [
        isA<VaultLoaded>()
            .having((s) => s.isDuress, 'isDuress', true)
            .having((s) => s.allItems.isNotEmpty, 'has decoy items', true),
      ],
    );
  });

  // ── Duress mode CRUD guards ────────────────────────────────────────────────
  group('Duress mode silent CRUD guards', () {
    blocTest<VaultBloc, VaultState>(
      'VaultItemAdded in duress mode emits success but never calls repo',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry()]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultDuressActivated());
        await Future.delayed(Duration.zero);
        bloc.add(VaultItemAdded(_entry(id: 'new-1', title: 'Fake')));
      },
      skip: 3, // VaultLoading + VaultLoaded + duress VaultLoaded
      expect: () => [
        isA<VaultLoaded>()
            .having((s) => s.isDuress, 'still duress', true)
            .having((s) => s.message, 'success msg', contains('✓')),
      ],
      verify: (_) => verifyNever(() => mockRepo.addItem(any())),
    );

    blocTest<VaultBloc, VaultState>(
      'VaultItemUpdated in duress mode emits success but never calls repo',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry()]));
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultDuressActivated());
        await Future.delayed(Duration.zero);
        bloc.add(VaultItemUpdated(_entry(title: 'Changed')));
      },
      skip: 3,
      expect: () => [
        isA<VaultLoaded>()
            .having((s) => s.isDuress, 'still duress', true)
            .having((s) => s.message, 'success msg', contains('✓')),
      ],
      verify: (_) => verifyNever(() => mockRepo.updateItem(any())),
    );

    blocTest<VaultBloc, VaultState>(
      'VaultItemDeleted in duress mode emits success but never calls repo',
      build: () {
        when(() => mockRepo.watchItems(any()))
            .thenAnswer((_) => Stream.value([_entry()]));
        when(() => mockRepo.deleteItem(any())).thenAnswer((_) async {});
        return VaultBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const VaultStarted('local_user'));
        await Future.delayed(Duration.zero);
        bloc.add(const VaultDuressActivated());
        await Future.delayed(Duration.zero);
        bloc.add(const VaultItemDeleted('decoy-1'));
      },
      skip: 3,
      expect: () => [
        isA<VaultLoaded>()
            .having((s) => s.isDuress, 'still duress', true)
            .having((s) => s.message, 'msg set', isNotNull),
      ],
      verify: (_) => verifyNever(() => mockRepo.deleteItem(any())),
    );
  });

  // ── securityScore computed property ───────────────────────────────────────
  group('VaultLoaded.securityScore', () {
    test('returns 100 for empty vault', () {
      final state = VaultLoaded(allItems: const []);
      expect(state.securityScore, 100);
    });

    test('returns proportional score based on strength', () {
      final state = VaultLoaded(allItems: [
        _entry(strengthScore: 4), // max
        _entry(id: '2', strengthScore: 0), // min
      ]);
      // (4 + 0) / (2 * 4) * 100 = 50
      expect(state.securityScore, 50);
    });

    test('counts weak items correctly', () {
      final state = VaultLoaded(allItems: [
        _entry(strengthScore: 0),
        _entry(id: '2', strengthScore: 1),
        _entry(id: '3', strengthScore: 4),
      ]);
      expect(state.weakItemCount, 2);
    });
  });

  // ── VaultLoaded.isDuress state property ─────────────────────────────────────
  group('VaultLoaded.isDuress', () {
    test('defaults to false', () {
      final state = VaultLoaded(allItems: const []);
      expect(state.isDuress, isFalse);
    });

    test('copyWith preserves isDuress when not overridden', () {
      const state = VaultLoaded(allItems: [], isDuress: true);
      final copied = state.copyWith(searchQuery: 'test');
      expect(copied.isDuress, isTrue);
    });

    test('copyWith can set isDuress', () {
      const state = VaultLoaded(allItems: []);
      final copied = state.copyWith(isDuress: true);
      expect(copied.isDuress, isTrue);
    });
  });
}
