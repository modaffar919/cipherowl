part of 'settings_bloc.dart';

abstract class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Settings successfully loaded and available.
class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  const SettingsLoaded(this.settings);

  SettingsLoaded copyWithSettings(AppSettings s) => SettingsLoaded(s);
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}
