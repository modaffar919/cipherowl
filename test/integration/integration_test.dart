// Integration tests — EPIC-15 (cipherowl-8ij)
//
// These tests exercise end-to-end multi-BLoC flows that mirror real user
// journeys: authentication, vault CRUD, security scoring, academy module
// completion flowing XP/badges into GamificationBloc, daily challenges, and
// settings persistence chains.
//
// All platform services (DB, SecureStorage, Rust FFI) are replaced with mocks
// or stubs so the suite runs fully offline in CI.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cipherowl/features/auth/data/repositories/auth_repository.dart';
import 'package:cipherowl/features/auth/data/services/intruder_snapshot_service.dart';
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/vault/data/repositories/vault_repository.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';
import 'package:cipherowl/features/security_center/presentation/bloc/security_bloc.dart';
import 'package:cipherowl/features/settings/data/repositories/settings_repository.dart';
import 'package:cipherowl/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:cipherowl/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:cipherowl/features/academy/presentation/bloc/academy_bloc.dart';
import 'package:cipherowl/features/generator/presentation/bloc/generator_bloc.dart';
import 'package:cipherowl/src/rust/api.dart' show ApiGeneratorConfig;

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

class MockIntruderSnapshotService extends Mock
    implements IntruderSnapshotService {}

class MockVaultRepository extends Mock implements VaultRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class FakeVaultEntry extends Fake implements VaultEntry {}

// ── Stub password generator (avoids Rust FFI in tests) ───────────────────────

String _stubGenerator({required ApiGeneratorConfig config}) {
  final len = config.length.toInt();
  const chars = 'Aa1!Bb2@Cc3#Dd4\$Ee5%Ff6^Gg7&Hh8*Ii9(Jj0)';
  return (chars * ((len ~/ chars.length) + 1)).substring(0, len);
}

// ── Domain helpers ────────────────────────────────────────────────────────────

const _userId = 'local_user';

