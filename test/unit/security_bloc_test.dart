import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cipherowl/features/security_center/presentation/bloc/security_bloc.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
VaultEntry _loginEntry({
  String id = 'id-1',
  int strengthScore = 3,
  bool hasTotp = false,
  DateTime? updatedAt,
}) {
  final dt = updatedAt ?? DateTime.now();
  return VaultEntry(
    id: id,
    userId: 'local_user',
    title: 'Test Entry',
    category: VaultCategory.login,
    strengthScore: strengthScore,
    isFavorite: false,
    encryptedTotpSecret: hasTotp ? Uint8List(1) : null,
    createdAt: dt,
    updatedAt: dt,
  );
}

void main() {
  group('SecurityBloc', () {
    // ── Initial state ───────────────────────────────────────────────────────
    test('initial state is SecurityInitial', () {
      final bloc = SecurityBloc();
      expect(bloc.state, isA<SecurityInitial>());
      bloc.close();
    });

    // ── SecurityScoreRequested ──────────────────────────────────────────────
    group('SecurityScoreRequested', () {
      blocTest<SecurityBloc, SecurityState>(
        'emits [SecurityCalculating, SecurityLoaded] for empty vault',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(const SecurityScoreRequested([])),
        expect: () => [
          const SecurityCalculating(),
          isA<SecurityLoaded>()
              .having((s) => s.score, 'score >= 0', greaterThanOrEqualTo(0))
              .having((s) => s.layers.length, 'layers', 6),
        ],
      );

      blocTest<SecurityBloc, SecurityState>(
        'total score = l1+l2+l3+15+3+5 for empty vault (no items)',
        // l1=32 (default when no items), l2=10, l3=15, l4=15, l5=3, l6=5 = 80
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(const SecurityScoreRequested([])),
        skip: 1, // skip SecurityCalculating
        expect: () => [
          isA<SecurityLoaded>().having((s) => s.score, 'empty vault score', 80),
        ],
      );

      blocTest<SecurityBloc, SecurityState>(
        'score is higher when all items have strong passwords',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([
          _loginEntry(id: '1', strengthScore: 4),
          _loginEntry(id: '2', strengthScore: 4),
          _loginEntry(id: '3', strengthScore: 3),
        ])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>()
              .having((s) => s.score, 'high score', greaterThan(60)),
        ],
      );

      blocTest<SecurityBloc, SecurityState>(
        'score is lower when all items have weak passwords',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([
          _loginEntry(id: '1', strengthScore: 0),
          _loginEntry(id: '2', strengthScore: 0),
          _loginEntry(id: '3', strengthScore: 1),
        ])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>()
              .having((s) => s.score, 'low score', lessThan(70))
              .having((s) => s.weakPasswordCount, 'weakPasswordCount', 3),
        ],
      );

      blocTest<SecurityBloc, SecurityState>(
        'counts noTotpCount for login items without TOTP',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([
          _loginEntry(id: '1', hasTotp: false),
          _loginEntry(id: '2', hasTotp: false),
          _loginEntry(id: '3', hasTotp: true),
        ])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>()
              .having((s) => s.noTotpCount, 'noTotpCount', 2),
        ],
      );

      blocTest<SecurityBloc, SecurityState>(
        'counts stalePasswordCount for entries older than 90 days',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([
          _loginEntry(
              id: '1',
              updatedAt: DateTime.now().subtract(const Duration(days: 100))),
          _loginEntry(id: '2', updatedAt: DateTime.now()),
        ])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>()
              .having((s) => s.stalePasswordCount, 'stalePasswordCount', 1),
        ],
      );
    });

    // ── SecurityVaultUpdated ────────────────────────────────────────────────
    group('SecurityVaultUpdated', () {
      blocTest<SecurityBloc, SecurityState>(
        'emits SecurityLoaded directly (no SecurityCalculating)',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityVaultUpdated([
          _loginEntry(id: '1', strengthScore: 4),
        ])),
        expect: () => [isA<SecurityLoaded>()],
      );

      blocTest<SecurityBloc, SecurityState>(
        'recalculates correctly when vault changes',
        build: SecurityBloc.new,
        act: (bloc) async {
          bloc.add(const SecurityScoreRequested([]));
          await Future.delayed(Duration.zero);
          bloc.add(SecurityVaultUpdated([
            _loginEntry(id: '1', strengthScore: 0),
            _loginEntry(id: '2', strengthScore: 0),
          ]));
        },
        skip: 2, // skip SecurityCalculating + first SecurityLoaded (empty)
        expect: () => [
          isA<SecurityLoaded>()
              .having((s) => s.weakPasswordCount, 'weakPasswordCount', 2),
        ],
      );
    });

    // ── Grade boundaries ────────────────────────────────────────────────────
    group('grade boundaries', () {
      test('grade is correct across all tier items', () async {
        // All strong passwords, all with TOTP, all fresh → score ~83
        final bloc = SecurityBloc();
        final items = List.generate(
          5,
          (i) => _loginEntry(id: 'id-$i', strengthScore: 4, hasTotp: true),
        );
        bloc.add(SecurityScoreRequested(items));
        await Future.delayed(Duration.zero);
        final state = bloc.state as SecurityLoaded;
        expect(state.score, greaterThanOrEqualTo(60));
        expect(state.grade, isNotEmpty);
        await bloc.close();
      });
    });

    // ── Layer structure ─────────────────────────────────────────────────────
    group('SecurityLoaded layer structure', () {
      blocTest<SecurityBloc, SecurityState>(
        'always emits exactly 6 layers',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([_loginEntry()])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>()
              .having((s) => s.layers.length, '6 layers', 6),
        ],
      );

      blocTest<SecurityBloc, SecurityState>(
        'layer 4 (encryption) always earns 15 pts',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([_loginEntry()])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>().having(
            (s) => s.layers[3].earnedPoints,
            'layer 4 earnedPoints',
            15,
          ),
        ],
      );

      blocTest<SecurityBloc, SecurityState>(
        'layer 6 (breach monitoring) always earns 5 pts',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([_loginEntry()])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>().having(
            (s) => s.layers[5].earnedPoints,
            'layer 6 earnedPoints',
            5,
          ),
        ],
      );
    });

    // ── Recommendations ─────────────────────────────────────────────────────
    group('recommendations', () {
      blocTest<SecurityBloc, SecurityState>(
        'generates recommendations for weak passwords',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([
          _loginEntry(id: '1', strengthScore: 0),
          _loginEntry(id: '2', strengthScore: 0),
        ])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>()
              .having((s) => s.recommendations, 'recommendations not empty',
                  isNotEmpty),
        ],
      );

      blocTest<SecurityBloc, SecurityState>(
        'shows congratulations recommendation for a perfect vault',
        build: SecurityBloc.new,
        act: (bloc) => bloc.add(SecurityScoreRequested([
          _loginEntry(id: '1', strengthScore: 4, hasTotp: true),
          _loginEntry(id: '2', strengthScore: 4, hasTotp: true),
        ])),
        skip: 1,
        expect: () => [
          isA<SecurityLoaded>().having(
            (s) => s.recommendations.length,
            'exactly 1 congrats recommendation',
            1,
          ),
        ],
      );
    });
  });
}
