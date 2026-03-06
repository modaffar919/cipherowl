part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before app check
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking stored auth data (splash loading)
class AuthChecking extends AuthState {
  const AuthChecking();
}

/// No master password set → show onboarding + setup
class AuthFirstTimeSetup extends AuthState {
  const AuthFirstTimeSetup();
}

/// Setup is done but vault is locked → show lock screen
class AuthLocked extends AuthState {
  const AuthLocked();
}

/// Unlocking in progress (showing loading indicator)
class AuthUnlocking extends AuthState {
  const AuthUnlocking();
}

/// Vault is open → navigate to dashboard
class AuthAuthenticated extends AuthState {
  /// Stable user identifier. Offline = 'local_user'.
  /// Will be replaced by Supabase UID in EPIC-5.
  final String userId;

  const AuthAuthenticated({this.userId = 'local_user'});

  @override
  List<Object?> get props => [userId];
}

/// Wrong password entered
class AuthFailed extends AuthState {
  final String message;
  final int attempts;

  const AuthFailed({required this.message, required this.attempts});

  @override
  List<Object?> get props => [message, attempts];
}

/// Too many failed attempts — timed lockout
class AuthBlocked extends AuthState {
  final DateTime unblockAt;
  final int durationMinutes;

  const AuthBlocked({required this.unblockAt, required this.durationMinutes});

  @override
  List<Object?> get props => [unblockAt, durationMinutes];
}

/// Biometric auth in progress
class AuthBiometricInProgress extends AuthState {
  const AuthBiometricInProgress();
}

/// Biometric not available / not enrolled
class AuthBiometricUnavailable extends AuthState {
  final String reason;
  const AuthBiometricUnavailable(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// FIDO2 key authentication in progress
class AuthFido2InProgress extends AuthState {
  const AuthFido2InProgress();
}

/// FIDO2 auth failed or no credentials registered
class AuthFido2Error extends AuthState {
  final String message;
  const AuthFido2Error(this.message);

  @override
  List<Object?> get props => [message];
}

/// Vault opened with the duress (decoy) password — show empty vault
class AuthDuressAuthenticated extends AuthState {
  const AuthDuressAuthenticated();
}

/// Face unlock verification in progress (camera + embedding)
class AuthFaceUnlockInProgress extends AuthState {
  const AuthFaceUnlockInProgress();
}

/// Face unlock failed (no enrolled face or mismatch)
class AuthFaceUnlockFailed extends AuthState {
  final String message;
  const AuthFaceUnlockFailed(this.message);

  @override
  List<Object?> get props => [message];
}
