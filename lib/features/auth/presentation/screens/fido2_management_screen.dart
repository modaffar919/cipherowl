import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/core/platform/platform_info.dart';
import 'package:cipherowl/features/auth/data/services/fido2_credential_service.dart';

/// Screen for managing FIDO2 passkeys (list, add, delete).
class Fido2ManagementScreen extends StatefulWidget {
  const Fido2ManagementScreen({super.key});

  @override
  State<Fido2ManagementScreen> createState() => _Fido2ManagementScreenState();
}

class _Fido2ManagementScreenState extends State<Fido2ManagementScreen> {
  late final Fido2CredentialService _service;
  late Future<List<Fido2CredentialInfo>> _credentialsFuture;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _service = Fido2CredentialService();
    _reload();
  }

  void _reload() {
    setState(() {
      _credentialsFuture = _service.listCredentials();
    });
  }

  String get _deviceName {
    if (PlatformInfo.isAndroid) return 'Android';
    if (PlatformInfo.isIOS) return 'iPhone';
    if (PlatformInfo.isWindows) return 'Windows';
    if (PlatformInfo.isMacOS) return 'macOS';
    if (PlatformInfo.isWeb) return 'Web';
    return '\u0647\u0630\u0627 \u0627\u0644\u062C\u0647\u0627\u0632';
  }

  // ── Add credential ─────────────────────────────────────────────────────────

  Future<void> _addCredential() async {
    setState(() => _isAdding = true);
    try {
      await _service.registerCredential(friendlyName: _deviceName);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل المفتاح بنجاح'),
            backgroundColor: AppConstants.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التسجيل: $e'),
            backgroundColor: AppConstants.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  // ── Delete credential ──────────────────────────────────────────────────────

  Future<void> _deleteCredential(Fido2CredentialInfo cred) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        title: const Text('حذف المفتاح؟',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'سيتم حذف "${cred.friendlyName}" نهائيًا. لن تتمكن من '
          'استخدامه لتسجيل الدخول بعد الآن.',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء',
                style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppConstants.errorRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteCredential(cred.id);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المفتاح'),
            backgroundColor: AppConstants.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحذف: $e'),
            backgroundColor: AppConstants.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppConstants.backgroundDark,
            pinned: true,
            title: const Text(
              'مفاتيح FIDO2',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            centerTitle: false,
            actions: [
              if (_isAdding)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryCyan,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.add, color: AppConstants.primaryCyan),
                  tooltip: 'إضافة مفتاح جديد',
                  onPressed: _addCredential,
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryCyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppConstants.primaryCyan.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security,
                            color: AppConstants.primaryCyan, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'مفاتيح FIDO2 تتيح لك فتح الخزنة بدون كلمة مرور '
                            'باستخدام Ed25519. المفتاح الخاص محفوظ على هذا '
                            'الجهاز فقط.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Credentials list
                  FutureBuilder<List<Fido2CredentialInfo>>(
                    future: _credentialsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(
                                color: AppConstants.primaryCyan),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _ErrorView(
                            message: snapshot.error.toString(),
                            onRetry: _reload);
                      }

                      final creds = snapshot.data ?? [];
                      if (creds.isEmpty) {
                        return _EmptyView(onAdd: _isAdding ? null : _addCredential);
                      }

                      return Column(
                        children: creds
                            .map((c) => _CredentialCard(
                                  credential: c,
                                  onDelete: () => _deleteCredential(c),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Credential card ──────────────────────────────────────────────────────────

class _CredentialCard extends StatelessWidget {
  final Fido2CredentialInfo credential;
  final VoidCallback onDelete;

  const _CredentialCard({
    required this.credential,
    required this.onDelete,
  });

  IconData get _osIcon {
    switch (credential.deviceOs) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      default:
        return Icons.devices;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppConstants.primaryCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_osIcon, color: AppConstants.primaryCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credential.friendlyName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'أُنشئ ${_formatDate(credential.createdAt)}'
                  '${credential.lastUsedAt != null ? ' · آخر استخدام ${_formatDate(credential.lastUsedAt!)}' : ''}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                Text(
                  'عدد الاستخدامات: ${credential.signCount}',
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppConstants.errorRed, size: 20),
            tooltip: 'حذف المفتاح',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback? onAdd;
  const _EmptyView({this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppConstants.primaryCyan.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.key_off_outlined,
                  color: AppConstants.primaryCyan, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مفاتيح FIDO2 مسجلة',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف مفتاحًا لتتمكن من فتح الخزنة\nبدون كلمة مرور',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (onAdd != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryCyan,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة مفتاح جديد',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppConstants.errorRed, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh,
                  color: AppConstants.primaryCyan, size: 16),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(color: AppConstants.primaryCyan)),
            ),
          ],
        ),
      ),
    );
  }
}
