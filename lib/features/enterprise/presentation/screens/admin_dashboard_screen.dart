import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/org_role.dart';
import '../../domain/entities/organisation.dart';
import '../bloc/org_bloc.dart';
import '../bloc/org_event.dart';
import '../bloc/org_state.dart';

/// Admin dashboard â€” member management, activity log, security policies.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
          'ظ„ظˆط­ط© ط§ظ„ط¥ط¯ط§ط±ط©',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppConstants.primaryCyan,
          labelColor: AppConstants.primaryCyan,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'ط§ظ„ط£ط¹ط¶ط§ط،'),
            Tab(icon: Icon(Icons.history), text: 'ط³ط¬ظ„ ط§ظ„ظ†ط´ط§ط·'),
            Tab(icon: Icon(Icons.policy_outlined), text: 'ط§ظ„ط³ظٹط§ط³ط§طھ'),
          ],
        ),
      ),
      body: BlocBuilder<OrgBloc, OrgState>(
        builder: (context, state) {
          final org = state.selectedOrg;
          if (org == null) {
            return const Center(
              child: Text('ط§ط®طھط± ظ…ط¤ط³ط³ط© ط£ظˆظ„ط§ظ‹',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return TabBarView(
            controller: _tabs,
            children: [
              _MembersTab(org: org),
              _ActivityLogTab(orgId: org.id),
              _SecurityPoliciesTab(orgId: org.id),
            ],
          );
        },
      ),
    );
  }
}

// â”€â”€ Members Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MembersTab extends StatelessWidget {
  final Organisation org;
  const _MembersTab({required this.org});

  @override
  Widget build(BuildContext context) {
    final members = org.members;
    return Column(
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              _StatCard(
                  value: '${members.length}',
                  label: 'ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ط£ط¹ط¶ط§ط،',
                  icon: Icons.group,
                  color: AppConstants.primaryCyan),
              const SizedBox(width: 12),
              _StatCard(
                  value: '${members.where((m) => m.role == OrgRole.admin).length}',
                  label: 'ط§ظ„ظ…ط¯ط±ط§ط،',
                  icon: Icons.admin_panel_settings,
                  color: AppConstants.errorRed),
              const SizedBox(width: 12),
              _StatCard(
                  value: '${members.where((m) => m.role == OrgRole.manager).length}',
                  label: 'ط§ظ„ظ…ط´ط±ظپظˆظ†',
                  icon: Icons.manage_accounts,
                  color: AppConstants.accentGold),
            ],
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ط¨ط­ط« ط¹ظ† ط¹ط¶ظˆ...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
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
          ),
        ),
        // Member list
        Expanded(
          child: members.isEmpty
              ? const Center(
                  child: Text('ظ„ط§ ظٹظˆط¬ط¯ ط£ط¹ط¶ط§ط،',
                      style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: members.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (ctx, i) => _AdminMemberRow(
                    member: members[i],
                    onRoleChange: (role) => ctx.read<OrgBloc>().add(
                          OrgUpdateMemberRoleRequested(members[i].id, role)),
                    onRemove: () => ctx
                        .read<OrgBloc>()
                        .add(OrgRemoveMemberRequested(members[i].id)),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppConstants.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _AdminMemberRow extends StatelessWidget {
  final OrgMember member;
  final ValueChanged<OrgRole> onRoleChange;
  final VoidCallback onRemove;
  const _AdminMemberRow(
      {required this.member,
      required this.onRoleChange,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _roleColor(member.role).withValues(alpha: 0.15),
            child: Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: _roleColor(member.role),
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName.isNotEmpty
                      ? member.displayName
                      : member.email,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                Text(member.email,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          // Role badge + dropdown
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor(member.role).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<OrgRole>(
              value: member.role,
              dropdownColor: AppConstants.surfaceDark,
              underline: const SizedBox.shrink(),
              style: TextStyle(
                  color: _roleColor(member.role), fontSize: 11),
              items: OrgRole.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.labelAr),
                      ))
                  .toList(),
              onChanged: (r) {
                if (r != null) onRoleChange(r);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppConstants.errorRed, size: 20),
            onPressed: onRemove,
            tooltip: 'ط¥ط²ط§ظ„ط©',
          ),
        ],
      ),
    );
  }

  Color _roleColor(OrgRole role) {
    switch (role) {
      case OrgRole.admin:
        return AppConstants.errorRed;
      case OrgRole.manager:
        return AppConstants.accentGold;
      case OrgRole.member:
        return AppConstants.primaryCyan;
    }
  }
}

