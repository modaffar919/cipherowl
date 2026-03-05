import 'package:equatable/equatable.dart';

import '../../domain/entities/organisation.dart';

enum OrgStatus { initial, loading, loaded, error }

class OrgState extends Equatable {
  final OrgStatus status;
  final List<Organisation> orgs;
  final Organisation? selectedOrg;
  final List<OrgVault> orgVaults;
  final String? errorMessage;

  const OrgState({
    this.status = OrgStatus.initial,
    this.orgs = const [],
    this.selectedOrg,
    this.orgVaults = const [],
    this.errorMessage,
  });

  OrgState copyWith({
    OrgStatus? status,
    List<Organisation>? orgs,
    Organisation? selectedOrg,
    List<OrgVault>? orgVaults,
    String? errorMessage,
  }) =>
      OrgState(
        status: status ?? this.status,
        orgs: orgs ?? this.orgs,
        selectedOrg: selectedOrg ?? this.selectedOrg,
        orgVaults: orgVaults ?? this.orgVaults,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, orgs, selectedOrg, orgVaults, errorMessage];
}
