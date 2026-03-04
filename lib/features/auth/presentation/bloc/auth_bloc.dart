import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthMasterPasswordSubmitted>(_onMasterPasswordSubmitted);
    on<AuthBiometricRequested>(_onBiometricRequested);
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

        case VerifyStatus.failed:
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

        case BiometricStatus.failed:
          emit(const AuthLocked());

        case BiometricStatus.unavailable:
          emit(AuthBiometricUnavailable(result.message ?? 'غير متاح'));
      }
    } catch (e) {
      emit(AuthBiometricUnavailable('خطأ في البصمة: ${e.toString()}'));
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
    emit(const AuthLocked());
  }

  void _onErrorDismissed(
    AuthErrorDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthLocked());
  }
}
