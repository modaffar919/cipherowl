import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/safe_zone.dart';

/// Monitors device location and notifies when the user leaves all safe zones.
///
/// Uses [Geolocator] package.  Location permissions must be granted before
/// calling [startMonitoring].
class GeofenceService {
  StreamSubscription<Position>? _subscription;

  /// Whether the service is currently streaming location updates.
  bool get isRunning => _subscription != null;

  // ── Permission helpers ────────────────────────────────────────────────────────

  /// Requests location permissions. Returns `true` when the app has at least
  /// [LocationPermission.whileInUse] permission.
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Returns true if location permission is already granted.
  static Future<bool> hasPermission() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  // ── Monitoring ────────────────────────────────────────────────────────────────

  /// Starts streaming location updates and calls [onExitedAllZones] when the
  /// device is outside all [zones].
  ///
  /// [onPositionUpdated] is called on every position tick so the UI can show
  /// the current status.
  void startMonitoring({
    required List<SafeZone> zones,
    required void Function() onExitedAllZones,
    void Function(Position position, bool isInsideAnyZone)? onPositionUpdated,
  }) {
    _subscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 30, // metres — avoid spamming on minor jitter
    );

    _subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      final inside = _isInsideAnyZone(position.latitude, position.longitude, zones);
      onPositionUpdated?.call(position, inside);
      if (!inside) {
        onExitedAllZones();
      }
    });
  }

  /// Stops monitoring location.
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Returns the current device position (one-shot).
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Geometry ─────────────────────────────────────────────────────────────────

  static bool _isInsideAnyZone(
      double lat, double lng, List<SafeZone> zones) {
    if (zones.isEmpty) return true; // no zones = no restriction
    return zones.any((z) => z.isActive && z.contains(lat, lng));
  }

  /// Checks once whether the current position is inside any of [zones].
  static Future<bool> isCurrentlyInsideAnyZone(List<SafeZone> zones) async {
    if (zones.isEmpty) return true;
    final pos = await getCurrentPosition();
    if (pos == null) return true; // fail-open: don't lock if GPS unavailable
    return _isInsideAnyZone(pos.latitude, pos.longitude, zones);
  }

  void dispose() => stopMonitoring();
}
