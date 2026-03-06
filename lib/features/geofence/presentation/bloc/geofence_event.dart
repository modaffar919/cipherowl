part of 'geofence_bloc.dart';

abstract class GeofenceEvent {
  const GeofenceEvent();
}

/// Load saved zones and start monitoring if previously enabled.
class GeofenceStarted extends GeofenceEvent {
  const GeofenceStarted();
}

/// Toggle monitoring on/off.  Requests permission if needed.
class GeofenceMonitoringToggled extends GeofenceEvent {
  const GeofenceMonitoringToggled();
}

/// Add a new safe zone.
class GeofenceZoneAdded extends GeofenceEvent {
  final SafeZone zone;
  const GeofenceZoneAdded(this.zone);
}

/// Remove an existing safe zone by [zoneId].
class GeofenceZoneRemoved extends GeofenceEvent {
  final String zoneId;
  const GeofenceZoneRemoved(this.zoneId);
}

/// Toggle a safe zone's active flag.
class GeofenceZoneToggled extends GeofenceEvent {
  final String zoneId;
  const GeofenceZoneToggled(this.zoneId);
}

/// Update an existing safe zone's properties.
class GeofenceZoneUpdated extends GeofenceEvent {
  final SafeZone zone;
  const GeofenceZoneUpdated(this.zone);
}

// ── Internal events (not dispatched by UI) ────────────────────────────────────

class _GeofencePositionTick extends GeofenceEvent {
  final Position position;
  final bool isInsideZone;
  const _GeofencePositionTick(this.position, this.isInsideZone);
}

class _GeofenceExitDetected extends GeofenceEvent {
  const _GeofenceExitDetected();
}