VaultEntry _entry({
  String id = 'id-1',
  String title = 'Google',
  VaultCategory category = VaultCategory.login,
  int strengthScore = 3,
  bool isFavorite = false,
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime(2025, 6, 1);
  return VaultEntry(
    id: id,
    userId: _userId,
    title: title,
    category: category,
    strengthScore: strengthScore,
    isFavorite: isFavorite,
    createdAt: now,
    updatedAt: now,
  );
}

const _defaultSettings = AppSettings(
  faceTrack: true,
  biometric: true,
  duressMode: false,
  lockTimeout: 5,
  darkWebMonitor: true,
  autoFill: true,
  language: 'ar',
);

// ════════════════════════════════════════════════════════════════════════════
// FLOW 1 — Authentication lifecycle
// ════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    registerFallbackValue(FakeVaultEntry());
  });

  // ── 1. Auth complete lifecycle ─────────────────────────────────────────────
  group('Auth lifecycle flow', () {
    late MockAuthRepository authRepo;
    late MockIntruderSnapshotService snapshotService;

    setUp(() {
      authRepo = MockAuthRepository();
      snapshotService = MockIntruderSnapshotService();
    });

    // 1-a: fresh install → first-time setup
    blocTest<AuthBloc, AuthState>(
      'fresh install: AppStarted → FirstTimeSetup',
      build: () {
        when(() => authRepo.isSetupComplete()).thenAnswer((_) async => false);
        return AuthBloc(
            authRepository: authRepo,
            snapshotService: snapshotService);
      },
      act: (bloc) => bloc.add(const AuthAppStarted()),
      expect: () => [const AuthChecking(), const AuthFirstTimeSetup()],
    );

    // 1-b: returning user → locked
    blocTest<AuthBloc, AuthState>(
      'returning user: AppStarted → Locked',
      build: () {
        when(() => authRepo.isSetupComplete()).thenAnswer((_) async => true);
        return AuthBloc(
            authRepository: authRepo,
            snapshotService: snapshotService);
      },
      act: (bloc) => bloc.add(const AuthAppStarted()),
      expect: () => [const AuthChecking(), const AuthLocked()],
    );

    // 1-c: correct password → authenticated
    blocTest<AuthBloc, AuthState>(
      'correct password: Locked → Authenticated',
      build: () {
        when(() => authRepo.verifyMasterPassword(any()))
            .thenAnswer((_) async => VerifyResult.success());
        return AuthBloc(
            authRepository: authRepo,
            snapshotService: snapshotService);
      },
      act: (bloc) =>
          bloc.add(const AuthMasterPasswordSubmitted('CorrectPass123!')),
      expect: () => [const AuthUnlocking(), const AuthAuthenticated()],
    );

    // 1-d: wrong password → failed with attempt count
    blocTest<AuthBloc, AuthState>(
      'wrong password: AuthFailed carrying attempt count',
      build: () {
        when(() => authRepo.verifyMasterPassword(any())).thenAnswer(
            (_) async =>
                VerifyResult.failed(attempts: 1, remainingAttempts: 4));
        return AuthBloc(
            authRepository: authRepo,
            snapshotService: snapshotService);
      },
      act: (bloc) => bloc.add(const AuthMasterPasswordSubmitted('wrong')),
      expect: () => [
        const AuthUnlocking(),
        isA<AuthFailed>()
            .having((s) => s.attempts, 'attempts', 1),
      ],
    );

    // 1-e: authenticate then lock vault  → Locked
    blocTest<AuthBloc, AuthState>(
      'lock vault after authentication → AuthLocked',
      build: () {
        when(() => authRepo.verifyMasterPassword(any()))
            .thenAnswer((_) async => VerifyResult.success());
        return AuthBloc(
            authRepository: authRepo,
            snapshotService: snapshotService);
      },
      act: (bloc) async {
        bloc.add(const AuthMasterPasswordSubmitted('secret'));
        await Future.delayed(Duration.zero);
        bloc.add(const AuthVaultLocked());
      },
      expect: () => [
        const AuthUnlocking(),
        const AuthAuthenticated(),
        const AuthLocked(),
      ],
    );

    // 1-f: error during startup → fallback to FirstTimeSetup
    blocTest<AuthBloc, AuthState>(
      'repository error on startup → FirstTimeSetup fallback',
      build: () {
        when(() => authRepo.isSetupComplete())
            .thenThrow(Exception('database locked'));
        return AuthBloc(
            authRepository: authRepo,
            snapshotService: snapshotService);
      },
      act: (bloc) => bloc.add(const AuthAppStarted()),
      expect: () => [const AuthChecking(), const AuthFirstTimeSetup()],
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // FLOW 2 — Vault CRUD pipeline
  // ════════════════════════════════════════════════════════════════════════════

  group('Vault CRUD pipeline', () {
    late MockVaultRepository vaultRepo;
    late StreamController<List<VaultEntry>> stream;

    setUp(() {
      vaultRepo = MockVaultRepository();
      stream = StreamController<List<VaultEntry>>.broadcast();
      when(() => vaultRepo.watchItems(any()))
          .thenAnswer((_) => stream.stream);
      when(() => vaultRepo.addItem(any()))
          .thenAnswer((_) async => _entry());
      when(() => vaultRepo.updateItem(any())).thenAnswer((_) async {});
      when(() => vaultRepo.deleteItem(any())).thenAnswer((_) async {});
      when(() => vaultRepo.toggleFavorite(any(), value: any(named: 'value')))
          .thenAnswer((_) async {});
    });

    tearDown(() => stream.close());

    // 2-a: start → items received → VaultLoaded
    blocTest<VaultBloc, VaultState>(
      'start: emits VaultLoading then VaultLoaded when items arrive',
      build: () => VaultBloc(repository: vaultRepo),
      act: (bloc) async {
        bloc.add(const VaultStarted(_userId));
        await Future.delayed(Duration.zero);
        stream.add([_entry()]);
      },
      expect: () => [
        const VaultLoading(),
        isA<VaultLoaded>()
            .having((s) => s.allItems.length, 'item count', 1),
      ],
    );

    // 2-b: search filters items
    blocTest<VaultBloc, VaultState>(
      'search: VaultSearchChanged narrows displayed items',
      build: () => VaultBloc(repository: vaultRepo),
      act: (bloc) async {
        bloc.add(const VaultStarted(_userId));
        await Future.delayed(Duration.zero);
        stream.add([
          _entry(id: 'a', title: 'Google'),
          _entry(id: 'b', title: 'Amazon'),
          _entry(id: 'c', title: 'GitHub'),
        ]);
        await Future.delayed(Duration.zero);
        bloc.add(const VaultSearchChanged('git'));
      },
      skip: 2, // VaultLoading + VaultLoaded
      expect: () => [
        isA<VaultLoaded>()
            .having((s) => s.filteredItems.length, 'filtered count', 1)
            .having(
                (s) => s.filteredItems.first.title, 'matched title', 'GitHub'),
      ],
    );

    // 2-c: category filter
    blocTest<VaultBloc, VaultState>(
      'category filter: VaultCategoryChanged shows only matching items',
      build: () => VaultBloc(repository: vaultRepo),
      act: (bloc) async {
        bloc.add(const VaultStarted(_userId));
        await Future.delayed(Duration.zero);
        stream.add([
          _entry(id: 'login1', title: 'Gmail', category: VaultCategory.login),
          _entry(id: 'card1', title: 'Visa', category: VaultCategory.card),
          _entry(id: 'login2', title: 'Slack', category: VaultCategory.login),
        ]);
        await Future.delayed(Duration.zero);
        bloc.add(const VaultCategoryChanged('card'));
      },
      skip: 2,
      expect: () => [
        isA<VaultLoaded>()
            .having((s) => s.filteredItems.length, 'card count', 1)
            .having(
                (s) => s.filteredItems.first.title, 'matched title', 'Visa'),
      ],
    );

    // 2-d: favorite toggle
    blocTest<VaultBloc, VaultState>(
      'favorite toggle: VaultFavoriteToggled calls repository.toggleFavorite',
      build: () => VaultBloc(repository: vaultRepo),
      act: (bloc) async {
        bloc.add(const VaultStarted(_userId));
        await Future.delayed(Duration.zero);
        stream.add([_entry()]);
        await Future.delayed(Duration.zero);
        bloc.add(const VaultFavoriteToggled('id-1', isFavorite: true));
      },
      verify: (_) {
        verify(() => vaultRepo.toggleFavorite('id-1', value: true)).called(1);
      },
    );

    // 2-e: delete item calls repo
    blocTest<VaultBloc, VaultState>(
      'delete: VaultItemDeleted calls repository deleteItem',
      build: () => VaultBloc(repository: vaultRepo),
      act: (bloc) async {
        bloc.add(const VaultStarted(_userId));
        await Future.delayed(Duration.zero);
        stream.add([_entry()]);
        await Future.delayed(Duration.zero);
        bloc.add(const VaultItemDeleted('id-1'));
      },
      verify: (_) {
        verify(() => vaultRepo.deleteItem('id-1')).called(1);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // FLOW 3 — Security score reflects vault strength
  // ════════════════════════════════════════════════════════════════════════════

  group('Security score pipeline', () {
    // 3-a: all strong items → high score
    // L1=40(all strong) + L2=0(no TOTP) + L3=15(fresh) + L4=15 + L5=3 + L6=5 = 78 ≥ 70
    blocTest<SecurityBloc, SecurityState>(
      'all strong recent passwords: score ≥ 70',
      build: SecurityBloc.new,
      act: (bloc) => bloc.add(SecurityScoreRequested(
        List.generate(5,
            (i) => _entry(id: 'strong-$i', strengthScore: 4,
                updatedAt: DateTime.now())),
      )),
      expect: () => [
        const SecurityCalculating(),
        isA<SecurityLoaded>()
            .having((s) => s.score, 'score', greaterThanOrEqualTo(70))
            .having((s) => s.weakPasswordCount, 'weakPasswordCount', 0),
      ],
    );

    // 3-b: all weak items → low score
    blocTest<SecurityBloc, SecurityState>(
      'all weak passwords: score < 50 and recommendations generated',
      build: SecurityBloc.new,
      act: (bloc) => bloc.add(SecurityScoreRequested(
        List.generate(
            5, (i) => _entry(id: 'weak-$i', strengthScore: 0)),
      )),
      expect: () => [
        const SecurityCalculating(),
        isA<SecurityLoaded>()
            .having((s) => s.score, 'score', lessThan(50))
            .having(
                (s) => s.weakPasswordCount, 'weakPasswordCount', greaterThan(0))
            .having((s) => s.recommendations.isNotEmpty, 'has recommendations',
                true),
      ],
    );

    // 3-c: vault update re-calculates (SecurityVaultUpdated)
    blocTest<SecurityBloc, SecurityState>(
      'vault update: SecurityVaultUpdated recalculates score upwards',
      build: SecurityBloc.new,
      act: (bloc) async {
        bloc.add(SecurityScoreRequested(
            [_entry(id: 'w', strengthScore: 0)])); // low score
        await Future.delayed(Duration.zero);
        // Upgrade to all fresh strong items
        bloc.add(SecurityVaultUpdated(
            List.generate(5, (i) =>
                _entry(id: 's$i', strengthScore: 4, updatedAt: DateTime.now()))));
      },
      skip: 2, // Calculating + first Loaded
      expect: () => [
        isA<SecurityLoaded>()
            .having((s) => s.score, 'score after upgrade',
                greaterThanOrEqualTo(70)),
      ],
    );

    // 3-d: completing a recommendation removes it and accumulates XP
    blocTest<SecurityBloc, SecurityState>(
      'recommendation completed: removed from list and XP accumulated',
      build: SecurityBloc.new,
      act: (bloc) async {
        bloc.add(SecurityScoreRequested(
            List.generate(3, (i) => _entry(id: 'w$i', strengthScore: 0))));
        await Future.delayed(Duration.zero);
        final loaded = bloc.state as SecurityLoaded;
        if (loaded.recommendations.isNotEmpty) {
          final rec = loaded.recommendations.first;
          bloc.add(SecurityRecommendationCompleted(
            recommendationId: rec.id,
            xpReward: 25,
          ));
        }
      },
      skip: 2,
      expect: () => [
        isA<SecurityLoaded>()
            .having((s) => s.sessionXpEarned, 'sessionXpEarned', 25),
      ],
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // FLOW 4 — Academy → Gamification cross-BLoC XP/badge bridge
  // ════════════════════════════════════════════════════════════════════════════

  group('Academy ↔ Gamification integration', () {
    setUp(() {
      // AcademyBloc calls SharedPreferences — provide empty mock storage.
      SharedPreferences.setMockInitialValues({});
    });

    // 4-a: completing a module awards XP to GamificationBloc
    test('completing a module awards XP to GamificationBloc', () async {
      final gamBloc = GamificationBloc()..add(const GamificationStarted());
      await Future.delayed(Duration.zero);

      final acadBloc = AcademyBloc(gamificationBloc: gamBloc)
        ..add(const AcademyStarted());
      await Future.delayed(Duration.zero);

      // Open phishing module and complete it
      acadBloc.add(const AcademyModuleOpened('mod_phishing'));
      await Future.delayed(Duration.zero);
      acadBloc.add(const AcademyModuleCompleted('mod_phishing'));
      await Future.delayed(Duration.zero);

      final gamState = gamBloc.state;
      expect(gamState, isA<GamificationLoaded>());
      // mod_phishing awards 50 XP
      expect((gamState as GamificationLoaded).xp, greaterThanOrEqualTo(50));

      await acadBloc.close();
      await gamBloc.close();
    });

    // 4-b: completing a module with badgeId unlocks the badge
    test('completing phishing module unlocks badge_academy_phishing', () async {
      final gamBloc = GamificationBloc()..add(const GamificationStarted());
      await Future.delayed(Duration.zero);

      final acadBloc = AcademyBloc(gamificationBloc: gamBloc)
        ..add(const AcademyStarted());
      await Future.delayed(Duration.zero);

      acadBloc.add(const AcademyModuleOpened('mod_phishing'));
      await Future.delayed(Duration.zero);
      acadBloc.add(const AcademyModuleCompleted('mod_phishing'));
      await Future.delayed(Duration.zero);

      final gamState = gamBloc.state as GamificationLoaded;
      final badge = gamState.badges.firstWhere(
          (b) => b.id == 'badge_academy_phishing',
          orElse: () => throw StateError('badge not found'));
      expect(badge.isUnlocked, isTrue);

      await acadBloc.close();
      await gamBloc.close();
    });

    // 4-c: completing same module twice doesn't double-award XP
    test('second completion of same module does not re-award XP', () async {
      final gamBloc = GamificationBloc()..add(const GamificationStarted());
      await Future.delayed(Duration.zero);

      final acadBloc = AcademyBloc(gamificationBloc: gamBloc)
        ..add(const AcademyStarted());
      await Future.delayed(Duration.zero);

      // First completion
      acadBloc.add(const AcademyModuleOpened('mod_phishing'));
      await Future.delayed(Duration.zero);
      acadBloc.add(const AcademyModuleCompleted('mod_phishing'));
      await Future.delayed(Duration.zero);
      final xpAfterFirst = (gamBloc.state as GamificationLoaded).xp;

      // Second completion of the same module
      acadBloc.add(const AcademyModuleOpened('mod_phishing'));
      await Future.delayed(Duration.zero);
      acadBloc.add(const AcademyModuleCompleted('mod_phishing'));
      await Future.delayed(Duration.zero);
      final xpAfterSecond = (gamBloc.state as GamificationLoaded).xp;

      expect(xpAfterSecond, equals(xpAfterFirst));

      await acadBloc.close();
      await gamBloc.close();
    });

    // 4-d: completing multiple modules accumulates XP correctly
    test('completing two modules accumulates XP from both', () async {
      final gamBloc = GamificationBloc()..add(const GamificationStarted());
      await Future.delayed(Duration.zero);

      final acadBloc = AcademyBloc(gamificationBloc: gamBloc)
        ..add(const AcademyStarted());
      await Future.delayed(Duration.zero);

      // mod_phishing = 50 XP, mod_malware = 50 XP → 100 XP total
      for (final modId in ['mod_phishing', 'mod_malware']) {
        acadBloc.add(AcademyModuleOpened(modId));
        await Future.delayed(Duration.zero);
        acadBloc.add(AcademyModuleCompleted(modId));
        await Future.delayed(Duration.zero);
      }

      final xp = (gamBloc.state as GamificationLoaded).xp;
      expect(xp, greaterThanOrEqualTo(100));

      await acadBloc.close();
      await gamBloc.close();
    });

    // 4-e: AcademyLoaded tracks completed module count
    test('completed module ids are tracked in AcademyLoaded state', () async {
      SharedPreferences.setMockInitialValues({});
      final gamBloc = GamificationBloc()..add(const GamificationStarted());
      await Future.delayed(Duration.zero);

      final acadBloc = AcademyBloc(gamificationBloc: gamBloc)
        ..add(const AcademyStarted());
      await Future.delayed(Duration.zero);

      acadBloc.add(const AcademyModuleOpened('mod_passwords'));
      await Future.delayed(Duration.zero);
      acadBloc.add(const AcademyModuleCompleted('mod_passwords'));
      await Future.delayed(Duration.zero);

      expect(acadBloc.state, isA<AcademyLoaded>());
      final acadState = acadBloc.state as AcademyLoaded;
      expect(acadState.completedModuleIds, contains('mod_passwords'));
      expect(acadState.completedCount, 1);

      await acadBloc.close();
      await gamBloc.close();
    });

    // 4-f: quiz progress tracked per module
    test('quiz answers are stored per module in quizProgress', () async {
      SharedPreferences.setMockInitialValues({});
      final gamBloc = GamificationBloc()..add(const GamificationStarted());
      final acadBloc = AcademyBloc(gamificationBloc: gamBloc)
        ..add(const AcademyStarted());
      await Future.delayed(Duration.zero);

      acadBloc.add(const AcademyModuleOpened('mod_phishing'));
      await Future.delayed(Duration.zero);

      acadBloc.add(const AcademyQuizAnswered(
          questionIndex: 0, selectedChoice: 1));
      await Future.delayed(Duration.zero);

      final state = acadBloc.state as AcademyLoaded;
      final progress = state.progressFor('mod_phishing');
      expect(progress.answers[0], 1);

      await acadBloc.close();
      await gamBloc.close();
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // FLOW 5 — Daily challenge awards XP
  // ════════════════════════════════════════════════════════════════════════════

  group('Daily challenge → Gamification XP flow', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('answering daily challenge awards XP to GamificationBloc', () async {
      final gamBloc = GamificationBloc()..add(const GamificationStarted());
      await Future.delayed(Duration.zero);
      final xpBefore = (gamBloc.state as GamificationLoaded).xp;

      final acadBloc = AcademyBloc(gamificationBloc: gamBloc)
        ..add(const AcademyStarted());
      await Future.delayed(Duration.zero);

      acadBloc.add(const AcademyDailyChallengeAnswered(0));
      await Future.delayed(Duration.zero);

      final xpAfter = (gamBloc.state as GamificationLoaded).xp;
      expect(xpAfter, greaterThan(xpBefore));

      // AcademyLoaded marks daily challenge as answered
      final acadState = acadBloc.state as AcademyLoaded;
      expect(acadState.dailyChallengeAnswered, isTrue);

      await acadBloc.close();
      await gamBloc.close();
    });

    test('answering daily challenge twice does not double-award XP', () async {
      final gamBloc = GamificationBloc()..add(const GamificationStarted());
      await Future.delayed(Duration.zero);

      final acadBloc = AcademyBloc(gamificationBloc: gamBloc)
        ..add(const AcademyStarted());
      await Future.delayed(Duration.zero);

      acadBloc.add(const AcademyDailyChallengeAnswered(0));
      await Future.delayed(Duration.zero);
      final xpAfterFirst = (gamBloc.state as GamificationLoaded).xp;

      acadBloc.add(const AcademyDailyChallengeAnswered(1));
      await Future.delayed(Duration.zero);
      final xpAfterSecond = (gamBloc.state as GamificationLoaded).xp;

      expect(xpAfterSecond, equals(xpAfterFirst));

      await acadBloc.close();
      await gamBloc.close();
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // FLOW 6 — Settings multi-toggle persistence chain
  // ════════════════════════════════════════════════════════════════════════════

  group('Settings multi-toggle flow', () {
    late MockSettingsRepository settingsRepo;

    setUp(() {
      settingsRepo = MockSettingsRepository();
      when(() => settingsRepo.loadAll())
          .thenAnswer((_) async => _defaultSettings);
      when(() => settingsRepo.setFaceTrack(any())).thenAnswer((_) async {});
      when(() => settingsRepo.setBiometric(any())).thenAnswer((_) async {});
      when(() => settingsRepo.setDuressMode(any())).thenAnswer((_) async {});
      when(() => settingsRepo.setLockTimeout(any())).thenAnswer((_) async {});
      when(() => settingsRepo.setDarkWebMonitor(any()))
          .thenAnswer((_) async {});
      when(() => settingsRepo.setAutoFill(any())).thenAnswer((_) async {});
      when(() => settingsRepo.setLanguage(any())).thenAnswer((_) async {});
    });

    // 6-a: start → loaded → toggle faceTrack → faceTrack flips
    blocTest<SettingsBloc, SettingsState>(
      'load → toggle FaceTrack: faceTrack flipped to false',
      build: () => SettingsBloc(repository: settingsRepo),
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsFaceTrackToggled());
      },
      skip: 2, // SettingsLoading + first SettingsLoaded
      expect: () => [
        isA<SettingsLoaded>().having(
            (s) => s.settings.faceTrack, 'faceTrack toggled', false),
      ],
    );

    // 6-b: change language persists
    blocTest<SettingsBloc, SettingsState>(
      'change language to en → persisted and reflected in state',
      build: () => SettingsBloc(repository: settingsRepo),
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsLanguageChanged('en'));
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.language, 'language', 'en'),
      ],
      verify: (_) {
        verify(() => settingsRepo.setLanguage('en')).called(1);
      },
    );

    // 6-c: lock timeout change persisted
    blocTest<SettingsBloc, SettingsState>(
      'change lock timeout to 15 min → persisted',
      build: () => SettingsBloc(repository: settingsRepo),
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsLockTimeoutChanged(15));
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.lockTimeout, 'lockTimeout', 15),
      ],
      verify: (_) {
        verify(() => settingsRepo.setLockTimeout(15)).called(1);
      },
    );

    // 6-d: multiple toggles in sequence — verify all repo calls
    blocTest<SettingsBloc, SettingsState>(
      'multiple toggles: biometric → duress → autofill all persisted',
      build: () => SettingsBloc(repository: settingsRepo),
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsBiometricToggled());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsDuressModeToggled());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsAutoFillToggled());
      },
      verify: (_) {
        verify(() => settingsRepo.setBiometric(any())).called(1);
        verify(() => settingsRepo.setDuressMode(any())).called(1);
        verify(() => settingsRepo.setAutoFill(any())).called(1);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // FLOW 7 — Generator config round-trip
  // ════════════════════════════════════════════════════════════════════════════

  group('Generator config round-trip', () {
    // 7-a: initial password is non-empty after constructor's auto-refresh
    test('initial state has non-empty generated password', () async {
      final bloc = GeneratorBloc(passwordGenerator: _stubGenerator);
      await Future.delayed(Duration.zero); // let constructor's event process
      expect(bloc.state.password, isNotEmpty);
      bloc.close();
    });

    // 7-b: custom length is honoured
    blocTest<GeneratorBloc, GeneratorState>(
      'length 8 config produces 8-character password',
      build: () => GeneratorBloc(passwordGenerator: _stubGenerator),
      act: (bloc) => bloc.add(const GeneratorConfigUpdated(length: 8)),
      skip: 1, // skip constructor's initial refresh
      expect: () => [
        isA<GeneratorState>()
            .having((s) => s.password.length, 'password.length', 8),
      ],
    );

    // 7-c: refresh generates a new password state
    blocTest<GeneratorBloc, GeneratorState>(
      'refresh: emits updated state',
      build: () => GeneratorBloc(passwordGenerator: _stubGenerator),
      skip: 1,
      act: (bloc) => bloc.add(const GeneratorRefreshRequested()),
      expect: () => [isA<GeneratorState>()],
    );

    // 7-d: length 32 produces 32-character password
    blocTest<GeneratorBloc, GeneratorState>(
      'length 32 config produces 32-character password',
      build: () => GeneratorBloc(passwordGenerator: _stubGenerator),
      act: (bloc) => bloc.add(const GeneratorConfigUpdated(length: 32)),
      skip: 1,
      expect: () => [
        isA<GeneratorState>()
            .having((s) => s.password.length, 'password.length', 32),
      ],
    );

    // 7-e: strength score is computed (>= 0)
    test('generated password always has a valid strength score 0-4', () {
      final bloc = GeneratorBloc(passwordGenerator: _stubGenerator);
      expect(bloc.state.strengthScore, inInclusiveRange(0, 4));
      bloc.close();
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // FLOW 8 — GamificationBloc XP levelling
  // ════════════════════════════════════════════════════════════════════════════

  group('GamificationBloc XP levelling', () {
    // 8-a: XP cross level-2 threshold (500 XP) → level 2
    blocTest<GamificationBloc, GamificationState>(
      'earning 500 XP crosses level 2 threshold',
      build: GamificationBloc.new,
      act: (bloc) async {
        bloc.add(const GamificationStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const GamificationXpEarned(amount: 500, reason: 'test'));
      },
      skip: 1,
      expect: () => [
        isA<GamificationLoaded>()
            .having((s) => s.level, 'level', greaterThanOrEqualTo(2)),
      ],
    );

    // 8-b: daily check-in increments streak
    blocTest<GamificationBloc, GamificationState>(
      'DailyCheckIn increments streak counter',
      build: GamificationBloc.new,
      act: (bloc) async {
        bloc.add(const GamificationStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const GamificationDailyCheckIn());
      },
      skip: 1,
      expect: () => [
        isA<GamificationLoaded>()
            .having((s) => s.streak, 'streak', greaterThanOrEqualTo(1)),
      ],
    );

    // 8-c: manually unlock badge
    blocTest<GamificationBloc, GamificationState>(
      'GamificationBadgeUnlocked marks badge as unlocked',
      build: GamificationBloc.new,
      act: (bloc) async {
        bloc.add(const GamificationStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const GamificationBadgeUnlocked('badge_first_password'));
      },
      skip: 1,
      expect: () => [
        isA<GamificationLoaded>().having(
          (s) =>
              s.badges
                  .firstWhere((b) => b.id == 'badge_first_password')
                  .isUnlocked,
          'badge_first_password.isUnlocked',
          true,
        ),
      ],
    );
  });
}
