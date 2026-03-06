import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cipherowl/features/auth/data/repositories/auth_repository.dart';
import 'package:cipherowl/features/auth/data/services/intruder_snapshot_service.dart';
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/face_track/data/services/background_face_monitor.dart';
import 'package:cipherowl/features/face_track/data/services/face_verification_service.dart';

// â"€â"€ Mocks â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
class MockAuthRepository extends Mock implements AuthRepository {}
class MockIntruderSnapshotService extends Mock implements IntruderSnapshotService {}
class MockBackgroundFaceMonitor extends Mock implements BackgroundFaceMonitor {}
class MockFaceVerificationService extends Mock implements FaceVerificationService {}

void main() {
  late MockAuthRepository mockRepo;
  late MockIntruderSnapshotService mockSnapshotService;
  late MockBackgroundFaceMonitor mockFaceMonitor;
  late MockFaceVerificationService mockFaceVerification;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockSnapshotService = MockIntruderSnapshotService();
    mockFaceMonitor = MockBackgroundFaceMonitor();
    mockFaceVerification = MockFaceVerificationService();
    when(() => mockFaceMonitor.start()).thenAnswer((_) async {});
    when(() => mockFaceMonitor.stop()).thenAnswer((_) async {});
  });

  group('AuthBloc', () {
    // â”€â”€ AuthAppStarted â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('AuthAppStarted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthChecking, AuthLocked] when setup is complete',
        build: () {
          when(() => mockRepo.isSetupComplete()).thenAnswer((_) async => true);
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthAppStarted()),
        expect: () => const [AuthChecking(), AuthLocked()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthChecking, AuthFirstTimeSetup] when setup not done',
        build: () {
          when(() => mockRepo.isSetupComplete()).thenAnswer((_) async => false);
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthAppStarted()),
        expect: () => const [AuthChecking(), AuthFirstTimeSetup()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthChecking, AuthFirstTimeSetup] on repository error',
        build: () {
          when(() => mockRepo.isSetupComplete())
              .thenThrow(Exception('db error'));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthAppStarted()),
        expect: () => const [AuthChecking(), AuthFirstTimeSetup()],
      );
    });

    // â”€â”€ AuthMasterPasswordSubmitted â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('AuthMasterPasswordSubmitted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnlocking, AuthAuthenticated] on correct password',
        build: () {
          when(() => mockRepo.verifyMasterPassword(any()))
              .thenAnswer((_) async => VerifyResult.success());
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) =>
            bloc.add(const AuthMasterPasswordSubmitted('correct123')),
        expect: () => const [AuthUnlocking(), AuthAuthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnlocking, AuthFailed] on wrong password',
        build: () {
          when(() => mockRepo.verifyMasterPassword(any()))
              .thenAnswer((_) async =>
                  VerifyResult.failed(attempts: 1, remainingAttempts: 4));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthMasterPasswordSubmitted('wrong')),
        expect: () => [
          const AuthUnlocking(),
          isA<AuthFailed>()
              .having((s) => s.attempts, 'attempts', 1)
              .having((s) => s.message, 'message', contains('4')),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnlocking, AuthBlocked] when account locked',
        build: () {
          when(() => mockRepo.verifyMasterPassword(any())).thenAnswer((_) async =>
              VerifyResult.locked(const Duration(minutes: 5),
                  isNewLockout: true));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthMasterPasswordSubmitted('wrong')),
        expect: () => [
          const AuthUnlocking(),
          isA<AuthBlocked>().having((s) => s.durationMinutes, 'duration', 5),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'does nothing when password is empty',
        build: () => AuthBloc(authRepository: mockRepo),
        act: (bloc) => bloc.add(const AuthMasterPasswordSubmitted('')),
        expect: () => const <AuthState>[],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnlocking, AuthFailed] on repository exception',
        build: () {
          when(() => mockRepo.verifyMasterPassword(any()))
              .thenThrow(Exception('network'));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthMasterPasswordSubmitted('pass')),
        expect: () => [
          const AuthUnlocking(),
          isA<AuthFailed>().having((s) => s.attempts, 'attempts', 0),
        ],
      );
    });

    // â”€â”€ AuthSetupCompleted â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('AuthSetupCompleted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnlocking, AuthAuthenticated] after saving password',
        build: () {
          when(() => mockRepo.saveMasterPassword(any()))
              .thenAnswer((_) async {});
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) =>
            bloc.add(const AuthSetupCompleted('NewP@ss1!')),
        expect: () => const [AuthUnlocking(), AuthAuthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnlocking, AuthFailed] if save throws',
        build: () {
          when(() => mockRepo.saveMasterPassword(any()))
              .thenThrow(Exception('disk full'));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) =>
            bloc.add(const AuthSetupCompleted('P@ss!')),
        expect: () => [
          const AuthUnlocking(),
          isA<AuthFailed>().having((s) => s.attempts, 'attempts', 0),
        ],
      );
    });

    // â”€â”€ AuthBiometricRequested â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('AuthBiometricRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthBiometricInProgress, AuthAuthenticated] on success',
        build: () {
          when(() => mockRepo.authenticateWithBiometric())
              .thenAnswer((_) async => BiometricResult.success());
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthBiometricRequested()),
        expect: () => const [AuthBiometricInProgress(), AuthAuthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthBiometricInProgress, AuthLocked] on biometric failure',
        build: () {
          when(() => mockRepo.authenticateWithBiometric())
              .thenAnswer((_) async =>
                  BiometricResult.failed('fingerprint mismatch'));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthBiometricRequested()),
        expect: () => const [AuthBiometricInProgress(), AuthLocked()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthBiometricInProgress, AuthBiometricUnavailable] when unavailable',
        build: () {
          when(() => mockRepo.authenticateWithBiometric())
              .thenAnswer((_) async =>
                  BiometricResult.unavailable('no sensor'));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthBiometricRequested()),
        expect: () => [
          const AuthBiometricInProgress(),
          isA<AuthBiometricUnavailable>(),
        ],
      );
    });

    // â”€â”€ AuthVaultLocked / AuthErrorDismissed â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('AuthVaultLocked', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLocked]',
        build: () => AuthBloc(authRepository: mockRepo),
        act: (bloc) => bloc.add(const AuthVaultLocked()),
        expect: () => const [AuthLocked()],
      );
    });

    group('AuthErrorDismissed', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLocked]',
        build: () => AuthBloc(authRepository: mockRepo),
        act: (bloc) => bloc.add(const AuthErrorDismissed()),
        expect: () => const [AuthLocked()],
      );
    });

    // â”€â”€ AuthFido2Requested â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('AuthFido2Requested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthFido2InProgress, AuthAuthenticated] on success',
        build: () {
          when(() => mockRepo.authenticateWithFido2())
              .thenAnswer((_) async =>
                  Fido2AuthResult.success(credentialId: 'cred-1'));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthFido2Requested()),
        expect: () => const [AuthFido2InProgress(), AuthAuthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthFido2InProgress, AuthFido2Error] when no credentials',
        build: () {
          when(() => mockRepo.authenticateWithFido2())
              .thenAnswer((_) async => Fido2AuthResult.noCredentials());
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthFido2Requested()),
        expect: () => [
          const AuthFido2InProgress(),
          isA<AuthFido2Error>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthFido2InProgress, AuthFido2Error] on failed verification',
        build: () {
          when(() => mockRepo.authenticateWithFido2())
              .thenAnswer((_) async => Fido2AuthResult.failed('ط§ظ„طھط­ظ‚ظ‚ ظپط´ظ„'));
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthFido2Requested()),
        expect: () => [
          const AuthFido2InProgress(),
          isA<AuthFido2Error>()
              .having((s) => s.message, 'message', 'ط§ظ„طھط­ظ‚ظ‚ ظپط´ظ„'),
        ],
      );
    });

    // â”€â”€ Duress authentication â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('Duress authentication', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnlocking, AuthDuressAuthenticated] on duress password',
        build: () {
          when(() => mockRepo.verifyMasterPassword(any()))
              .thenAnswer((_) async => VerifyResult.duress());
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) =>
            bloc.add(const AuthMasterPasswordSubmitted('duress123')),
        expect: () => const [AuthUnlocking(), AuthDuressAuthenticated()],
      );
    });

    // â”€â”€ AuthDuressPasswordSet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('AuthDuressPasswordSet', () {
      blocTest<AuthBloc, AuthState>(
        'calls saveDuressPassword with provided password (no state changes)',
        build: () {
          when(() => mockRepo.saveDuressPassword(any()))
              .thenAnswer((_) async {});
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthDuressPasswordSet('secret')),
        expect: () => const <AuthState>[],
        verify: (_) =>
            verify(() => mockRepo.saveDuressPassword('secret')).called(1),
      );

      blocTest<AuthBloc, AuthState>(
        'calls saveDuressPassword with null to clear',
        build: () {
          when(() => mockRepo.saveDuressPassword(any()))
              .thenAnswer((_) async {});
          return AuthBloc(authRepository: mockRepo, faceMonitor: mockFaceMonitor);
        },
        act: (bloc) => bloc.add(const AuthDuressPasswordSet(null)),
        expect: () => const <AuthState>[],
        verify: (_) =>
            verify(() => mockRepo.saveDuressPassword(null)).called(1),
      );
    });

    // â”€â”€ Intruder snapshot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('Intruder snapshot', () {
      blocTest<AuthBloc, AuthState>(
        'calls captureAsync when shouldCaptureSnapshot is true',
        build: () {
          when(() => mockRepo.verifyMasterPassword(any()))
              .thenAnswer((_) async => VerifyResult.failed(
                    attempts: 3,
                    remainingAttempts: 2,
                    shouldCaptureSnapshot: true,
                  ));
          when(() => mockSnapshotService.captureAsync()).thenReturn(null);
          return AuthBloc(
            authRepository: mockRepo,
            snapshotService: mockSnapshotService, faceMonitor: mockFaceMonitor,);
        },
        act: (bloc) => bloc.add(const AuthMasterPasswordSubmitted('wrong')),
        expect: () => [const AuthUnlocking(), isA<AuthFailed>()],
        verify: (_) =>
            verify(() => mockSnapshotService.captureAsync()).called(1),
      );

      blocTest<AuthBloc, AuthState>(
        'does NOT call captureAsync when shouldCaptureSnapshot is false',
        build: () {
          when(() => mockRepo.verifyMasterPassword(any()))
              .thenAnswer((_) async => VerifyResult.failed(
                    attempts: 1,
                    remainingAttempts: 4,
                    shouldCaptureSnapshot: false,
                  ));
          return AuthBloc(
            authRepository: mockRepo,
            snapshotService: mockSnapshotService, faceMonitor: mockFaceMonitor,);
        },
        act: (bloc) => bloc.add(const AuthMasterPasswordSubmitted('wrong')),
        expect: () => [const AuthUnlocking(), isA<AuthFailed>()],
        verify: (_) =>
            verifyNever(() => mockSnapshotService.captureAsync()),
      );
    });

    // ── AuthFaceUnlockRequested ──────────────────────────────────────────────
    group('AuthFaceUnlockRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthFaceUnlockInProgress, AuthAuthenticated] when enrolled + biometric success',
        build: () {
          when(() => mockFaceVerification.hasEnrolledFace())
              .thenAnswer((_) async => true);
          when(() => mockRepo.authenticateWithBiometric())
              .thenAnswer((_) async => BiometricResult.success());
          return AuthBloc(
            authRepository: mockRepo,
            faceMonitor: mockFaceMonitor,
            faceVerification: mockFaceVerification,
          );
        },
        act: (bloc) => bloc.add(const AuthFaceUnlockRequested()),
        expect: () => const [AuthFaceUnlockInProgress(), AuthAuthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthFaceUnlockInProgress, AuthFaceUnlockFailed] when no enrolled face',
        build: () {
          when(() => mockFaceVerification.hasEnrolledFace())
              .thenAnswer((_) async => false);
          return AuthBloc(
            authRepository: mockRepo,
            faceMonitor: mockFaceMonitor,
            faceVerification: mockFaceVerification,
          );
        },
        act: (bloc) => bloc.add(const AuthFaceUnlockRequested()),
        expect: () => [
          const AuthFaceUnlockInProgress(),
          isA<AuthFaceUnlockFailed>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthFaceUnlockInProgress, AuthFaceUnlockFailed] when biometric fails',
        build: () {
          when(() => mockFaceVerification.hasEnrolledFace())
              .thenAnswer((_) async => true);
          when(() => mockRepo.authenticateWithBiometric())
              .thenAnswer((_) async => BiometricResult.failed('mismatch'));
          return AuthBloc(
            authRepository: mockRepo,
            faceMonitor: mockFaceMonitor,
            faceVerification: mockFaceVerification,
          );
        },
        act: (bloc) => bloc.add(const AuthFaceUnlockRequested()),
        expect: () => [
          const AuthFaceUnlockInProgress(),
          isA<AuthFaceUnlockFailed>(),
        ],
      );
    });
  });
}
