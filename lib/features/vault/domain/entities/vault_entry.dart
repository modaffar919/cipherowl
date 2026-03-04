import 'dart:typed_data';

/// Category of a vault entry — mirrors [VaultItemCategory] enum in the DB
/// but lives in the domain layer (no Drift dependency).
enum VaultCategory {
  login,
  card,
  secureNote,
  identity,
  totp;

  /// Localised Arabic label.
  String get labelAr {
    switch (this) {
      case login:
        return 'تسجيل دخول';
      case card:
        return 'بطاقة';
      case secureNote:
        return 'ملاحظة آمنة';
      case identity:
        return 'هوية';
      case totp:
        return 'TOTP';
    }
  }

  /// Icon for each category.
  String get emoji {
    switch (this) {
      case login:
        return '🔑';
      case card:
        return '💳';
      case secureNote:
        return '📝';
      case identity:
        return '🪪';
      case totp:
        return '🔐';
    }
  }
}

/// Pure domain entity — no ORM / platform dependencies.
///
/// Sensitive fields ([encryptedPassword], [encryptedNotes],
/// [encryptedTotpSecret]) hold raw AES-256-GCM blobs produced by the
/// Rust core. Decryption happens in the presentation layer on demand.
class VaultEntry {
  final String id;
  final String userId;
  final String title;
  final String? username;

  /// AES-256-GCM cipher blob (nonce prepended). Null if no password set.
  final Uint8List? encryptedPassword;

  final String? url;

  /// AES-256-GCM encrypted notes blob. Null if no notes.
  final Uint8List? encryptedNotes;

  /// AES-256-GCM encrypted TOTP secret. Non-null only for [VaultCategory.totp].
  final Uint8List? encryptedTotpSecret;

  final VaultCategory category;
  final bool isFavorite;

  /// zxcvbn strength score 0–4. -1 means not yet computed.
  final int strengthScore;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;

  /// Null while pending sync; set after a successful Supabase upsert.
  final DateTime? syncedAt;

  const VaultEntry({
    required this.id,
    required this.userId,
    required this.title,
    this.username,
    this.encryptedPassword,
    this.url,
    this.encryptedNotes,
    this.encryptedTotpSecret,
    this.category = VaultCategory.login,
    this.isFavorite = false,
    this.strengthScore = -1,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    this.syncedAt,
  });

  VaultEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? username,
    Uint8List? encryptedPassword,
    String? url,
    Uint8List? encryptedNotes,
    Uint8List? encryptedTotpSecret,
    VaultCategory? category,
    bool? isFavorite,
    int? strengthScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    DateTime? syncedAt,
  }) =>
      VaultEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        username: username ?? this.username,
        encryptedPassword: encryptedPassword ?? this.encryptedPassword,
        url: url ?? this.url,
        encryptedNotes: encryptedNotes ?? this.encryptedNotes,
        encryptedTotpSecret: encryptedTotpSecret ?? this.encryptedTotpSecret,
        category: category ?? this.category,
        isFavorite: isFavorite ?? this.isFavorite,
        strengthScore: strengthScore ?? this.strengthScore,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
        syncedAt: syncedAt ?? this.syncedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultEntry && other.id == id && other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(id, updatedAt);

  @override
  String toString() =>
      'VaultEntry(id: $id, title: $title, category: ${category.name})';
}
