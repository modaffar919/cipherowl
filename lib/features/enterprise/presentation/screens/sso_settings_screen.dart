import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../../domain/entities/sso_config.dart';

/// SSO settings screen — configure OIDC, SAML 2.0, and LDAP/AD.
class SsoSettingsScreen extends StatefulWidget {
  const SsoSettingsScreen({super.key});

  @override
  State<SsoSettingsScreen> createState() => _SsoSettingsScreenState();
}

class _SsoSettingsScreenState extends State<SsoSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: SsoProvider.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text(
          'إعدادات SSO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppConstants.primaryCyan,
          labelColor: AppConstants.primaryCyan,
          unselectedLabelColor: Colors.white54,
          tabs: SsoProvider.values
              .map((p) => Tab(text: _shortLabel(p)))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OidcConfigPanel(),
          _SamlConfigPanel(),
          _LdapConfigPanel(),
        ],
      ),
    );
  }

  String _shortLabel(SsoProvider p) {
    switch (p) {
      case SsoProvider.oidc:
        return 'OIDC';
      case SsoProvider.saml:
        return 'SAML';
      case SsoProvider.ldap:
        return 'LDAP';
    }
  }
}

// ── OIDC Panel ────────────────────────────────────────────────────────────────

class _OidcConfigPanel extends StatefulWidget {
  @override
  State<_OidcConfigPanel> createState() => _OidcConfigPanelState();
}

class _OidcConfigPanelState extends State<_OidcConfigPanel> {
  bool _enabled = false;
  final _clientIdCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _discoveryCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => _ConfigForm(
    provider: SsoProvider.oidc,
    isEnabled: _enabled,
    onToggle: (v) => setState(() => _enabled = v),
    onSave: () => _save(context),
    fields: [
      _DarkField(ctrl: _clientIdCtrl, label: 'Client ID'),
      _DarkField(ctrl: _secretCtrl, label: 'Client Secret', obscure: true),
      _DarkField(
        ctrl: _discoveryCtrl,
        label: 'Discovery URL',
        hint: 'https://accounts.google.com/.well-known/openid-configuration',
        keyboardType: TextInputType.url,
      ),
    ],
  );

  void _save(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('تم حفظ إعدادات OIDC'),
          backgroundColor: AppConstants.successGreen),
    );
  }
}

// ── SAML Panel ────────────────────────────────────────────────────────────────

class _SamlConfigPanel extends StatefulWidget {
  @override
  State<_SamlConfigPanel> createState() => _SamlConfigPanelState();
}

class _SamlConfigPanelState extends State<_SamlConfigPanel> {
  bool _enabled = false;
  final _entityIdCtrl = TextEditingController();
  final _ssoUrlCtrl = TextEditingController();
  final _certCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => _ConfigForm(
    provider: SsoProvider.saml,
    isEnabled: _enabled,
    onToggle: (v) => setState(() => _enabled = v),
    onSave: () => _save(context),
    fields: [
      _DarkField(ctrl: _entityIdCtrl, label: 'Entity ID (IdP Issuer)'),
      _DarkField(
        ctrl: _ssoUrlCtrl,
        label: 'SSO URL (IdP)',
        keyboardType: TextInputType.url,
      ),
      _DarkField(
        ctrl: _certCtrl,
        label: 'X.509 Certificate (PEM)',
        maxLines: 5,
        hint: '-----BEGIN CERTIFICATE-----\n...',
      ),
    ],
  );

  void _save(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('تم حفظ إعدادات SAML'),
          backgroundColor: AppConstants.successGreen),
    );
  }
}

// ── LDAP Panel ────────────────────────────────────────────────────────────────

class _LdapConfigPanel extends StatefulWidget {
  @override
  State<_LdapConfigPanel> createState() => _LdapConfigPanelState();
}

class _LdapConfigPanelState extends State<_LdapConfigPanel> {
  bool _enabled = false;
  bool _useSsl = true;
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '636');
  final _bindDnCtrl = TextEditingController();
  final _baseDnCtrl = TextEditingController();
  final _bindPassCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => _ConfigForm(
    provider: SsoProvider.ldap,
    isEnabled: _enabled,
    onToggle: (v) => setState(() => _enabled = v),
    onSave: () => _save(context),
    fields: [
      _DarkField(ctrl: _hostCtrl, label: 'LDAP Host', hint: 'ldap.company.com'),
      _DarkField(
        ctrl: _portCtrl,
        label: 'Port',
        keyboardType: TextInputType.number,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('استخدام SSL/TLS',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        value: _useSsl,
        activeColor: AppConstants.primaryCyan,
        onChanged: (v) => setState(() {
          _useSsl = v;
          _portCtrl.text = v ? '636' : '389';
        }),
      ),
      _DarkField(
        ctrl: _bindDnCtrl,
        label: 'Bind DN',
        hint: 'cn=admin,dc=company,dc=com',
      ),
      _DarkField(ctrl: _bindPassCtrl, label: 'Bind Password', obscure: true),
      _DarkField(
        ctrl: _baseDnCtrl,
        label: 'Base DN',
        hint: 'dc=company,dc=com',
      ),
    ],
  );

  void _save(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('تم حفظ إعدادات LDAP'),
          backgroundColor: AppConstants.successGreen),
    );
  }
}

// ── Shared form wrapper ───────────────────────────────────────────────────────

class _ConfigForm extends StatelessWidget {
  final SsoProvider provider;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSave;
  final List<Widget> fields;

  const _ConfigForm({
    required this.provider,
    required this.isEnabled,
    required this.onToggle,
    required this.onSave,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConstants.primaryCyan.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vpn_key, color: AppConstants.primaryCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(provider.labelAr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                    Switch(
                      value: isEnabled,
                      activeColor: AppConstants.primaryCyan,
                      onChanged: onToggle,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(provider.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          if (!isEnabled)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('فعّل المزوّد أولاً لتكوينه',
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
              ),
            )
          else ...[
            const SizedBox(height: 20),
            ...fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: f,
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onSave,
                child: const Text('حفظ الإعدادات',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboardType;
  const _DarkField({
    required this.ctrl,
    required this.label,
    this.hint,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    obscureText: obscure,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
      filled: true,
      fillColor: AppConstants.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppConstants.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppConstants.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppConstants.primaryCyan),
      ),
    ),
  );
}
