import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists Travel Mode state using [FlutterSecureStorage].
///
/// Keys:
///   `travel_mode_enabled`            — '1' / '0'
///   `travel_mode_hidden_categories`  — JSON list of VaultCategory.name strings
class TravelModeRepository {
  static const _keyEnabled = 'travel_mode_enabled';
  static const _keyHidden = 'travel_mode_hidden_categories';

  /// Default categories hidden when Travel Mode is first enabled.
  static const defaultHiddenCategories = ['card', 'identity'];

  final FlutterSecureStorage _storage;

  const TravelModeRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> isEnabled() async {
    final v = await _storage.read(key: _keyEnabled);
    return v == '1';
  }

  Future<void> setEnabled(bool value) =>
      _storage.write(key: _keyEnabled, value: value ? '1' : '0');

  Future<Set<String>> getHiddenCategories() async {
    final raw = await _storage.read(key: _keyHidden);
    if (raw == null || raw.isEmpty) {
      return defaultHiddenCategories.toSet();
    }
    final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
    return list.toSet();
  }

  Future<void> setHiddenCategories(Set<String> categories) => _storage.write(
        key: _keyHidden,
        value: jsonEncode(categories.toList()),
      );

  Future<void> clearAll() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyHidden);
  }
}