// â”€â”€ Activity Log Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActivityLogTab extends StatelessWidget {
  final String orgId;
  const _ActivityLogTab({required this.orgId});

  // Simulated activity entries for the org (in production: fetched from Supabase)
  static final _entries = [
    _ActivityEntry(
        icon: Icons.login,
        color: Color(0xFF06D6A0),
        title: 'طھط³ط¬ظٹظ„ ط¯ط®ظˆظ„',
        detail: 'user@example.com â€” ظ…ظ†ط° ط¯ظ‚ظٹظ‚طھظٹظ†'),
    _ActivityEntry(
        icon: Icons.person_add,
        color: Color(0xFF3B82F6),
        title: 'ط¥ط¶ط§ظپط© ط¹ط¶ظˆ',
        detail: 'ahmed@company.com â€” ظ…ظ†ط° ط³ط§ط¹ط©'),
    _ActivityEntry(
        icon: Icons.lock_reset,
        color: Color(0xFFFFAB00),
        title: 'طھط؛ظٹظٹط± ط¯ظˆط±',
        detail: 'ط¹ظڈظٹظ‘ظ† sara@company.com ظ…ط¯ظٹط±ط§ظ‹ â€” ظ…ظ†ط° 3 ط³ط§ط¹ط§طھ'),
    _ActivityEntry(
        icon: Icons.share,
        color: Color(0xFF8B5CF6),
        title: 'ظ…ط´ط§ط±ظƒط© ط®ط²ظٹظ†ط©',
        detail: '"ط®ط²ظٹظ†ط© ط§ظ„ط¥ظ†طھط§ط¬" ط´ط§ط±ظƒظ‡ط§ admin@company.com â€” ط£ظ…ط³'),
    _ActivityEntry(
        icon: Icons.delete_sweep,
        color: Color(0xFFFF3D57),
        title: 'ط­ط°ظپ ط¨ظ†ط¯',
        detail: 'ط­ظڈط°ظپ "Production DB" â€” ط£ظ…ط³ 14:30'),
    _ActivityEntry(
        icon: Icons.vpn_key,
        color: Color(0xFF00CEC9),
        title: 'ط¬ظ„ط³ط© SSO',
        detail: 'طھط³ط¬ظٹظ„ ط¯ط®ظˆظ„ ط¹ط¨ط± OIDC â€” ظ‚ط¨ظ„ ظٹظˆظ…ظٹظ†'),
  ];

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        separatorBuilder: (_, __) =>
            Divider(color: AppConstants.borderDark, height: 1),
        itemBuilder: (ctx, i) {
          final entry = _entries[i];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(entry.icon, color: entry.color, size: 20),
            ),
            title: Text(entry.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            subtitle: Text(entry.detail,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          );
        },
      );
}

class _ActivityEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  const _ActivityEntry(
      {required this.icon,
      required this.color,
      required this.title,
      required this.detail});
}

// â”€â”€ Security Policies Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SecurityPoliciesTab extends StatefulWidget {
  final String orgId;
  const _SecurityPoliciesTab({required this.orgId});
  @override
  State<_SecurityPoliciesTab> createState() => _SecurityPoliciesTabState();
}

