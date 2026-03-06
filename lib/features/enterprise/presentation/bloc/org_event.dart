import 'package:equatable/equatable.dart';

import '../../domain/entities/org_role.dart';

abstract class OrgEvent extends Equatable {
  const OrgEvent();
  @override
  List<Object?> get props => [];
}

/// Load orgs for the authenticated user.
class OrgLoadRequested extends OrgEvent {
  final String userId;
  const OrgLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

/// Create a new organisation.
class OrgCreateRequested extends OrgEvent {
  final String ownerId;
  final String name;
  final String? description;
  const OrgCreateRequested({
    required this.ownerId,
    required this.name,
    this.description,
  });
  @override
  List<Object?> get props => [ownerId, name, description];
}

/// Select an org to view its details/vaults.
class OrgSelected extends OrgEvent {
  final String orgId;
  const OrgSelected(this.orgId);
  @override
  List<Object?> get props => [orgId];
}

/// Invite a member by email to the currently selected org.
class OrgInviteMemberRequested extends OrgEvent {
  final String orgId;
  final String userId;
  final String displayName;
  final String email;
  final OrgRole role;
  const OrgInviteMemberRequested({
    required this.orgId,
    required this.userId,
    required this.displayName,
    required this.email,
    this.role = OrgRole.member,
  });
  @override
  List<Object?> get props => [orgId, userId, email, role];
}

/// Update a member's role.
class OrgUpdateMemberRoleRequested extends OrgEvent {
  final String memberId;
  final OrgRole newRole;
  const OrgUpdateMemberRoleRequested(this.memberId, this.newRole);
  @override
  List<Object?> get props => [memberId, newRole];
}

/// Remove a member from the org.
class OrgRemoveMemberRequested extends OrgEvent {
  final String memberId;
  const OrgRemoveMemberRequested(this.memberId);
  @override
  List<Object?> get props => [memberId];
}

/// Create a shared vault inside the selected org.
class OrgCreateVaultRequested extends OrgEvent {
  final String orgId;
  final String name;
  final String createdByUserId;
  final String? description;
  const OrgCreateVaultRequested({
    required this.orgId,
    required this.name,
    required this.createdByUserId,
    this.description,
  });
  @override
  List<Object?> get props => [orgId, name, createdByUserId, description];
}

/// Delete a shared vault.
class OrgDeleteVaultRequested extends OrgEvent {
  final String vaultId;
  const OrgDeleteVaultRequested(this.vaultId);
  @override
  List<Object?> get props => [vaultId];
}
