part of 'settings_bloc.dart';

abstract class SettingsEvent {
  const SettingsEvent();
}

/// Load all settings from the repository on app start.
class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

/// Toggle Face-Track biometric continuous monitoring.
class SettingsFaceTrackToggled extends SettingsEvent {
  const SettingsFaceTrackToggled();
}

/// Toggle fingerprint / local-auth biometric unlock.
class SettingsBiometricToggled extends SettingsEvent {
  const SettingsBiometricToggled();
}

/// Toggle duress password (fake vault on wrong password).
class SettingsDuressModeToggled extends SettingsEvent {
  const SettingsDuressModeToggled();
}

/// Change auto-lock timeout in minutes (1–60).
class SettingsLockTimeoutChanged extends SettingsEvent {
  final int minutes;
  const SettingsLockTimeoutChanged(this.minutes);
}

/// Toggle dark-web monitoring (HaveIBeenPwned integration).
class SettingsDarkWebToggled extends SettingsEvent {
  const SettingsDarkWebToggled();
}

/// Toggle Android/iOS AutoFill service.
class SettingsAutoFillToggled extends SettingsEvent {
  const SettingsAutoFillToggled();
}

/// Change UI language. [code] is either 'ar' or 'en'.
class SettingsLanguageChanged extends SettingsEvent {
  final String code;
  const SettingsLanguageChanged(this.code);
}
