import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/sso_config.dart';

/// Service for persisting and retrieving SSO configurations.
///
/// Table required (supabase/migrations/005_sso_config.sql):
///   sso_configs (id, org_id, provider, is_enabled, ...fields, updated_at)
class SsoConfigService {
  final SupabaseClient _client;
  static const _uuid = Uuid();

  SsoConfigService(this._client);

  Future<SsoConfig?> getConfig(String orgId, SsoProvider provider) async {
    final rows = await _client
        .from('sso_configs')
        .select()
        .eq('org_id', orgId)
        .eq('provider', provider.name)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return SsoConfig.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<SsoConfig> saveConfig(SsoConfig config) async {
    final now = DateTime.now().toUtc();
    final updated = config.copyWith(updatedAt: now);
    await _client.from('sso_configs').upsert(updated.toJson());
    return updated;
  }

  Future<List<SsoConfig>> getAllConfigs(String orgId) async {
    final rows = await _client
        .from('sso_configs')
        .select()
        .eq('org_id', orgId);
    return (rows as List)
        .map((r) => SsoConfig.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleEnabled(String configId, bool enabled) async {
    await _client
        .from('sso_configs')
        .update({'is_enabled': enabled, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', configId);
  }

  /// Create a default (disabled) config for a provider if none exists.
  Future<SsoConfig> ensureConfig(String orgId, SsoProvider provider) async {
    final existing = await getConfig(orgId, provider);
    if (existing != null) return existing;
    final config = SsoConfig(
      id: _uuid.v4(),
      orgId: orgId,
      provider: provider,
      updatedAt: DateTime.now().toUtc(),
    );
    await _client.from('sso_configs').insert(config.toJson());
    return config;
  }
}
