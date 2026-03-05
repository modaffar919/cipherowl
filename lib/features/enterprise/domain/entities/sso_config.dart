/// Supported enterprise SSO provider types.
enum SsoProvider {
  oidc,
  saml,
  ldap;

  String get labelAr {
    switch (this) {
      case oidc:
        return 'OpenID Connect (OIDC)';
      case saml:
        return 'SAML 2.0';
      case ldap:
        return 'LDAP / Active Directory';
    }
  }

  String get description {
    switch (this) {
      case oidc:
        return 'دمج مع Google Workspace, Azure AD, Okta, Auth0';
      case saml:
        return 'تسجيل دخول موحد للتطبيقات المؤسسية';
      case ldap:
        return 'مزامنة مع دليل الشركة لإدارة المستخدمين';
    }
  }
}

/// Configuration for an enterprise SSO provider.
class SsoConfig {
  final String id;
  final String orgId;
  final SsoProvider provider;
  final bool isEnabled;

  // OIDC / OAuth2 fields
  final String? oidcClientId;
  final String? oidcClientSecret;
  final String? oidcDiscoveryUrl;

  // SAML fields
  final String? samlEntityId;
  final String? samlSsoUrl;
  final String? samlCertificate;

  // LDAP fields
  final String? ldapHost;
  final int? ldapPort;
  final String? ldapBindDn;
  final String? ldapBaseDn;
  final bool ldapUseSsl;

  final DateTime updatedAt;

  const SsoConfig({
    required this.id,
    required this.orgId,
    required this.provider,
    this.isEnabled = false,
    this.oidcClientId,
    this.oidcClientSecret,
    this.oidcDiscoveryUrl,
    this.samlEntityId,
    this.samlSsoUrl,
    this.samlCertificate,
    this.ldapHost,
    this.ldapPort,
    this.ldapBindDn,
    this.ldapBaseDn,
    this.ldapUseSsl = true,
    required this.updatedAt,
  });

  SsoConfig copyWith({
    String? id,
    String? orgId,
    SsoProvider? provider,
    bool? isEnabled,
    String? oidcClientId,
    String? oidcClientSecret,
    String? oidcDiscoveryUrl,
    String? samlEntityId,
    String? samlSsoUrl,
    String? samlCertificate,
    String? ldapHost,
    int? ldapPort,
    String? ldapBindDn,
    String? ldapBaseDn,
    bool? ldapUseSsl,
    DateTime? updatedAt,
  }) =>
      SsoConfig(
        id: id ?? this.id,
        orgId: orgId ?? this.orgId,
        provider: provider ?? this.provider,
        isEnabled: isEnabled ?? this.isEnabled,
        oidcClientId: oidcClientId ?? this.oidcClientId,
        oidcClientSecret: oidcClientSecret ?? this.oidcClientSecret,
        oidcDiscoveryUrl: oidcDiscoveryUrl ?? this.oidcDiscoveryUrl,
        samlEntityId: samlEntityId ?? this.samlEntityId,
        samlSsoUrl: samlSsoUrl ?? this.samlSsoUrl,
        samlCertificate: samlCertificate ?? this.samlCertificate,
        ldapHost: ldapHost ?? this.ldapHost,
        ldapPort: ldapPort ?? this.ldapPort,
        ldapBindDn: ldapBindDn ?? this.ldapBindDn,
        ldapBaseDn: ldapBaseDn ?? this.ldapBaseDn,
        ldapUseSsl: ldapUseSsl ?? this.ldapUseSsl,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory SsoConfig.fromJson(Map<String, dynamic> json) => SsoConfig(
        id: json['id'] as String,
        orgId: json['org_id'] as String,
        provider: SsoProvider.values.firstWhere(
          (p) => p.name == json['provider'],
          orElse: () => SsoProvider.oidc,
        ),
        isEnabled: json['is_enabled'] as bool? ?? false,
        oidcClientId: json['oidc_client_id'] as String?,
        oidcClientSecret: json['oidc_client_secret'] as String?,
        oidcDiscoveryUrl: json['oidc_discovery_url'] as String?,
        samlEntityId: json['saml_entity_id'] as String?,
        samlSsoUrl: json['saml_sso_url'] as String?,
        samlCertificate: json['saml_certificate'] as String?,
        ldapHost: json['ldap_host'] as String?,
        ldapPort: json['ldap_port'] as int?,
        ldapBindDn: json['ldap_bind_dn'] as String?,
        ldapBaseDn: json['ldap_base_dn'] as String?,
        ldapUseSsl: json['ldap_use_ssl'] as bool? ?? true,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'provider': provider.name,
        'is_enabled': isEnabled,
        if (oidcClientId != null) 'oidc_client_id': oidcClientId,
        if (oidcClientSecret != null) 'oidc_client_secret': oidcClientSecret,
        if (oidcDiscoveryUrl != null) 'oidc_discovery_url': oidcDiscoveryUrl,
        if (samlEntityId != null) 'saml_entity_id': samlEntityId,
        if (samlSsoUrl != null) 'saml_sso_url': samlSsoUrl,
        if (samlCertificate != null) 'saml_certificate': samlCertificate,
        if (ldapHost != null) 'ldap_host': ldapHost,
        if (ldapPort != null) 'ldap_port': ldapPort,
        if (ldapBindDn != null) 'ldap_bind_dn': ldapBindDn,
        if (ldapBaseDn != null) 'ldap_base_dn': ldapBaseDn,
        'ldap_use_ssl': ldapUseSsl,
        'updated_at': updatedAt.toIso8601String(),
      };
}
