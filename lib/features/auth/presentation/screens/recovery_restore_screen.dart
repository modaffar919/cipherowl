import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/auth/data/services/recovery_key_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';

/// Screen that allows the user to restore access using their 12-word
/// BIP39 recovery mnemonic when they have forgotten their master password.
///
/// Flow:
///   1. User enters 12 words (one per field).
///   2. Words are validated against BIP39 wordlist.
///   3. Derived key is compared to the stored verifier.
///   4. On success, user sets a new master password → vault unlocked.
class RecoveryRestoreScreen extends StatefulWidget {
  const RecoveryRestoreScreen({super.key});

  @override
  State<RecoveryRestoreScreen> createState() => _RecoveryRestoreScreenState();
}

class _RecoveryRestoreScreenState extends State<RecoveryRestoreScreen> {
  final _service = RecoveryKeyService();
  final _controllers = List.generate(12, (_) => TextEditingController());
  final _focusNodes = List.generate(12, (_) => FocusNode());

  bool _verifying = false;
  String? _error;
  bool _verified = false;

  // New password step
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String _buildMnemonic() {
    return _controllers
        .map((c) => c.text.trim().toLowerCase())
        .join(' ');
  }

  Future<void> _verifyRecovery() async {
    final mnemonic = _buildMnemonic();
    final words = mnemonic.split(' ');

    // Basic validation
    if (words.any((w) => w.isEmpty)) {
      setState(() => _error = 'أدخل جميع الكلمات الـ 12');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final valid = await _service.verifyMnemonic(mnemonic);
      if (!mounted) return;

      if (valid) {
        setState(() {
          _verified = true;
          _verifying = false;
        });
      } else {
        setState(() {
          _error = 'عبارة الاسترداد غير صحيحة — تأكد من الكلمات وترتيبها';
          _verifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'خطأ: ${e.toString()}';
          _verifying = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (newPass.length < 12) {
      setState(() => _error = 'كلمة المرور يجب أن تكون 12 حرفاً على الأقل');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = AuthRepository();
      await repo.saveMasterPassword(newPass);
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthSetupCompleted(''));
      context.go(AppConstants.routeDashboard);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'خطأ في حفظ كلمة المرور: ${e.toString()}';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: Text(
          _verified ? 'إعادة تعيين كلمة المرور' : 'استرداد الحساب',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go(AppConstants.routeLock),
        ),
      ),
      body: SafeArea(
        child: _verified ? _buildNewPasswordStep() : _buildWordEntryStep(),
      ),
    );
  }

  // ── Step 1: Enter 12 words ─────────────────────────────────────────────────

  Widget _buildWordEntryStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '🔑',
          style: TextStyle(fontSize: 40),
        ),
        const SizedBox(height: 12),
        const Text(
          'أدخل كلمات الاسترداد الـ 12',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'أدخل الكلمات الـ 12 التي حفظتها عند إعداد حسابك بالترتيب الصحيح.',
          style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Word input grid (2 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2,
          ),
          itemCount: 12,
          itemBuilder: (_, i) => _WordInput(
            index: i + 1,
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            onSubmitted: () {
              if (i < 11) {
                _focusNodes[i + 1].requestFocus();
              }
            },
          ),
        ),

        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: AppConstants.errorRed, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        ElevatedButton(
          onPressed: _verifying ? null : _verifyRecovery,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _verifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('التحقق من عبارة الاسترداد'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Step 2: Set new master password ────────────────────────────────────────

  Widget _buildNewPasswordStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text(
            'تم التحقق بنجاح!',
            style: TextStyle(
              color: AppConstants.successGreen,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أنشئ كلمة مرور رئيسية جديدة لخزنتك.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontFamily: 'SpaceMono'),
            decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPassCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontFamily: 'SpaceMono'),
            decoration:
                const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة'),
          ),
          const SizedBox(height: 16),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style:
                    const TextStyle(color: AppConstants.errorRed, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('حفظ وفتح الخزنة'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Sub-widget ──────────────────────────────────────────────────────────────

class _WordInput extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  const _WordInput({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.borderDark),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index.',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: index < 12
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: (_) => onSubmitted(),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceMono',
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
