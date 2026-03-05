import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cipherowl/features/settings/data/repositories/settings_repository.dart';
import 'package:cipherowl/features/settings/presentation/bloc/settings_bloc.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────
class MockSettingsRepository extends Mock implements SettingsRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────
const _defaultSettings = AppSettings(
  faceTrack: true,
  biometric: true,
  duressMode: false,
  lockTimeout: 5,
  darkWebMonitor: true,
  autoFill: true,
  language: 'ar',
);

SettingsBloc _bloc(MockSettingsRepository repo) =>
    SettingsBloc(repository: repo);

void main() {
  late MockSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  // ── SettingsStarted ────────────────────────────────────────────────────────
  group('SettingsStarted', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits [SettingsLoading, SettingsLoaded] with defaults',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        return _bloc(mockRepo);
      },
      act: (bloc) => bloc.add(const SettingsStarted()),
      expect: () => [
        const SettingsLoading(),
        isA<SettingsLoaded>().having(
          (s) => s.settings.language,
          'language defaults to ar',
          'ar',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [SettingsLoading, SettingsError] on repository error',
      build: () {
        when(() => mockRepo.loadAll()).thenThrow(Exception('db locked'));
        return _bloc(mockRepo);
      },
      act: (bloc) => bloc.add(const SettingsStarted()),
      expect: () => [
        const SettingsLoading(),
        isA<SettingsError>(),
      ],
    );
  });

  // ── SettingsFaceTrackToggled ───────────────────────────────────────────────
  group('SettingsFaceTrackToggled', () {
    blocTest<SettingsBloc, SettingsState>(
      'toggles faceTrack from true to false and persists',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setFaceTrack(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsFaceTrackToggled());
      },
      skip: 2, // skip Loading + initial Loaded
      expect: () => [
        isA<SettingsLoaded>().having(
          (s) => s.settings.faceTrack,
          'faceTrack toggled off',
          false,
        ),
      ],
      verify: (_) => verify(() => mockRepo.setFaceTrack(false)).called(1),
    );

    blocTest<SettingsBloc, SettingsState>(
      'does nothing if not yet loaded',
      build: () => _bloc(mockRepo),
      act: (bloc) => bloc.add(const SettingsFaceTrackToggled()),
      expect: () => const <SettingsState>[],
    );
  });

  // ── SettingsBiometricToggled ───────────────────────────────────────────────
  group('SettingsBiometricToggled', () {
    blocTest<SettingsBloc, SettingsState>(
      'toggles biometric and persists',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setBiometric(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsBiometricToggled());
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.biometric, 'biometric', false),
      ],
      verify: (_) => verify(() => mockRepo.setBiometric(false)).called(1),
    );
  });

  // ── SettingsDuressModeToggled ──────────────────────────────────────────────
  group('SettingsDuressModeToggled', () {
    blocTest<SettingsBloc, SettingsState>(
      'toggles duressMode from false to true and persists',
      build: () {
        when(() => mockRepo.loadAll()).thenAnswer((_) async =>
            _defaultSettings.copyWith(duressMode: false));
        when(() => mockRepo.setDuressMode(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsDuressModeToggled());
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.duressMode, 'duressMode', true),
      ],
      verify: (_) => verify(() => mockRepo.setDuressMode(true)).called(1),
    );
  });

  // ── SettingsLockTimeoutChanged ─────────────────────────────────────────────
  group('SettingsLockTimeoutChanged', () {
    blocTest<SettingsBloc, SettingsState>(
      'updates lockTimeout to valid value',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setLockTimeout(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
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
      verify: (_) => verify(() => mockRepo.setLockTimeout(15)).called(1),
    );

    blocTest<SettingsBloc, SettingsState>(
      'clamps lockTimeout to 1 if below minimum',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setLockTimeout(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsLockTimeoutChanged(0));
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.lockTimeout, 'clamped to 1', 1),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'clamps lockTimeout to 60 if above maximum',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setLockTimeout(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsLockTimeoutChanged(999));
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.lockTimeout, 'clamped to 60', 60),
      ],
    );
  });

  // ── SettingsDarkWebToggled ─────────────────────────────────────────────────
  group('SettingsDarkWebToggled', () {
    blocTest<SettingsBloc, SettingsState>(
      'toggles darkWebMonitor and persists',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setDarkWebMonitor(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsDarkWebToggled());
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.darkWebMonitor, 'toggled off', false),
      ],
      verify: (_) => verify(() => mockRepo.setDarkWebMonitor(false)).called(1),
    );
  });

  // ── SettingsAutoFillToggled ────────────────────────────────────────────────
  group('SettingsAutoFillToggled', () {
    blocTest<SettingsBloc, SettingsState>(
      'toggles autoFill and persists',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setAutoFill(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsAutoFillToggled());
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.autoFill, 'toggled off', false),
      ],
      verify: (_) => verify(() => mockRepo.setAutoFill(false)).called(1),
    );
  });

  // ── SettingsLanguageChanged ────────────────────────────────────────────────
  group('SettingsLanguageChanged', () {
    blocTest<SettingsBloc, SettingsState>(
      'changes language from ar to en and persists',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setLanguage(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
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
      verify: (_) => verify(() => mockRepo.setLanguage('en')).called(1),
    );

    blocTest<SettingsBloc, SettingsState>(
      'unknown language code falls back to ar',
      build: () {
        when(() => mockRepo.loadAll())
            .thenAnswer((_) async => _defaultSettings);
        when(() => mockRepo.setLanguage(any())).thenAnswer((_) async {});
        return _bloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const SettingsLanguageChanged('fr'));
      },
      skip: 2,
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.settings.language, 'fallback to ar', 'ar'),
      ],
      verify: (_) => verify(() => mockRepo.setLanguage('ar')).called(1),
    );
  });

  // ── AppSettings.copyWith ───────────────────────────────────────────────────
  group('AppSettings', () {
    test('copyWith only changes specified fields', () {
      const s = AppSettings(
        faceTrack: true,
        biometric: true,
        duressMode: false,
        lockTimeout: 5,
        darkWebMonitor: true,
        autoFill: true,
        language: 'ar',
      );
      final updated = s.copyWith(language: 'en', lockTimeout: 10);
      expect(updated.language, 'en');
      expect(updated.lockTimeout, 10);
      expect(updated.faceTrack, true); // unchanged
      expect(updated.biometric, true); // unchanged
    });
  });
}
