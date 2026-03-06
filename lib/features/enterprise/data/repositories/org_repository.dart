import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/org_member.dart';
import '../../domain/entities/org_role.dart';
import '../../domain/entities/organisation.dart';

/// Repository for organisation/team vault operations via Supabase.
///
/// Tables required (see supabase/migrations/004_org_vaults.sql):
///   - organisations   (id, name, description, owner_id, logo_url, created_at)
///   - org_members     (id, org_id, user_id, display_name, email, role, joined_at, is_active)
///   - org_vaults      (id, org_id, name, description, created_by_user_id, created_at)
class OrgRepository {
  final SupabaseClient _client;
  static const _uuid = Uuid();

  OrgRepository(this._client);

  // ── Organisation CRUD ────────────────────────────────────────────────────

  /// Create a new organisation owned by [ownerId].
  Future<Organisation> createOrganisation({
    required String ownerId,
    required String name,
    String? description,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final row = {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'owner_id': ownerId,
      'created_at': now.toIso8601String(),
    };
    await _client.from('organisations').insert(row);
    // Auto-add creator as admin
    await addMember(
      orgId: id,
      userId: ownerId,
      displayName: '',
      email: _client.auth.currentUser?.email ?? '',
      role: OrgRole.admin,
    );
    return Organisation(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      createdAt: now,
    );
  }

  /// Fetch all organisations that the current user belongs to.
  Future<List<Organisation>> getOrgsForUser(String userId) async {
    // Get org IDs via membership
    final memberRows = await _client
        .from('org_members')
        .select('org_id')
        .eq('user_id', userId)
        .eq('is_active', true);
    final orgIds =
        (memberRows as List).map((r) => r['org_id'] as String).toList();
    if (orgIds.isEmpty) return [];

    final rows = await _client
        .from('organisations')
        .select()
        .inFilter('id', orgIds);
    return rows.map((r) => Organisation.fromJson(r)).toList();
  }

  /// Fetch a single organisation by [orgId], including its members.
  Future<Organisation?> getOrg(String orgId) async {
    final rows =
        await _client.from('organisations').select().eq('id', orgId).limit(1);
    if (rows.isEmpty) return null;
    final org = Organisation.fromJson(rows.first);
    final members = await getMembersForOrg(orgId);
    return org.copyWith(members: members);
  }

  // ── Members ──────────────────────────────────────────────────────────────

  Future<List<OrgMember>> getMembersForOrg(String orgId) async {
    final rows = await _client
        .from('org_members')
        .select()
        .eq('org_id', orgId)
        .eq('is_active', true);
    return (rows as List)
        .map((r) => OrgMember.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<OrgMember> addMember({
    required String orgId,
    required String userId,
    required String displayName,
    required String email,
    OrgRole role = OrgRole.member,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final member = OrgMember(
      id: id,
      orgId: orgId,
      userId: userId,
      displayName: displayName,
      email: email,
      role: role,
      joinedAt: now,
    );
    await _client.from('org_members').insert(member.toJson());
    return member;
  }

  Future<void> updateMemberRole({
    required String memberId,
    required OrgRole role,
  }) async {
    await _client
        .from('org_members')
        .update({'role': role.name})
        .eq('id', memberId);
  }

  Future<void> removeMember(String memberId) async {
    await _client
        .from('org_members')
        .update({'is_active': false})
        .eq('id', memberId);
  }

  // ── Org Vaults ───────────────────────────────────────────────────────────

  Future<List<OrgVault>> getVaultsForOrg(String orgId) async {
    final rows = await _client
        .from('org_vaults')
        .select()
        .eq('org_id', orgId);
    return (rows as List)
        .map((r) => OrgVault.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<OrgVault> createVault({
    required String orgId,
    required String name,
    required String createdByUserId,
    String? description,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final vault = OrgVault(
      id: id,
      orgId: orgId,
      name: name,
      description: description,
      createdByUserId: createdByUserId,
      createdAt: now,
    );
    await _client.from('org_vaults').insert(vault.toJson());
    return vault;
  }

  Future<void> deleteVault(String vaultId) async {
    await _client.from('org_vaults').delete().eq('id', vaultId);
  }
}
