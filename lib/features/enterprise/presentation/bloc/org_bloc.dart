import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/org_repository.dart';
import '../../domain/entities/organisation.dart';
import 'org_event.dart';
import 'org_state.dart';

class OrgBloc extends Bloc<OrgEvent, OrgState> {
  final OrgRepository _repo;

  OrgBloc(this._repo) : super(const OrgState()) {
    on<OrgLoadRequested>(_onLoad);
    on<OrgCreateRequested>(_onCreate);
    on<OrgSelected>(_onSelect);
    on<OrgInviteMemberRequested>(_onInvite);
    on<OrgUpdateMemberRoleRequested>(_onUpdateRole);
    on<OrgRemoveMemberRequested>(_onRemoveMember);
    on<OrgCreateVaultRequested>(_onCreateVault);
    on<OrgDeleteVaultRequested>(_onDeleteVault);
  }

  Future<void> _onLoad(OrgLoadRequested event, Emitter<OrgState> emit) async {
    emit(state.copyWith(status: OrgStatus.loading));
    try {
      final orgs = await _repo.getOrgsForUser(event.userId);
      emit(state.copyWith(status: OrgStatus.loaded, orgs: orgs));
    } catch (e) {
      emit(state.copyWith(
          status: OrgStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreate(
      OrgCreateRequested event, Emitter<OrgState> emit) async {
    emit(state.copyWith(status: OrgStatus.loading));
    try {
      final org = await _repo.createOrganisation(
        ownerId: event.ownerId,
        name: event.name,
        description: event.description,
      );
      final updated = [...state.orgs, org];
      emit(state.copyWith(
          status: OrgStatus.loaded, orgs: updated, selectedOrg: org));
    } catch (e) {
      emit(state.copyWith(
          status: OrgStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSelect(OrgSelected event, Emitter<OrgState> emit) async {
    emit(state.copyWith(status: OrgStatus.loading));
    try {
      final org = await _repo.getOrg(event.orgId);
      final vaults =
          org != null ? await _repo.getVaultsForOrg(event.orgId) : <OrgVault>[];
      emit(state.copyWith(
        status: OrgStatus.loaded,
        selectedOrg: org,
        orgVaults: vaults,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: OrgStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onInvite(
      OrgInviteMemberRequested event, Emitter<OrgState> emit) async {
    try {
      final member = await _repo.addMember(
        orgId: event.orgId,
        userId: event.userId,
        displayName: event.displayName,
        email: event.email,
        role: event.role,
      );
      if (state.selectedOrg?.id == event.orgId) {
        final members = [...?state.selectedOrg?.members, member];
        emit(state.copyWith(
          selectedOrg: state.selectedOrg?.copyWith(members: members),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
          status: OrgStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateRole(
      OrgUpdateMemberRoleRequested event, Emitter<OrgState> emit) async {
    try {
      await _repo.updateMemberRole(
          memberId: event.memberId, role: event.newRole);
      if (state.selectedOrg != null) {
        final members = state.selectedOrg!.members.map((m) {
          return m.id == event.memberId ? m.copyWith(role: event.newRole) : m;
        }).toList();
        emit(state.copyWith(
          selectedOrg: state.selectedOrg!.copyWith(members: members),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
          status: OrgStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onRemoveMember(
      OrgRemoveMemberRequested event, Emitter<OrgState> emit) async {
    try {
      await _repo.removeMember(event.memberId);
      if (state.selectedOrg != null) {
        final members = state.selectedOrg!.members
            .where((m) => m.id != event.memberId)
            .toList();
        emit(state.copyWith(
          selectedOrg: state.selectedOrg!.copyWith(members: members),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
          status: OrgStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateVault(
      OrgCreateVaultRequested event, Emitter<OrgState> emit) async {
    try {
      final vault = await _repo.createVault(
        orgId: event.orgId,
        name: event.name,
        createdByUserId: event.createdByUserId,
        description: event.description,
      );
      final vaults = [...state.orgVaults, vault];
      emit(state.copyWith(orgVaults: vaults));
    } catch (e) {
      emit(state.copyWith(
          status: OrgStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteVault(
      OrgDeleteVaultRequested event, Emitter<OrgState> emit) async {
    try {
      await _repo.deleteVault(event.vaultId);
      final vaults =
          state.orgVaults.where((v) => v.id != event.vaultId).toList();
      emit(state.copyWith(orgVaults: vaults));
    } catch (e) {
      emit(state.copyWith(
          status: OrgStatus.error, errorMessage: e.toString()));
    }
  }
}
