import 'org_member.dart';

/// An organisation that owns shared vaults and has team members.
class Organisation {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String? logoUrl;
  final DateTime createdAt;
  final List<OrgMember> members;

  const Organisation({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.logoUrl,
    required this.createdAt,
    this.members = const [],
  });

  Organisation copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? logoUrl,
    DateTime? createdAt,
    List<OrgMember>? members,
  }) =>
      Organisation(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        ownerId: ownerId ?? this.ownerId,
        logoUrl: logoUrl ?? this.logoUrl,
        createdAt: createdAt ?? this.createdAt,
        members: members ?? this.members,
      );

  factory Organisation.fromJson(Map<String, dynamic> json) => Organisation(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        ownerId: json['owner_id'] as String,
        logoUrl: json['logo_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'owner_id': ownerId,
        if (logoUrl != null) 'logo_url': logoUrl,
        'created_at': createdAt.toIso8601String(),
      };
}

/// A shared vault belonging to an organisation.
class OrgVault {
  final String id;
  final String orgId;
  final String name;
  final String? description;
  final String createdByUserId;
  final DateTime createdAt;
  final int itemCount;

  const OrgVault({
    required this.id,
    required this.orgId,
    required this.name,
    this.description,
    required this.createdByUserId,
    required this.createdAt,
    this.itemCount = 0,
  });

  OrgVault copyWith({
    String? id,
    String? orgId,
    String? name,
    String? description,
    String? createdByUserId,
    DateTime? createdAt,
    int? itemCount,
  }) =>
      OrgVault(
        id: id ?? this.id,
        orgId: orgId ?? this.orgId,
        name: name ?? this.name,
        description: description ?? this.description,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
        itemCount: itemCount ?? this.itemCount,
      );

  factory OrgVault.fromJson(Map<String, dynamic> json) => OrgVault(
        id: json['id'] as String,
        orgId: json['org_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        createdByUserId: json['created_by_user_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        itemCount: json['item_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'name': name,
        if (description != null) 'description': description,
        'created_by_user_id': createdByUserId,
        'created_at': createdAt.toIso8601String(),
      };
}
