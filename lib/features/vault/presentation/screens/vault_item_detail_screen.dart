import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cipherowl/src/rust/frb_generated.dart/api.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/core/crypto/vault_crypto_service.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';

/// Full detail view for a single vault entry.
/// Loads real data from [VaultBloc]. Decrypts password on reveal via [VaultCryptoService].
class VaultItemDetailScreen extends StatefulWidget {
  final String itemId;
  const VaultItemDetailScreen({super.key, required this.itemId});

  @override
  State<VaultItemDetailScreen> createState() => _VaultItemDetailScreenState();
}

class _VaultItemDetailScreenState extends State<VaultItemDetailScreen> {
  VaultEntry? _entry;
  String? _decryptedPassword;
  bool _passwordDecrypted = false;
  bool _passwordVisible = false;
  bool _isDecrypting = false;

  // TOTP
  String? _totpSecret; // decrypted Base32 secret
  String _totpCode = '------';
  int _totpSecondsLeft = 30;
  Timer? _totpTimer;
  bool _isLoadingTotp = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEntry();
  }

  @override
  void dispose() {
    _totpTimer?.cancel();
    super.dispose();
  }

  Future<void> _initTotp(VaultEntry entry) async {
    if (entry.encryptedTotpSecret == null) return;
    if (_totpSecret != null) return; // already loaded
    setState(() => _isLoadingTotp = true);
    try {
      final crypto = context.read<VaultCryptoService>();
      final secret = await crypto.decrypt(entry.encryptedTotpSecret!);
      if (!mounted) return;
      setState(() {
        _totpSecret = secret;
        _isLoadingTotp = false;
      });
      _refreshTotp();
      _totpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _refreshTotp();
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingTotp = false);
    }
  }

  void _refreshTotp() {
    final secret = _totpSecret;
    if (secret == null) return;
    final nowSecs = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    try {
      final code = apiTotpGenerate(secretBase32: secret, timestampSecs: nowSecs);
      final secsLeft = apiTotpTimeRemaining(timestampSecs: nowSecs).toInt();
      if (mounted) setState(() { _totpCode = code; _totpSecondsLeft = secsLeft; });
    } catch (_) {
      if (mounted) setState(() => _totpCode = 'خطأ');
    }
  }

  void _loadEntry() {
    final state = context.read<VaultBloc>().state;
    if (state is VaultLoaded) {
      final found = state.allItems.where((i) => i.id == widget.itemId).firstOrNull;
      if (found != null) {
        setState(() => _entry = found);
        if (found.encryptedTotpSecret != null) _initTotp(found);
      }
    }
  }

  Future<void> _revealPassword() async {
    if (_passwordDecrypted) {
      setState(() => _passwordVisible = !_passwordVisible);
      return;
    }
    final entry = _entry;
    if (entry?.encryptedPassword == null || entry!.encryptedPassword!.isEmpty) {
      setState(() {
        _decryptedPassword = '';
        _passwordDecrypted = true;
        _passwordVisible = true;
      });
      return;
    }
    setState(() => _isDecrypting = true);
    try {
      final crypto = context.read<VaultCryptoService>();
      final pwd = await crypto.decrypt(Uint8List.fromList(entry.encryptedPassword!));
      if (mounted) {
        setState(() {
          _decryptedPassword = pwd;
          _passwordDecrypted = true;
          _passwordVisible = true;
          _isDecrypting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDecrypting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فك تشفير كلمة المرور')),
        );
      }
    }
  }

  void _copyPassword() {
    if (!_passwordDecrypted || _decryptedPassword == null) {
      _revealPassword().then((_) => _doCopyPassword());
      return;
    }
    _doCopyPassword();
  }

  void _doCopyPassword() {
    if (_decryptedPassword == null) return;
    Clipboard.setData(ClipboardData(text: _decryptedPassword!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ كلمة المرور — تُمسح خلال 30 ثانية'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 30), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  void _confirmDelete(BuildContext ctx) {
    final vaultBloc = ctx.read<VaultBloc>();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        title: const Text('حذف الحساب؟', style: TextStyle(color: Colors.white)),
        content: Text('سيتم حذف "${_entry?.title ?? '...'}" نهائياً.',
            style: const TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorRed),
            onPressed: () {
              Navigator.pop(ctx);
              vaultBloc.add(VaultItemDeleted(widget.itemId));
              ctx.go(AppConstants.routeVaultList);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _catIcon(VaultCategory cat) {
    switch (cat) {
      case VaultCategory.login: return '🔑';
      case VaultCategory.card: return '💳';
      case VaultCategory.secureNote: return '📝';
      case VaultCategory.identity: return '🪪';
      case VaultCategory.totp: return '🔐';
    }
  }

  static String _catLabel(VaultCategory cat) {
    switch (cat) {
      case VaultCategory.login: return 'حساب';
      case VaultCategory.card: return 'بطاقة';
      case VaultCategory.secureNote: return 'ملاحظة';
      case VaultCategory.identity: return 'هوية';
      case VaultCategory.totp: return 'رمز 2FA';
    }
  }

  static String _strengthLabel(int s) {
    if (s < 0) return 'غير محدد';
    const labels = ['ضعيفة جداً', 'ضعيفة', 'متوسطة', 'قوية', 'قوية جداً'];
    return labels[s.clamp(0, 4)];
  }

  static Color _strengthColor(int s) {
    if (s <= 1) return AppConstants.errorRed;
    if (s == 2) return AppConstants.warningAmber;
    return AppConstants.successGreen;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<VaultBloc, VaultState>(
      listener: (context, state) {
        if (state is VaultLoaded) {
          final updated = state.allItems.where((i) => i.id == widget.itemId).firstOrNull;
          if (updated != null && updated != _entry) {
            setState(() {
              _entry = updated;
              _passwordDecrypted = false;
              _decryptedPassword = null;
              _passwordVisible = false;
            });
          }
        }
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final entry = _entry;
    if (entry == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppConstants.backgroundDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppConstants.primaryCyan)),
      );
    }

    final fmt = DateFormat('yyyy-MM-dd');
    final hasPassword = entry.encryptedPassword != null && entry.encryptedPassword!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: Text(entry.title, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppConstants.primaryCyan),
            onPressed: () => context.go('/vault/${entry.id}/edit'),
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
          Row(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppConstants.surfaceDark, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(_catIcon(entry.category), style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              Text(_catLabel(entry.category), style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ])),
            if (entry.isFavorite)
              const Icon(Icons.star, color: AppConstants.accentGold, size: 22),
          ]),
          const SizedBox(height: 24),

          // Fields
          if (entry.username != null && entry.username!.isNotEmpty)
            _FieldCard(label: 'اسم المستخدم', value: entry.username!, copyable: true),

          if (hasPassword) _buildPasswordCard(),

          if (entry.url != null && entry.url!.isNotEmpty)
            _FieldCard(label: 'الموقع الإلكتروني', value: entry.url!, copyable: true),

          if (entry.encryptedTotpSecret != null) _buildTotpCard(),

          const SizedBox(height: 24),

          // Security info
          _buildSecurityCard(entry, fmt),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTotpCard() {
    final frac = _totpSecondsLeft / 30.0;
    final danger = _totpSecondsLeft <= 5;
    final codeColor = danger ? AppConstants.errorRed : AppConstants.primaryCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('رمز TOTP (2FA)', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          _isLoadingTotp
              ? const SizedBox(height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryCyan))
              : Text(
                  // Show formatted as "123 456"
                  _totpCode.length == 6
                      ? '${_totpCode.substring(0, 3)} ${_totpCode.substring(3)}'
                      : _totpCode,
                  style: TextStyle(
                    color: codeColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    fontFamily: 'SpaceMono',
                  ),
                ),
        ])),
        Column(children: [
          SizedBox(
            width: 36, height: 36,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: frac,
                strokeWidth: 3,
                backgroundColor: AppConstants.borderDark,
                color: codeColor,
              ),
              Text(
                '$_totpSecondsLeft',
                style: TextStyle(color: codeColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white38, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _totpCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ رمز TOTP'), duration: Duration(seconds: 2)),
              );
            },
          ),
        ]),
      ]),
    );
  }

  Widget _buildPasswordCard() {
    final displayPwd = (_passwordVisible && _passwordDecrypted)
        ? (_decryptedPassword ?? '')
        : '••••••••••••';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('كلمة المرور', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          _isDecrypting
              ? const SizedBox(height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryCyan))
              : Text(displayPwd, style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'SpaceMono')),
        ])),
        IconButton(
          icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
          onPressed: _revealPassword,
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.white38, size: 18),
          onPressed: _copyPassword,
        ),
      ]),
    );
  }

  Widget _buildSecurityCard(VaultEntry entry, DateFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('معلومات الأمان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatTile(
            label: 'قوة كلمة المرور',
            value: _strengthLabel(entry.strengthScore),
            color: _strengthColor(entry.strengthScore),
          )),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(
            label: 'آخر تحديث',
            value: fmt.format(entry.updatedAt),
            color: Colors.white60,
          )),
        ]),
        const SizedBox(height: 8),
        _StatTile(
          label: 'تاريخ الإنشاء',
          value: fmt.format(entry.createdAt),
          color: Colors.white38,
        ),
      ]),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

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
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ])),
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
      ]),
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
      decoration: BoxDecoration(color: AppConstants.surfaceDark, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    );
  }
}

