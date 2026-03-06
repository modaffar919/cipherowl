import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/org_role.dart';
import '../../domain/entities/organisation.dart';
import '../bloc/org_bloc.dart';
import '../bloc/org_event.dart';
import '../bloc/org_state.dart';

/// Enterprise screen -- shows the user's organisations and their shared vaults.
class EnterpriseScreen extends StatelessWidget {
  const EnterpriseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrgBloc, OrgState>(
      listener: (context, state) {
        if (state.status == OrgStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppConstants.errorRed,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppConstants.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppConstants.backgroundDark,
            title: const Text(
              'وضع المؤسسة',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.dashboard_customize, color: Colors.white70),
                tooltip: 'لوحة الإدارة',
                onPressed: () => context.push(AppConstants.routeAdminDashboard),
              ),
              IconButton(
                icon: const Icon(Icons.vpn_key_outlined, color: Colors.white70),
                tooltip: 'إعدادات SSO',
                onPressed: () => context.push(AppConstants.routeSsoSettings),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppConstants.primaryCyan,
            onPressed: () => _showCreateOrgSheet(context),
            icon: const Icon(Icons.add_business, color: Colors.black),
            label: const Text('مؤسسة جديدة',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
          body: state.status == OrgStatus.loading
              ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryCyan))
              : state.orgs.isEmpty
                  ? _EmptyState(onCreateOrg: () => _showCreateOrgSheet(context))
                  : _OrgList(orgs: state.orgs),
        );
      },
    );
  }

  void _showCreateOrgSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إنشاء مؤسسة جديدة',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _DarkTextField(controller: nameCtrl, label: 'اسم المؤسسة'),
            const SizedBox(height: 12),
            _DarkTextField(controller: descCtrl, label: 'الوصف (اختياري)', maxLines: 2),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  context.read<OrgBloc>().add(OrgCreateRequested(
                    ownerId: 'current_user_id',
                    name: name,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  ));
                  Navigator.of(ctx).pop();
                },
                child: const Text('إنشاء',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Sub-widgets --------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateOrg;
  const _EmptyState({required this.onCreateOrg});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppConstants.primaryCyan.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.business, color: AppConstants.primaryCyan, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('لا توجد مؤسسات بعد',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('أنشئ مؤسستك لبدء إدارة\nخزائن الفريق المشتركة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryCyan,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onCreateOrg,
          icon: const Icon(Icons.add_business, color: Colors.black, size: 20),
          label: const Text('إنشاء مؤسسة',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

class _OrgList extends StatelessWidget {
  final List<Organisation> orgs;
  const _OrgList({required this.orgs});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrgBloc, OrgState>(
      builder: (context, state) {
        final selectedId = state.selectedOrg?.id;
        return Row(
          children: [
            Container(
              width: 200,
              color: AppConstants.surfaceDark,
              child: ListView.builder(
                itemCount: orgs.length,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                itemBuilder: (ctx, i) {
                  final org = orgs[i];
                  final isSelected = org.id == selectedId;
                  return _OrgTile(
                    org: org,
                    isSelected: isSelected,
                    onTap: () => context.read<OrgBloc>().add(OrgSelected(org.id)),
                  );
                },
              ),
            ),
            Expanded(
              child: selectedId == null
                  ? const _SelectOrgHint()
                  : _OrgDetail(org: state.selectedOrg!, vaults: state.orgVaults),
            ),
          ],
        );
      },
    );
  }
}

class _OrgTile extends StatelessWidget {
  final Organisation org;
  final bool isSelected;
  final VoidCallback onTap;
  const _OrgTile({required this.org, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppConstants.primaryCyan.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppConstants.primaryCyan.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppConstants.primaryCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business, color: AppConstants.primaryCyan, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(org.name,
              style: TextStyle(
                color: isSelected ? AppConstants.primaryCyan : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SelectOrgHint extends StatelessWidget {
  const _SelectOrgHint();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('اختر مؤسسة من القائمة',
        style: TextStyle(color: Colors.white38, fontSize: 15)),
  );
}

class _OrgDetail extends StatelessWidget {
  final Organisation org;
  final List<OrgVault> vaults;
  const _OrgDetail({required this.org, required this.vaults});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, color: AppConstants.primaryCyan, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(org.name,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          if (org.description != null)
                            Text(org.description!,
                                style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  _StatChip(label: ' أعضاء', icon: Icons.people),
                  const SizedBox(width: 10),
                  _StatChip(label: ' خزائن', icon: Icons.lock_outline),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // Vaults header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الخزائن المشتركة',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => _showCreateVaultSheet(context),
                  icon: const Icon(Icons.add, color: AppConstants.primaryCyan, size: 18),
                  label: const Text('إضافة', style: TextStyle(color: AppConstants.primaryCyan)),
                ),
              ],
            ),
          ),
        ),
        if (vaults.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text('لا توجد خزائن مشتركة بعد.',
                  style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _VaultTile(
                vault: vaults[i],
                onDelete: () => ctx.read<OrgBloc>().add(OrgDeleteVaultRequested(vaults[i].id)),
              ),
              childCount: vaults.length,
            ),
          ),
        // Members header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الأعضاء',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => _showInviteSheet(context),
                  icon: const Icon(Icons.person_add_alt_1, color: AppConstants.primaryCyan, size: 18),
                  label: const Text('دعوة', style: TextStyle(color: AppConstants.primaryCyan)),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _MemberTile(
              member: org.members[i],
              onRoleChange: (role) => ctx.read<OrgBloc>().add(
                    OrgUpdateMemberRoleRequested(org.members[i].id, role)),
              onRemove: () =>
                  ctx.read<OrgBloc>().add(OrgRemoveMemberRequested(org.members[i].id)),
            ),
            childCount: org.members.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  void _showCreateVaultSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('خزينة مشتركة جديدة',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _DarkTextField(controller: nameCtrl, label: 'اسم الخزينة'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  context.read<OrgBloc>().add(OrgCreateVaultRequested(
                    orgId: org.id,
                    name: name,
                    createdByUserId: 'current_user_id',
                  ));
                  Navigator.of(ctx).pop();
                },
                child: const Text('إنشاء',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    OrgRole selectedRole = OrgRole.member;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('دعوة عضو',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _DarkTextField(controller: nameCtrl, label: 'الاسم'),
              const SizedBox(height: 12),
              _DarkTextField(
                  controller: emailCtrl,
                  label: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.borderDark),
                ),
                child: DropdownButton<OrgRole>(
                  value: selectedRole,
                  isExpanded: true,
                  dropdownColor: AppConstants.surfaceDark,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(color: Colors.white),
                  items: OrgRole.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.labelAr)))
                      .toList(),
                  onChanged: (r) { if (r != null) setState(() => selectedRole = r); },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryCyan,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final email = emailCtrl.text.trim();
                    if (email.isEmpty) return;
                    context.read<OrgBloc>().add(OrgInviteMemberRequested(
                      orgId: org.id,
                      userId: 'invited_user_id',
                      displayName: nameCtrl.text.trim(),
                      email: email,
                      role: selectedRole,
                    ));
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('دعوة',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppConstants.cardDark,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppConstants.borderDark),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    ),
  );
}

class _VaultTile extends StatelessWidget {
  final OrgVault vault;
  final VoidCallback onDelete;
  const _VaultTile({required this.vault, required this.onDelete});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppConstants.accentGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_outline, color: AppConstants.accentGold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vault.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                if (vault.description != null)
                  Text(vault.description!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    ),
  );
}

class _MemberTile extends StatelessWidget {
  final OrgMember member;
  final ValueChanged<OrgRole> onRoleChange;
  final VoidCallback onRemove;
  const _MemberTile({required this.member, required this.onRoleChange, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppConstants.primaryCyan.withValues(alpha: 0.15),
            child: Text(
              member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppConstants.primaryCyan, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName.isNotEmpty ? member.displayName : member.email,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(member.email, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          DropdownButton<OrgRole>(
            value: member.role,
            dropdownColor: AppConstants.surfaceDark,
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            items: OrgRole.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.labelAr)))
                .toList(),
            onChanged: (r) { if (r != null) onRoleChange(r); },
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppConstants.errorRed, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    ),
  );
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  const _DarkTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
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
