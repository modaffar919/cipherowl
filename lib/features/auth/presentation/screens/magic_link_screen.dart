import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/auth/data/services/supabase_auth_service.dart';

/// Magic Link (passwordless) sign-in screen.
///
/// Sends a one-time link to the user's email. Clicking the link in the
/// email opens the app via deep-link and creates a cloud session.
///
/// This does NOT bypass the master password — the user still needs to
/// unlock their local vault after the cloud session is established.
class MagicLinkScreen extends StatefulWidget {
  const MagicLinkScreen({super.key});

  @override
  State<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends State<MagicLinkScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _sending = false;
  bool _sent = false;
  String? _error;

  late final SupabaseAuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = SupabaseAuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await _authService.sendMagicLink(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '\u062D\u062F\u062B \u062E\u0637\u0623 \u063A\u064A\u0631 \u0645\u062A\u0648\u0642\u0639'); // حدث خطأ غير متوقع
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '\u062A\u0633\u062C\u064A\u0644 \u062F\u062E\u0648\u0644 \u0628\u062F\u0648\u0646 \u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631', // تسجيل دخول بدون كلمة مرور
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _sent ? _buildSentState() : _buildFormState(),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // ── Icon ──────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.primaryCyan.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: AppConstants.primaryCyan,
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            '\u0631\u0627\u0628\u0637 \u0633\u062D\u0631\u064A', // رابط سحري
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          const Text(
            '\u0633\u0646\u0631\u0633\u0644 \u0631\u0627\u0628\u0637\u0627\u064B \u0622\u0645\u0646\u0627\u064B \u0625\u0644\u0649 \u0628\u0631\u064A\u062F\u0643 \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A \u0644\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644 \u0625\u0644\u0649 \u0627\u0644\u0633\u062D\u0627\u0628\u0629', // سنرسل رابطاً آمناً إلى بريدك الإلكتروني لتسجيل الدخول إلى السحابة
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // ── Email Field ───────────────────
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'example@email.com',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white38),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return '\u0627\u0644\u0631\u062C\u0627\u0621 \u0625\u062F\u062E\u0627\u0644 \u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A'; // الرجاء إدخال البريد الإلكتروني
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return '\u0628\u0631\u064A\u062F \u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A \u063A\u064A\u0631 \u0635\u0627\u0644\u062D'; // بريد إلكتروني غير صالح
              }
              return null;
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppConstants.errorRed, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // ── Send Button ───────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendLink,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _sending
                    ? '\u062C\u0627\u0631\u064D \u0627\u0644\u0625\u0631\u0633\u0627\u0644...' // جارٍ الإرسال...
                    : '\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0627\u0628\u0637', // إرسال الرابط
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Info ──────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderDark),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppConstants.primaryCyan, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '\u0647\u0630\u0627 \u064A\u0633\u062C\u0644 \u062F\u062E\u0648\u0644\u0643 \u0625\u0644\u0649 \u0627\u0644\u0633\u062D\u0627\u0628\u0629 \u0641\u0642\u0637. \u0633\u062A\u062D\u062A\u0627\u062C \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629 \u0644\u0641\u062A\u062D \u0627\u0644\u062E\u0632\u0646\u0629.', // هذا يسجل دخولك إلى السحابة فقط. ستحتاج كلمة المرور الرئيسية لفتح الخزنة.
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Success Icon ────────────────
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppConstants.accentGreen.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppConstants.accentGreen,
            size: 48,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          '\u062A\u0645 \u0627\u0644\u0625\u0631\u0633\u0627\u0644!', // تم الإرسال!
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          '\u062A\u0641\u0642\u062F \u0628\u0631\u064A\u062F\u0643 \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A\n${_emailController.text.trim()}', // تفقد بريدك الإلكتروني
          style: const TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // ── Resend button ───────────────
        TextButton.icon(
          onPressed: () {
            setState(() {
              _sent = false;
              _error = null;
            });
          },
          icon: const Icon(Icons.refresh, color: AppConstants.primaryCyan, size: 18),
          label: const Text(
            '\u0625\u0639\u0627\u062F\u0629 \u0627\u0644\u0625\u0631\u0633\u0627\u0644', // إعادة الإرسال
            style: TextStyle(color: AppConstants.primaryCyan),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '\u0627\u0644\u0639\u0648\u062F\u0629', // العودة
            style: TextStyle(color: Colors.white38),
          ),
        ),
      ],
    );
  }
}
