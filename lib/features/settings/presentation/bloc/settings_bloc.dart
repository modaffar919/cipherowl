import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/features/settings/data/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// BLoC that owns all persisted application settings.
///
/// Reads from and writes to [SettingsRepository] (SQLCipher via Drift).
/// Emits [SettingsLoaded] once settings are loaded; each toggle/change
/// event optimistically updates state and persists in the background.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repo;

  SettingsBloc({required SettingsRepository repository})
      : _repo = repository,
        super(const SettingsInitial()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsFaceTrackToggled>(_onFaceTrackToggled);
    on<SettingsBiometricToggled>(_onBiometricToggled);
    on<SettingsDuressModeToggled>(_onDuressModeToggled);
    on<SettingsLockTimeoutChanged>(_onLockTimeoutChanged);
    on<SettingsDarkWebToggled>(_onDarkWebToggled);
    on<SettingsAutoFillToggled>(_onAutoFillToggled);
    on<SettingsLanguageChanged>(_onLanguageChanged);
    on<SettingsGeoFenceToggled>(_onGeoFenceToggled);
    on<SettingsTravelModeToggled>(_onTravelModeToggled);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AppSettings? get _current =>
      state is SettingsLoaded ? (state as SettingsLoaded).settings : null;

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onStarted(
      SettingsStarted event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final s = await _repo.loadAll();
      emit(SettingsLoaded(s));
    } catch (e) {
      emit(SettingsError('فشل تحميل الإعدادات: $e'));
    }
  }

  Future<void> _onFaceTrackToggled(
      SettingsFaceTrackToggled event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(faceTrack: !s.faceTrack);
    emit(SettingsLoaded(next));
    await _repo.setFaceTrack(next.faceTrack);
  }

  Future<void> _onBiometricToggled(
      SettingsBiometricToggled event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(biometric: !s.biometric);
    emit(SettingsLoaded(next));
    await _repo.setBiometric(next.biometric);
  }

  Future<void> _onDuressModeToggled(
      SettingsDuressModeToggled event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(duressMode: !s.duressMode);
    emit(SettingsLoaded(next));
    await _repo.setDuressMode(next.duressMode);
  }

  Future<void> _onLockTimeoutChanged(
      SettingsLockTimeoutChanged event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final minutes = event.minutes.clamp(1, 60);
    final next = s.copyWith(lockTimeout: minutes);
    emit(SettingsLoaded(next));
    await _repo.setLockTimeout(minutes);
  }

  Future<void> _onDarkWebToggled(
      SettingsDarkWebToggled event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(darkWebMonitor: !s.darkWebMonitor);
    emit(SettingsLoaded(next));
    await _repo.setDarkWebMonitor(next.darkWebMonitor);
  }

  Future<void> _onAutoFillToggled(
      SettingsAutoFillToggled event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(autoFill: !s.autoFill);
    emit(SettingsLoaded(next));
    await _repo.setAutoFill(next.autoFill);
  }

  Future<void> _onLanguageChanged(
      SettingsLanguageChanged event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final code = (event.code == 'ar' || event.code == 'en') ? event.code : 'ar';
    final next = s.copyWith(language: code);
    emit(SettingsLoaded(next));
    await _repo.setLanguage(code);
  }

  Future<void> _onGeoFenceToggled(
      SettingsGeoFenceToggled event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(geoFenceEnabled: !s.geoFenceEnabled);
    emit(SettingsLoaded(next));
    await _repo.setGeoFenceEnabled(next.geoFenceEnabled);
  }

  Future<void> _onTravelModeToggled(
      SettingsTravelModeToggled event, Emitter<SettingsState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(travelModeEnabled: !s.travelModeEnabled);
    emit(SettingsLoaded(next));
    await _repo.setTravelModeEnabled(next.travelModeEnabled);
  }
}
