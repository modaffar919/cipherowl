part of 'security_bloc.dart';

abstract class SecurityEvent {
  const SecurityEvent();
}

/// Compute score and recommendations from the current vault items.
class SecurityScoreRequested extends SecurityEvent {
  final List<VaultEntry> items;
  const SecurityScoreRequested(this.items);
}

/// Refresh score whenever vault changes (called from VaultBloc listener).
class SecurityVaultUpdated extends SecurityEvent {
  final List<VaultEntry> items;
  const SecurityVaultUpdated(this.items);
}
