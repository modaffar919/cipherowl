import 'dart:convert';
import 'dart:math' as math;

/// Represents a named geographic area that is considered "safe" for the vault.
///
/// When the device exits ALL active safe zones and geo-fencing is enabled,
/// the vault is automatically locked.
class SafeZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Radius in metres around the centre point. Default 150 m.
  final double radiusMeters;
  final bool isActive;

  const SafeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 150.0,
    this.isActive = true,
  });

  // ── Serialisation ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'isActive': isActive,
      };

  factory SafeZone.fromJson(Map<String, dynamic> json) => SafeZone(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 150.0,
        isActive: json['isActive'] as bool? ?? true,
      );

  static List<SafeZone> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SafeZone.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<SafeZone> zones) =>
      jsonEncode(zones.map((z) => z.toJson()).toList());

  // ── Geometry ──────────────────────────────────────────────────────────────────

  /// Returns the great-circle distance in metres between this zone's centre
  /// and the given coordinates using the Haversine formula.
  double distanceTo(double lat, double lng) {
    const r = 6371000.0; // Earth radius in metres
    final phi1 = latitude * math.pi / 180;
    final phi2 = lat * math.pi / 180;
    final dPhi = (lat - latitude) * math.pi / 180;
    final dLambda = (lng - longitude) * math.pi / 180;

    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Whether the given coordinates are inside this zone.
  bool contains(double lat, double lng) =>
      isActive && distanceTo(lat, lng) <= radiusMeters;

  // ── Equality ─────────────────────────────────────────────────────────────────

  SafeZone copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? isActive,
  }) =>
      SafeZone(
        id: id ?? this.id,
        name: name ?? this.name,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        isActive: isActive ?? this.isActive,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SafeZone && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SafeZone(id: $id, name: $name, lat: $latitude, lng: $longitude, r: ${radiusMeters}m)';
}
