import 'package:drift/drift.dart';

import '../smartvault_database.dart';

part 'settings_dao.g.dart';

/// Data Access Object for [UserSettings] key-value store.
@DriftAccessor(tables: [UserSettings])
class SettingsDao extends DatabaseAccessor<SmartVaultDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  // ── Queries ─────────────────────────────────────────────────────────────

  /// Read a single setting value (returns null if key not set).
  Future<String?> getSetting(String key) async {
    final row = await (select(userSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Read all settings as a `Map<key, value>`.
  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(userSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  /// Watch a single setting value in real time.
  Stream<String?> watchSetting(String key) =>
      (select(userSettings)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r?.value);

  // ── Mutations ───────────────────────────────────────────────────────────

  /// Insert or replace a setting (upsert).
  Future<void> setSetting(String key, String value) =>
      into(userSettings).insertOnConflictUpdate(
        UserSettingsCompanion.insert(key: key, value: value),
      );

  /// Delete a setting by key.
  Future<int> deleteSetting(String key) =>
      (delete(userSettings)..where((t) => t.key.equals(key))).go();

  /// Delete all settings (for full reset / wipe).
  Future<int> clearAll() => delete(userSettings).go();

  // ── Typed convenience getters ────────────────────────────────────────────

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final v = await getSetting(key);
    if (v == null) return defaultValue;
    return v == 'true' || v == '1';
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final v = await getSetting(key);
    return int.tryParse(v ?? '') ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) =>
      setSetting(key, value.toString());

  Future<void> setInt(String key, int value) =>
      setSetting(key, value.toString());
}
