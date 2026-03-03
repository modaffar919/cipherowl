import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

/// Vault Item Detail Screen
class VaultItemDetailScreen extends StatelessWidget {
  final String itemId;
  const VaultItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    // TODO: Load from drift by itemId
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text('تفاصيل الحساب', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppConstants.primaryCyan),
            onPressed: () => context.go('/vault/$itemId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppConstants.errorRed),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          _SectionHeader(title: 'Google', icon: '🔵'),
          const SizedBox(height: 24),

          // Fields
          _FieldCard(label: 'اسم المستخدم', value: 'user@gmail.com', copyable: true),
          _PasswordFieldCard(label: 'كلمة المرور', value: 'SecureP@ss123!'),
          _FieldCard(label: 'الموقع الإلكتروني', value: 'https://accounts.google.com', copyable: true),
          _FieldCard(label: 'ملاحظات', value: 'الحساب الرئيسي'),

          const SizedBox(height: 24),

          // TOTP
          _TotpCard(),

          const SizedBox(height: 24),

          // Security info
          _SecurityInfoCard(strength: 95, lastChanged: '2025-01-10'),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        title: const Text('حذف الحساب؟', style: TextStyle(color: Colors.white)),
        content: const Text('لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorRed),
            onPressed: () {
              Navigator.pop(context);
              context.go(AppConstants.routeVault);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppConstants.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 30))),
        ),
        const SizedBox(width: 16),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _FieldCard({required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white38, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ'), duration: Duration(seconds: 2)),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PasswordFieldCard extends StatefulWidget {
  final String label;
  final String value;
  const _PasswordFieldCard({required this.label, required this.value});
  @override
  State<_PasswordFieldCard> createState() => _PasswordFieldCardState();
}

class _PasswordFieldCardState extends State<_PasswordFieldCard> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _visible ? widget.value : '•' * widget.value.length,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'SpaceMono'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_visible ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
            onPressed: () => setState(() => _visible = !_visible),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white38, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ كلمة المرور — تمسح خلال 30 ثانية'), duration: Duration(seconds: 2)),
              );
              // TODO: clear clipboard after 30s
            },
          ),
        ],
      ),
    );
  }
}

class _TotpCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryCyan.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.primaryCyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, color: AppConstants.primaryCyan, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('رمز التحقق (2FA)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                SizedBox(height: 4),
                Text('483 721', style: TextStyle(color: AppConstants.primaryCyan, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'SpaceMono', letterSpacing: 4)),
              ],
            ),
          ),
          // Countdown circle
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: 0.6,
              backgroundColor: AppConstants.borderDark,
              color: AppConstants.primaryCyan,
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityInfoCard extends StatelessWidget {
  final int strength;
  final String lastChanged;
  const _SecurityInfoCard({required this.strength, required this.lastChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('معلومات الأمان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'قوة كلمة المرور', value: '$strength%', color: AppConstants.successGreen)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'آخر تغيير', value: lastChanged, color: Colors.white60)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}
