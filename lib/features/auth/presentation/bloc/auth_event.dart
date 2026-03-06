part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App launched — check if first time or returning user
class AuthAppStarted extends AuthEvent {
  const AuthAppStarted();
}

/// User submitted master password on lock screen
class AuthMasterPasswordSubmitted extends AuthEvent {
  final String password;
  const AuthMasterPasswordSubmitted(this.password);

  @override
  List<Object?> get props => [password];
}

/// User tapped biometric button (Face ID / fingerprint)
class AuthBiometricRequested extends AuthEvent {
  const AuthBiometricRequested();
}

/// First-time setup completed — store hashed master password
class AuthSetupCompleted extends AuthEvent {
  final String masterPassword;
  const AuthSetupCompleted(this.masterPassword);

  @override
  List<Object?> get props => [masterPassword];
}

/// Lock the vault (timeout, background, manual lock)
class AuthVaultLocked extends AuthEvent {
  const AuthVaultLocked();
}

/// Reset failed attempts + clear error
class AuthErrorDismissed extends AuthEvent {
  const AuthErrorDismissed();
}

/// User tapped the FIDO2 hardware key button on lock screen
class AuthFido2Requested extends AuthEvent {
  const AuthFido2Requested();
}

/// Save (or clear) the duress password from Settings
class AuthDuressPasswordSet extends AuthEvent {
  /// null = clear the duress password
  final String? password;
  const AuthDuressPasswordSet(this.password);

  @override
  List<Object?> get props => [password];
}

/// User tapped the Face Unlock button — verify via MobileFaceNet embedding
class AuthFaceUnlockRequested extends AuthEvent {
  const AuthFaceUnlockRequested();
}
