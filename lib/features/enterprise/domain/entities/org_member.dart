import 'org_role.dart';

/// A member of an organisation.
class OrgMember {
  final String id;
  final String orgId;
  final String userId;
  final String displayName;
  final String email;
  final OrgRole role;
  final DateTime joinedAt;
  final bool isActive;

  const OrgMember({
    required this.id,
    required this.orgId,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  OrgMember copyWith({
    String? id,
    String? orgId,
    String? userId,
    String? displayName,
    String? email,
    OrgRole? role,
    DateTime? joinedAt,
    bool? isActive,
  }) =>
      OrgMember(
        id: id ?? this.id,
        orgId: orgId ?? this.orgId,
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        role: role ?? this.role,
        joinedAt: joinedAt ?? this.joinedAt,
        isActive: isActive ?? this.isActive,
      );

  factory OrgMember.fromJson(Map<String, dynamic> json) => OrgMember(
        id: json['id'] as String,
        orgId: json['org_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: OrgRole.fromString(json['role'] as String),
        joinedAt: DateTime.parse(json['joined_at'] as String),
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'user_id': userId,
        'display_name': displayName,
        'email': email,
        'role': role.name,
        'joined_at': joinedAt.toIso8601String(),
        'is_active': isActive,
      };
}
