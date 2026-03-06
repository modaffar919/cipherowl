import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../face_track/data/services/background_face_monitor.dart';
import '../../../face_track/data/services/face_verification_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/intruder_snapshot_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final IntruderSnapshotService _snapshotService;
  final FaceVerificationService _faceVerification;
  BackgroundFaceMonitor? _faceMonitor;

  AuthBloc({
    AuthRepository? authRepository,
    IntruderSnapshotService? snapshotService,
    BackgroundFaceMonitor? faceMonitor,
    FaceVerificationService? faceVerification,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _snapshotService = snapshotService ?? IntruderSnapshotService(),
        _faceVerification = faceVerification ?? FaceVerificationService(),
        _faceMonitor = faceMonitor,
        super(const AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthMasterPasswordSubmitted>(_onMasterPasswordSubmitted);
    on<AuthBiometricRequested>(_onBiometricRequested);
    on<AuthFaceUnlockRequested>(_onFaceUnlockRequested);
    on<AuthFido2Requested>(_onFido2Requested);
    on<AuthDuressPasswordSet>(_onDuressPasswordSet);
    on<AuthSetupCompleted>(_onSetupCompleted);
    on<AuthVaultLocked>(_onVaultLocked);
    on<AuthErrorDismissed>(_onErrorDismissed);
  }

  // ── Handlers ─────────────────────────────────────────────

  Future<void> _onAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthChecking());
    try {
      final isSetup = await _authRepository.isSetupComplete();
      if (isSetup) {
        emit(const AuthLocked());
      } else {
        emit(const AuthFirstTimeSetup());
      }
    } catch (e) {
      // On any DB error, fallback to first-time setup
      emit(const AuthFirstTimeSetup());
    }
  }

  Future<void> _onMasterPasswordSubmitted(
    AuthMasterPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (event.password.isEmpty) return;

    emit(const AuthUnlocking());

    try {
      final result = await _authRepository.verifyMasterPassword(event.password);

      switch (result.status) {
        case VerifyStatus.success:
          emit(const AuthAuthenticated());
          _startFaceMonitor();

        case VerifyStatus.duress:
          // Duress password — open decoy (empty) vault, don't reveal real data
          emit(const AuthDuressAuthenticated());

        case VerifyStatus.failed:
          // Trigger intruder snapshot if threshold reached
          if (result.shouldCaptureSnapshot) {
            _snapshotService.captureAsync();
          }
          emit(AuthFailed(
            message: result.remainingAttempts > 0
                ? 'كلمة المرور غير صحيحة — تبقى ${result.remainingAttempts} محاولة'
                : 'كلمة المرور غير صحيحة',
            attempts: result.attempts,
          ));

        case VerifyStatus.locked:
          final totalMinutes =
              result.lockDuration?.inMinutes ?? 5;
          emit(AuthBlocked(
            unblockAt: DateTime.now().add(result.lockDuration!),
            durationMinutes: totalMinutes,
          ));

        case VerifyStatus.error:
          emit(AuthFailed(
            message: result.errorMessage ?? 'خطأ غير معروف',
            attempts: 0,
          ));
      }
    } catch (e) {
      emit(AuthFailed(
        message: 'خطأ في التحقق: ${e.toString()}',
        attempts: 0,
      ));
    }
  }

  Future<void> _onBiometricRequested(
    AuthBiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthBiometricInProgress());

    try {
      final result = await _authRepository.authenticateWithBiometric();

      switch (result.status) {
        case BiometricStatus.success:
          emit(const AuthAuthenticated());
          _startFaceMonitor();

        case BiometricStatus.failed:
          emit(const AuthLocked());

        case BiometricStatus.unavailable:
          emit(AuthBiometricUnavailable(result.message ?? 'غير متاح'));
      }
    } catch (e) {
      emit(AuthBiometricUnavailable('خطأ في البصمة: ${e.toString()}'));
    }
  }

  // ── Face Unlock (MobileFaceNet embedding) ──────────────

  Future<void> _onFaceUnlockRequested(
    AuthFaceUnlockRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthFaceUnlockInProgress());

    try {
      final hasEnrolled = await _faceVerification.hasEnrolledFace();
      if (!hasEnrolled) {
        emit(const AuthFaceUnlockFailed('لم يتم تسجيل وجه بعد'));
        return;
      }

      // Use platform biometric as a secondary confirmation, then start
      // the continuous face monitor which verifies via embedding.
      final result = await _authRepository.authenticateWithBiometric();
      if (result.status == BiometricStatus.success) {
        emit(const AuthAuthenticated());
        _startFaceMonitor();
      } else {
        emit(const AuthFaceUnlockFailed('فشل التحقق من الوجه'));
      }
    } catch (e) {
      emit(AuthFaceUnlockFailed('خطأ: ${e.toString()}'));
    }
  }

  // ── FIDO2 ──────────────────────────────────────────────

  Future<void> _onFido2Requested(
    AuthFido2Requested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthFido2InProgress());

    try {
      final result = await _authRepository.authenticateWithFido2();

      switch (result.status) {
        case Fido2AuthStatus.success:
          emit(const AuthAuthenticated());
          _startFaceMonitor();

        case Fido2AuthStatus.noCredentials:
          emit(AuthFido2Error(result.message ?? 'لا توجد مفاتيح مسجّلة'));

        case Fido2AuthStatus.failed:
        case Fido2AuthStatus.error:
          emit(AuthFido2Error(result.message ?? 'فشل التحقق بمفتاح FIDO2'));
      }
    } catch (e) {
      emit(AuthFido2Error('خطأ: ${e.toString()}'));
    }
  }

  // ── Duress Password ────────────────────────────────────

  Future<void> _onDuressPasswordSet(
    AuthDuressPasswordSet event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.saveDuressPassword(event.password);
    } catch (_) {
      // Non-critical — silently ignore
    }
  }

  Future<void> _onSetupCompleted(
    AuthSetupCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUnlocking());
    try {
      await _authRepository.saveMasterPassword(event.masterPassword);
      emit(const AuthAuthenticated());
      _startFaceMonitor();
    } catch (e) {
      emit(AuthFailed(
        message: 'فشل حفظ كلمة المرور: ${e.toString()}',
        attempts: 0,
      ));
    }
  }

  Future<void> _onVaultLocked(
    AuthVaultLocked event,
    Emitter<AuthState> emit,
  ) async {
    await _stopFaceMonitor();
    emit(const AuthLocked());
  }

  void _onErrorDismissed(
    AuthErrorDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthLocked());
  }

  // ── Face-Track monitor ─────────────────────────────────

  void _startFaceMonitor() {
    _faceMonitor ??= BackgroundFaceMonitor(
      onVerificationFailed: () => add(const AuthVaultLocked()),
    );
    _faceMonitor!.start();
  }

  Future<void> _stopFaceMonitor() async {
    await _faceMonitor?.stop();
  }

  @override
  Future<void> close() async {
    await _stopFaceMonitor();
    return super.close();
  }
}
