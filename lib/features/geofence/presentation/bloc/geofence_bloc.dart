import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'package:cipherowl/features/geofence/data/models/safe_zone.dart';
import 'package:cipherowl/features/geofence/data/repositories/geofence_repository.dart';
import 'package:cipherowl/features/geofence/data/services/geofence_service.dart';

part 'geofence_event.dart';
part 'geofence_state.dart';

/// BLoC that manages geo-fencing safe zones and auto-lock logic.
///
/// When geo-fencing is enabled and the device leaves all active safe zones,
/// this BLoC emits [GeofenceExited], which the UI uses to trigger vault lock.
class GeofenceBloc extends Bloc<GeofenceEvent, GeofenceState> {
  final GeofenceRepository _repo;
  final GeofenceService _service;
  final _uuid = const Uuid();

  GeofenceBloc({
    GeofenceRepository? repository,
    GeofenceService? service,
  })  : _repo = repository ?? const GeofenceRepository(),
        _service = service ?? GeofenceService(),
        super(const GeofenceInitial()) {
    on<GeofenceStarted>(_onStarted);
    on<GeofenceMonitoringToggled>(_onMonitoringToggled);
    on<GeofenceZoneAdded>(_onZoneAdded);
    on<GeofenceZoneRemoved>(_onZoneRemoved);
    on<GeofenceZoneToggled>(_onZoneToggled);
    on<GeofenceZoneUpdated>(_onZoneUpdated);
    on<_GeofencePositionTick>(_onPositionTick);
    on<_GeofenceExitDetected>(_onExitDetected);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  GeofenceLoaded? get _loaded =>
      state is GeofenceLoaded ? state as GeofenceLoaded : null;

  void _startService(List<SafeZone> zones) {
    _service.startMonitoring(
      zones: zones,
      onExitedAllZones: () => add(const _GeofenceExitDetected()),
      onPositionUpdated: (pos, inside) =>
          add(_GeofencePositionTick(pos, inside)),
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────────

  Future<void> _onStarted(
      GeofenceStarted event, Emitter<GeofenceState> emit) async {
    emit(const GeofenceLoading());
    final enabled = await _repo.isEnabled();
    final zones = await _repo.getSafeZones();
    emit(GeofenceLoaded(zones: zones, isMonitoring: false));
    if (enabled && zones.isNotEmpty) {
      final hasPermission = await GeofenceService.hasPermission();
      if (hasPermission) {
        emit(GeofenceLoaded(
            zones: zones, isMonitoring: true, isInsideZone: true));
        _startService(zones);
      }
    }
  }

  Future<void> _onMonitoringToggled(
      GeofenceMonitoringToggled event, Emitter<GeofenceState> emit) async {
    final s = _loaded;
    if (s == null) return;

    if (s.isMonitoring) {
      // Disable
      _service.stopMonitoring();
      await _repo.setEnabled(false);
      emit(s.copyWith(isMonitoring: false, isInsideZone: null, exitedAt: null));
    } else {
      // Enable — request permission first
      final granted = await GeofenceService.requestPermission();
      if (!granted) {
        emit(s.copyWith(
            permissionDenied: true,
            message: 'إذن الموقع مطلوب لتفعيل السياج الجغرافي'));
        return;
      }
      await _repo.setEnabled(true);
      final zones = s.zones;
      if (zones.isEmpty) {
        emit(s.copyWith(
            isMonitoring: false,
            message: 'أضف منطقة آمنة أولاً لتفعيل المراقبة'));
        return;
      }
      emit(s.copyWith(isMonitoring: true, isInsideZone: true, message: null));
      _startService(zones);
    }
  }

  Future<void> _onZoneAdded(
      GeofenceZoneAdded event, Emitter<GeofenceState> emit) async {
    final s = _loaded;
    if (s == null) return;

    final zone = event.zone.copyWith(id: event.zone.id.isEmpty
        ? _uuid.v4()
        : event.zone.id);
    await _repo.addSafeZone(zone);
    final zones = [...s.zones, zone];
    emit(s.copyWith(zones: zones, message: 'تمت إضافة المنطقة الآمنة ✓'));
    if (s.isMonitoring) _startService(zones);
  }

  Future<void> _onZoneRemoved(
      GeofenceZoneRemoved event, Emitter<GeofenceState> emit) async {
    final s = _loaded;
    if (s == null) return;

    await _repo.removeSafeZone(event.zoneId);
    final zones = s.zones.where((z) => z.id != event.zoneId).toList();
    emit(s.copyWith(zones: zones));
    if (s.isMonitoring) {
      if (zones.isEmpty) {
        _service.stopMonitoring();
        emit(s.copyWith(zones: zones, isMonitoring: false));
      } else {
        _startService(zones);
      }
    }
  }

  Future<void> _onZoneToggled(
      GeofenceZoneToggled event, Emitter<GeofenceState> emit) async {
    final s = _loaded;
    if (s == null) return;

    await _repo.toggleZone(event.zoneId);
    final zones = s.zones.map((z) {
      if (z.id == event.zoneId) return z.copyWith(isActive: !z.isActive);
      return z;
    }).toList();
    emit(s.copyWith(zones: zones));
    if (s.isMonitoring) _startService(zones);
  }

  Future<void> _onZoneUpdated(
      GeofenceZoneUpdated event, Emitter<GeofenceState> emit) async {
    final s = _loaded;
    if (s == null) return;

    await _repo.updateSafeZone(event.zone);
    final zones =
        s.zones.map((z) => z.id == event.zone.id ? event.zone : z).toList();
    emit(s.copyWith(zones: zones));
    if (s.isMonitoring) _startService(zones);
  }

  void _onPositionTick(
      _GeofencePositionTick event, Emitter<GeofenceState> emit) {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(
        isInsideZone: event.isInsideZone,
        lastPosition: event.position,
        exitedAt: event.isInsideZone ? null : s.exitedAt ?? DateTime.now()));
  }

  void _onExitDetected(
      _GeofenceExitDetected event, Emitter<GeofenceState> emit) {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(
        isInsideZone: false,
        exitedAt: DateTime.now(),
        shouldLockVault: true));
  }

  @override
  Future<void> close() {
    _service.dispose();
    return super.close();
  }
}
