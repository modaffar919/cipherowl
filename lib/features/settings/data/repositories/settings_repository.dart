import 'package:cipherowl/core/database/smartvault_database.dart';

/// Typed settings repository backed by [SettingsDao] (SQLCipher key-value).
///
/// All keys are prefixed with `setting_` to avoid collisions.
/// Values are stored as strings and cast on read.
class SettingsRepository {
  static const _prefix = 'setting_';

  final SmartVaultDatabase _db;

  SettingsRepository(this._db);

  // ── Security ──────────────────────────────────────────────────────────────

  Future<bool> getFaceTrack() =>
      _db.settingsDao.getBool('${_prefix}face_track', defaultValue: true);

  Future<void> setFaceTrack(bool v) =>
      _db.settingsDao.setBool('${_prefix}face_track', v);

  Future<bool> getBiometric() =>
      _db.settingsDao.getBool('${_prefix}biometric', defaultValue: true);

  Future<void> setBiometric(bool v) =>
      _db.settingsDao.setBool('${_prefix}biometric', v);

  Future<bool> getDuressMode() =>
      _db.settingsDao.getBool('${_prefix}duress_mode', defaultValue: false);

  Future<void> setDuressMode(bool v) =>
      _db.settingsDao.setBool('${_prefix}duress_mode', v);

  /// Lock timeout in minutes. Default: 5.
  Future<int> getLockTimeout() =>
      _db.settingsDao.getInt('${_prefix}lock_timeout', defaultValue: 5);

  Future<void> setLockTimeout(int minutes) =>
      _db.settingsDao.setInt('${_prefix}lock_timeout', minutes);

  // ── Privacy ───────────────────────────────────────────────────────────────

  Future<bool> getDarkWebMonitor() =>
      _db.settingsDao.getBool('${_prefix}dark_web', defaultValue: true);

  Future<void> setDarkWebMonitor(bool v) =>
      _db.settingsDao.setBool('${_prefix}dark_web', v);

  Future<bool> getAutoFill() =>
      _db.settingsDao.getBool('${_prefix}autofill', defaultValue: true);

  Future<void> setAutoFill(bool v) =>
      _db.settingsDao.setBool('${_prefix}autofill', v);

  // ── App ───────────────────────────────────────────────────────────────────

  /// Language code: 'ar' | 'en'. Default: 'ar'.
  Future<String> getLanguage() async =>
      (await _db.settingsDao.getSetting('${_prefix}language')) ?? 'ar';

  Future<void> setLanguage(String code) =>
      _db.settingsDao.setSetting('${_prefix}language', code);

  // ── Location Security ─────────────────────────────────────────────────────

  Future<bool> getGeoFenceEnabled() =>
      _db.settingsDao.getBool('${_prefix}geofence_enabled', defaultValue: false);

  Future<void> setGeoFenceEnabled(bool v) =>
      _db.settingsDao.setBool('${_prefix}geofence_enabled', v);

  // ── Travel Mode ───────────────────────────────────────────────────────────

  Future<bool> getTravelModeEnabled() =>
      _db.settingsDao.getBool('${_prefix}travel_mode_enabled', defaultValue: false);

  Future<void> setTravelModeEnabled(bool v) =>
      _db.settingsDao.setBool('${_prefix}travel_mode_enabled', v);

  // ── Load all at once ──────────────────────────────────────────────────────

  Future<AppSettings> loadAll() async {
    final results = await Future.wait([
      getFaceTrack(),
      getBiometric(),
      getDuressMode(),
      getLockTimeout() as Future<dynamic>,
      getDarkWebMonitor(),
      getAutoFill(),
      getLanguage() as Future<dynamic>,
      getGeoFenceEnabled(),
      getTravelModeEnabled(),
    ]);
    return AppSettings(
      faceTrack: results[0] as bool,
      biometric: results[1] as bool,
      duressMode: results[2] as bool,
      lockTimeout: results[3] as int,
      darkWebMonitor: results[4] as bool,
      autoFill: results[5] as bool,
      language: results[6] as String,
      geoFenceEnabled: results[7] as bool,
      travelModeEnabled: results[8] as bool,
    );
  }
}

/// Immutable snapshot of all persisted app settings.
class AppSettings {
  final bool faceTrack;
  final bool biometric;
  final bool duressMode;
  final int lockTimeout;
  final bool darkWebMonitor;
  final bool autoFill;
  final String language;
  final bool geoFenceEnabled;
  final bool travelModeEnabled;

  const AppSettings({
    required this.faceTrack,
    required this.biometric,
    required this.duressMode,
    required this.lockTimeout,
    required this.darkWebMonitor,
    required this.autoFill,
    required this.language,
    this.geoFenceEnabled = false,
    this.travelModeEnabled = false,
  });

  AppSettings copyWith({
    bool? faceTrack,
    bool? biometric,
    bool? duressMode,
    int? lockTimeout,
    bool? darkWebMonitor,
    bool? autoFill,
    String? language,
    bool? geoFenceEnabled,
    bool? travelModeEnabled,
  }) {
    return AppSettings(
      faceTrack: faceTrack ?? this.faceTrack,
      biometric: biometric ?? this.biometric,
      duressMode: duressMode ?? this.duressMode,
      lockTimeout: lockTimeout ?? this.lockTimeout,
      darkWebMonitor: darkWebMonitor ?? this.darkWebMonitor,
      autoFill: autoFill ?? this.autoFill,
      language: language ?? this.language,
      geoFenceEnabled: geoFenceEnabled ?? this.geoFenceEnabled,
      travelModeEnabled: travelModeEnabled ?? this.travelModeEnabled,
    );
  }
}
