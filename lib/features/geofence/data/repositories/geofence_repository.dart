import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/safe_zone.dart';

/// Persists the list of geo-fence safe zones using [FlutterSecureStorage].
///
/// Safe zones are stored as a JSON array under a single key so they are
/// encrypted at rest on both Android (EncryptedSharedPreferences) and iOS
/// (Keychain).
class GeofenceRepository {
  static const _zonesKey = 'geofence_safe_zones';
  static const _enabledKey = 'geofence_enabled';

  final FlutterSecureStorage _storage;

  const GeofenceRepository(
      {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── Enabled flag ─────────────────────────────────────────────────────────────

  Future<bool> isEnabled() async {
    final raw = await _storage.read(key: _enabledKey);
    return raw == 'true';
  }

  Future<void> setEnabled(bool value) =>
      _storage.write(key: _enabledKey, value: value.toString());

  // ── Safe zones CRUD ───────────────────────────────────────────────────────────

  Future<List<SafeZone>> getSafeZones() async {
    final raw = await _storage.read(key: _zonesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return SafeZone.listFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveZones(List<SafeZone> zones) =>
      _storage.write(key: _zonesKey, value: SafeZone.listToJson(zones));

  Future<void> addSafeZone(SafeZone zone) async {
    final zones = await getSafeZones();
    // Replace if same id exists, otherwise append.
    final idx = zones.indexWhere((z) => z.id == zone.id);
    if (idx >= 0) {
      zones[idx] = zone;
    } else {
      zones.add(zone);
    }
    await _saveZones(zones);
  }

  Future<void> updateSafeZone(SafeZone zone) async {
    final zones = await getSafeZones();
    final idx = zones.indexWhere((z) => z.id == zone.id);
    if (idx >= 0) {
      zones[idx] = zone;
      await _saveZones(zones);
    }
  }

  Future<void> removeSafeZone(String id) async {
    final zones = await getSafeZones();
    zones.removeWhere((z) => z.id == id);
    await _saveZones(zones);
  }

  Future<void> toggleZone(String id) async {
    final zones = await getSafeZones();
    final idx = zones.indexWhere((z) => z.id == id);
    if (idx >= 0) {
      zones[idx] = zones[idx].copyWith(isActive: !zones[idx].isActive);
      await _saveZones(zones);
    }
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _zonesKey);
    await _storage.delete(key: _enabledKey);
  }
}
