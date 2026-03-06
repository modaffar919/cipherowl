part of 'geofence_bloc.dart';

abstract class GeofenceState {
  const GeofenceState();
}

class GeofenceInitial extends GeofenceState {
  const GeofenceInitial();
}

class GeofenceLoading extends GeofenceState {
  const GeofenceLoading();
}

/// Main state — geo-fencing loaded and optionally running.
class GeofenceLoaded extends GeofenceState {
  final List<SafeZone> zones;
  final bool isMonitoring;

  /// Whether the device is currently inside at least one active zone.
  /// `null` = unknown (not yet determined).
  final bool? isInsideZone;

  /// Last GPS position received from the stream.
  final Position? lastPosition;

  /// When the device first exited all zones in the current monitoring session.
  final DateTime? exitedAt;

  /// Set to `true` when the bloc detects the user has left all zones.
  /// The UI should listen for this flag and trigger `AuthVaultLocked`.
  final bool shouldLockVault;

  /// Set to `true` when location permission was denied during toggle.
  final bool permissionDenied;

  /// Transient message to show as a SnackBar.
  final String? message;

  const GeofenceLoaded({
    required this.zones,
    required this.isMonitoring,
    this.isInsideZone,
    this.lastPosition,
    this.exitedAt,
    this.shouldLockVault = false,
    this.permissionDenied = false,
    this.message,
  });

  bool get hasActiveZones => zones.any((z) => z.isActive);

  GeofenceLoaded copyWith({
    List<SafeZone>? zones,
    bool? isMonitoring,
    bool? isInsideZone,
    Position? lastPosition,
    DateTime? exitedAt,
    bool? shouldLockVault,
    bool? permissionDenied,
    String? message,
  }) =>
      GeofenceLoaded(
        zones: zones ?? this.zones,
        isMonitoring: isMonitoring ?? this.isMonitoring,
        isInsideZone: isInsideZone ?? this.isInsideZone,
        lastPosition: lastPosition ?? this.lastPosition,
        exitedAt: exitedAt ?? this.exitedAt,
        shouldLockVault: shouldLockVault ?? this.shouldLockVault,
        permissionDenied: permissionDenied ?? this.permissionDenied,
        message: message,
      );
}
