import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_notification.dart';

/// Persists notifications in SharedPreferences (key: _kKey).
/// Maintains an in-memory cache for fast reads.
class NotificationRepository {
  static const _kKey = 'app_notifications_v1';

  List<AppNotification> _cache = [];
  bool _loaded = false;

  Future<List<AppNotification>> getAll() async {
    if (_loaded) return List.unmodifiable(_cache);
    await _load();
    return List.unmodifiable(_cache);
  }

  Future<void> add(AppNotification notification) async {
    await _load();
    _cache = [notification, ..._cache];
    await _save();
  }

  Future<void> markRead(String id) async {
    await _load();
    _cache = _cache
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await _save();
  }

  Future<void> markAllRead() async {
    await _load();
    _cache = _cache.map((n) => n.copyWith(isRead: true)).toList();
    await _save();
  }

  Future<void> remove(String id) async {
    await _load();
    _cache = _cache.where((n) => n.id != id).toList();
    await _save();
  }

  Future<void> clearAll() async {
    _cache = [];
    _loaded = true;
    await _save();
  }

  int get unreadCount => _loaded ? _cache.where((n) => !n.isRead).length : 0;

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        _cache = list;
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Load error: $e');
      _cache = [];
    }
    _loaded = true;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_cache.map((n) => n.toJson()).toList());
      await prefs.setString(_kKey, json);
    } catch (e) {
      debugPrint('[NotificationRepository] Save error: $e');
    }
  }
}