class _SecurityPoliciesTabState extends State<_SecurityPoliciesTab> {
  bool _requireMfa = true;
  bool _require2Fa = true;
  int _minPasswordLength = 12;
  int _sessionTimeoutHours = 24;
  bool _allowWeakPasswords = false;
  bool _enforcePasswordRotation = false;
  int _passwordRotationDays = 90;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'ط§ظ„ظ…طµط§ط¯ظ‚ط©'),
        _PolicyToggle(
          title: 'ط·ظ„ط¨ ط§ظ„ظ…طµط§ط¯ظ‚ط© ط§ظ„ط¨ظٹظˆظ…طھط±ظٹط©',
          subtitle: 'FaceID / ط¨طµظ…ط© ط§ظ„ط¥طµط¨ط¹ ط¹ظ†ط¯ ظƒظ„ ظˆطµظˆظ„',
          value: _requireMfa,
          onChanged: (v) => setState(() => _requireMfa = v),
          activeColor: AppConstants.primaryCyan,
        ),
        _PolicyToggle(
          title: 'ط¥ظ„ط²ط§ظ…ظٹط© 2FA',
          subtitle: 'TOTP ط£ظˆ ظ…ظپطھط§ط­ ط£ظ…ط§ظ† ظ„ط¬ظ…ظٹط¹ ط§ظ„ط£ط¹ط¶ط§ط،',
          value: _require2Fa,
          onChanged: (v) => setState(() => _require2Fa = v),
          activeColor: AppConstants.primaryCyan,
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: 'ظƒظ„ظ…ط§طھ ط§ظ„ظ…ط±ظˆط±'),
        _PolicyToggle(
          title: 'ط§ظ„ط³ظ…ط§ط­ ط¨ظƒظ„ظ…ط§طھ ظ…ط±ظˆط± ط¶ط¹ظٹظپط©',
          subtitle: 'ظ…ظˆطµظ‰ ط¨ط¥ظٹظ‚ط§ظپظ‡ ظ„ظ„ط£ظ…ط§ظ† ط§ظ„ط£ظ…ط«ظ„',
          value: _allowWeakPasswords,
          onChanged: (v) => setState(() => _allowWeakPasswords = v),
          activeColor: AppConstants.errorRed,
        ),
        _PolicyToggle(
          title: 'طھط¯ظˆظٹط± ظƒظ„ظ…ط§طھ ط§ظ„ظ…ط±ظˆط± ط§ظ„ط¥ظ„ط²ط§ظ…ظٹ',
          subtitle: 'طھط°ظƒظٹط± ط¯ظˆط±ظٹ ط¨طھط؛ظٹظٹط± ظƒظ„ظ…ط§طھ ط§ظ„ظ…ط±ظˆط±',
          value: _enforcePasswordRotation,
          onChanged: (v) => setState(() => _enforcePasswordRotation = v),
          activeColor: AppConstants.accentGold,
        ),
        if (_enforcePasswordRotation) ...[
          const SizedBox(height: 12),
          _SliderPolicy(
            label: 'طھط¯ظˆظٹط± ظƒظ„ $_passwordRotationDays ظٹظˆظ…',
            value: _passwordRotationDays.toDouble(),
            min: 30,
            max: 365,
            divisions: 11,
            onChanged: (v) => setState(() => _passwordRotationDays = v.round()),
          ),
        ],
        const SizedBox(height: 8),
        _SliderPolicy(
          label: 'ط§ظ„ط­ط¯ ط§ظ„ط£ط¯ظ†ظ‰ ظ„ط·ظˆظ„ ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط±: $_minPasswordLength ط­ط±ظپ',
          value: _minPasswordLength.toDouble(),
          min: 8,
          max: 32,
          divisions: 24,
          onChanged: (v) => setState(() => _minPasswordLength = v.round()),
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: 'ط§ظ„ط¬ظ„ط³ط©'),
        _SliderPolicy(
          label: 'ط§ظ†طھظ‡ط§ط، ط§ظ„ط¬ظ„ط³ط© ط¨ط¹ط¯: $_sessionTimeoutHours ط³ط§ط¹ط©',
          value: _sessionTimeoutHours.toDouble(),
          min: 1,
          max: 72,
          divisions: 71,
          onChanged: (v) => setState(() => _sessionTimeoutHours = v.round()),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryCyan,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('طھظ… ط­ظپط¸ ط§ظ„ط³ظٹط§ط³ط§طھ ط¨ظ†ط¬ط§ط­'),
                backgroundColor: AppConstants.successGreen,
              ),
            );
          },
          child: const Text('ط­ظپط¸ ط§ظ„ط³ظٹط§ط³ط§طھ',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: AppConstants.primaryCyan,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );
}

class _PolicyToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  const _PolicyToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.borderDark),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          value: value,
          activeThumbColor: activeColor,
          onChanged: onChanged,
        ),
      );
}

class _SliderPolicy extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  const _SliderPolicy({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: AppConstants.primaryCyan,
              inactiveColor: AppConstants.borderDark,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}
