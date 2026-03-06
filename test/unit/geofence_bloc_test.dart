import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cipherowl/features/geofence/data/models/safe_zone.dart';
import 'package:cipherowl/features/geofence/data/repositories/geofence_repository.dart';
import 'package:cipherowl/features/geofence/data/services/geofence_service.dart';
import 'package:cipherowl/features/geofence/presentation/bloc/geofence_bloc.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────
class MockGeofenceRepository extends Mock implements GeofenceRepository {}

class MockGeofenceService extends Mock implements GeofenceService {}

class FakeSafeZone extends Fake implements SafeZone {}

// ── Helpers ───────────────────────────────────────────────────────────────────
SafeZone _zone({
  String id = 'zone-1',
  String name = 'Home',
  double lat = 30.0,
  double lng = 31.0,
  double radius = 150.0,
  bool isActive = true,
}) =>
    SafeZone(
      id: id,
      name: name,
      latitude: lat,
      longitude: lng,
      radiusMeters: radius,
      isActive: isActive,
    );

void main() {
  late MockGeofenceRepository mockRepo;
  late MockGeofenceService mockService;

  setUpAll(() {
    registerFallbackValue(FakeSafeZone());
  });

  setUp(() {
    mockRepo = MockGeofenceRepository();
    mockService = MockGeofenceService();
  });

  // ── GeofenceStarted ─────────────────────────────────────────────────────────
  group('GeofenceStarted', () {
    blocTest<GeofenceBloc, GeofenceState>(
      'emits [GeofenceLoading, GeofenceLoaded] when disabled',
      build: () {
        when(() => mockRepo.isEnabled()).thenAnswer((_) async => false);
        when(() => mockRepo.getSafeZones()).thenAnswer((_) async => []);
        return GeofenceBloc(repository: mockRepo, service: mockService);
      },
      act: (bloc) => bloc.add(const GeofenceStarted()),
      expect: () => [
        const GeofenceLoading(),
        isA<GeofenceLoaded>()
            .having((s) => s.isMonitoring, 'not monitoring', false)
            .having((s) => s.zones, 'empty zones', []),
      ],
    );

    blocTest<GeofenceBloc, GeofenceState>(
      'loads existing zones when enabled but no zones exist',
      build: () {
        when(() => mockRepo.isEnabled()).thenAnswer((_) async => true);
        when(() => mockRepo.getSafeZones()).thenAnswer((_) async => []);
        return GeofenceBloc(repository: mockRepo, service: mockService);
      },
      act: (bloc) => bloc.add(const GeofenceStarted()),
      expect: () => [
        const GeofenceLoading(),
        isA<GeofenceLoaded>()
            .having((s) => s.isMonitoring, 'not monitoring (no zones)', false)
            .having((s) => s.zones, 'empty', []),
      ],
    );
  });

  // ── GeofenceZoneAdded ───────────────────────────────────────────────────────
  group('GeofenceZoneAdded', () {
    blocTest<GeofenceBloc, GeofenceState>(
      'adds zone to loaded state',
      build: () {
        when(() => mockRepo.isEnabled()).thenAnswer((_) async => false);
        when(() => mockRepo.getSafeZones()).thenAnswer((_) async => []);
        when(() => mockRepo.addSafeZone(any())).thenAnswer((_) async {});
        return GeofenceBloc(repository: mockRepo, service: mockService);
      },
      act: (bloc) async {
        bloc.add(const GeofenceStarted());
        await Future.delayed(Duration.zero);
        bloc.add(GeofenceZoneAdded(_zone()));
      },
      skip: 2, // GeofenceLoading + GeofenceLoaded
      expect: () => [
        isA<GeofenceLoaded>()
            .having((s) => s.zones.length, 'one zone', 1)
            .having((s) => s.message, 'success msg', isNotNull),
      ],
      verify: (_) => verify(() => mockRepo.addSafeZone(any())).called(1),
    );
  });

  // ── GeofenceZoneRemoved ─────────────────────────────────────────────────────
  group('GeofenceZoneRemoved', () {
    blocTest<GeofenceBloc, GeofenceState>(
      'removes zone from loaded state',
      build: () {
        when(() => mockRepo.isEnabled()).thenAnswer((_) async => false);
        when(() => mockRepo.getSafeZones())
            .thenAnswer((_) async => [_zone()]);
        when(() => mockRepo.removeSafeZone(any())).thenAnswer((_) async {});
        return GeofenceBloc(repository: mockRepo, service: mockService);
      },
      act: (bloc) async {
        bloc.add(const GeofenceStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const GeofenceZoneRemoved('zone-1'));
      },
      skip: 2,
      expect: () => [
        isA<GeofenceLoaded>()
            .having((s) => s.zones, 'empty after removal', []),
      ],
      verify: (_) =>
          verify(() => mockRepo.removeSafeZone('zone-1')).called(1),
    );
  });

  // ── GeofenceZoneToggled ─────────────────────────────────────────────────────
  group('GeofenceZoneToggled', () {
    blocTest<GeofenceBloc, GeofenceState>(
      'toggles zone active state',
      build: () {
        when(() => mockRepo.isEnabled()).thenAnswer((_) async => false);
        when(() => mockRepo.getSafeZones())
            .thenAnswer((_) async => [_zone(isActive: true)]);
        when(() => mockRepo.toggleZone(any())).thenAnswer((_) async {});
        return GeofenceBloc(repository: mockRepo, service: mockService);
      },
      act: (bloc) async {
        bloc.add(const GeofenceStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const GeofenceZoneToggled('zone-1'));
      },
      skip: 2,
      expect: () => [
        isA<GeofenceLoaded>().having(
          (s) => s.zones.first.isActive,
          'toggled to inactive',
          false,
        ),
      ],
    );
  });

  // ── SafeZone model ────────────────────────────────────────────────────────
  group('SafeZone', () {
    test('serialisation round-trip preserves all fields', () {
      final zone = _zone(id: 'z1', name: 'Office', radius: 200);
      final json = zone.toJson();
      final restored = SafeZone.fromJson(json);
      expect(restored.id, zone.id);
      expect(restored.name, zone.name);
      expect(restored.latitude, zone.latitude);
      expect(restored.longitude, zone.longitude);
      expect(restored.radiusMeters, zone.radiusMeters);
      expect(restored.isActive, zone.isActive);
    });

    test('contains returns true for point inside radius', () {
      final zone = _zone(lat: 30.0, lng: 31.0, radius: 1000);
      // Same point — distance 0
      expect(zone.contains(30.0, 31.0), isTrue);
    });

    test('contains returns false for point far outside radius', () {
      final zone = _zone(lat: 30.0, lng: 31.0, radius: 100);
      // ~111 km away
      expect(zone.contains(31.0, 31.0), isFalse);
    });

    test('contains returns false when zone is inactive', () {
      final zone = _zone(lat: 30.0, lng: 31.0, radius: 1000, isActive: false);
      expect(zone.contains(30.0, 31.0), isFalse);
    });

    test('copyWith preserves unmodified fields', () {
      final zone = _zone();
      final copied = zone.copyWith(name: 'Work');
      expect(copied.name, 'Work');
      expect(copied.id, zone.id);
      expect(copied.latitude, zone.latitude);
    });

    test('listFromJson / listToJson round-trip', () {
      final zones = [_zone(id: 'a'), _zone(id: 'b', name: 'Work')];
      final json = SafeZone.listToJson(zones);
      final restored = SafeZone.listFromJson(json);
      expect(restored.length, 2);
      expect(restored[0].id, 'a');
      expect(restored[1].name, 'Work');
    });

    test('distanceTo returns 0 for same coordinates', () {
      final zone = _zone(lat: 30.0, lng: 31.0);
      expect(zone.distanceTo(30.0, 31.0), closeTo(0, 0.001));
    });
  });

  // ── GeofenceLoaded state helpers ───────────────────────────────────────────
  group('GeofenceLoaded', () {
    test('hasActiveZones returns true when at least one zone is active', () {
      const state = GeofenceLoaded(
        zones: [
          SafeZone(
              id: 'a', name: 'A', latitude: 0, longitude: 0, isActive: false),
          SafeZone(
              id: 'b', name: 'B', latitude: 0, longitude: 0, isActive: true),
        ],
        isMonitoring: false,
      );
      expect(state.hasActiveZones, isTrue);
    });

    test('hasActiveZones returns false when all zones are inactive', () {
      const state = GeofenceLoaded(
        zones: [
          SafeZone(
              id: 'a', name: 'A', latitude: 0, longitude: 0, isActive: false),
        ],
        isMonitoring: false,
      );
      expect(state.hasActiveZones, isFalse);
    });

    test('shouldLockVault defaults to false', () {
      const state =
          GeofenceLoaded(zones: [], isMonitoring: true);
      expect(state.shouldLockVault, isFalse);
    });
  });
}
