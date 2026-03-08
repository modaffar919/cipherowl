import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../bloc/auth_bloc.dart';

/// Lock Screen — primary vault entry point after cold start
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();

  bool _obscureText = true;

  // ── Biometric indicator animation ──────────────────────
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _unlock() {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    context.read<AuthBloc>().add(AuthMasterPasswordSubmitted(password));
  }

  void _biometricUnlock() {
    context.read<AuthBloc>().add(const AuthBiometricRequested());
  }

  void _faceUnlock() {
    context.read<AuthBloc>().add(const AuthFaceUnlockRequested());
  }

  void _fido2Unlock() {
    context.read<AuthBloc>().add(const AuthFido2Requested());
  }

  void _ssoLogin() {
    // Prompt for org ID, then dispatch SSO event
    showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('SSO تسجيل دخول', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'أدخل معرّف المؤسسة',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                final orgId = controller.text.trim();
                Navigator.pop(ctx, orgId);
              },
              child: const Text('متابعة'),
            ),
          ],
        );
      },
    ).then((orgId) {
      if (!mounted) return;
      if (orgId != null && orgId.isNotEmpty) {
        context.read<AuthBloc>().add(AuthSsoLoginRequested(orgId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _passwordController.clear();
          context.go(AppConstants.routeDashboard);
          SemanticsService.sendAnnouncement(View.of(context), '\u062A\u0645 \u0641\u062A\u062D \u0627\u0644\u062E\u0632\u0646\u0629', TextDirection.rtl); // تم فتح الخزنة
        } else if (state is AuthDuressAuthenticated) {
          // Duress password — navigate to dashboard, VaultBloc will serve empty vault
          _passwordController.clear();
          context.go(AppConstants.routeDashboard);
        } else if (state is AuthFailed) {
          _shakeController.forward(from: 0);
          HapticFeedback.heavyImpact();
        } else if (state is AuthBlocked) {
          HapticFeedback.heavyImpact();
        } else if (state is AuthFirstTimeSetup) {
          context.go(AppConstants.routeSetup);
        } else if (state is AuthFido2Error) {
          HapticFeedback.mediumImpact();
        } else if (state is AuthFaceUnlockFailed) {
          HapticFeedback.mediumImpact();
        } else if (state is AuthSsoFailed) {
          HapticFeedback.mediumImpact();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthUnlocking
            || state is AuthBiometricInProgress
            || state is AuthFido2InProgress
            || state is AuthFaceUnlockInProgress
            || state is AuthSsoInProgress;
        final hasError = state is AuthFailed || state is AuthFido2Error || state is AuthFaceUnlockFailed || state is AuthSsoFailed;
        final isBlocked = state is AuthBlocked;
        final errorMessage = state is AuthFailed
            ? state.message
            : state is AuthFido2Error
                ? state.message
                : state is AuthFaceUnlockFailed
                    ? state.message
                    : state is AuthSsoFailed
                        ? state.message
                        : null;

        return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────
          const _GridBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // ── Logo ────────────────────────────────
                  _buildLogo(),

                  const Spacer(),

                  // ── Password field ───────────────────────
                  _buildPasswordSection(
                    isLoading: isLoading,
                    hasError: hasError,
                    errorMessage: errorMessage,
                    isBlocked: isBlocked,
                    blockedUntil: state is AuthBlocked ? state.unblockAt : null,
                  ),

                  const SizedBox(height: 24),

                  // ── Biometric / FIDO2 options ────────────
                  _buildAlternativeAuth(),

                  const Spacer(),

                  // ── Footer ──────────────────────────────
                  _buildFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Animated glow behind logo
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryCyan.withValues(alpha:
                      0.05 + _glowController.value * 0.1,
                    ),
                    blurRadius: 40 + _glowController.value * 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Image.asset(
            'assets/images/logo_owl.png', // drop your logo here
            errorBuilder: (_, __, ___) => const _OwlIconFallback(),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'مرحباً بعودتك',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'أدخل كلمة المرور الرئيسية لفتح الخزنة',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPasswordSection({
    required bool isLoading,
    required bool hasError,
    required bool isBlocked,
    String? errorMessage,
    DateTime? blockedUntil,
  }) {
    final blockedMsg = isBlocked && blockedUntil != null
        ? 'الخزنة مقفلة مؤقتاً. حاول بعد ${blockedUntil.difference(DateTime.now()).inMinutes + 1} دقيقة'
        : null;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final offset = hasError
            ? Offset(8 * (0.5 - (_shakeAnim.value % 1)).abs() * 4, 0)
            : Offset.zero;
        return Transform.translate(offset: offset, child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Text(
            'كلمة المرور الرئيسية',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Blocked banner
          if (isBlocked && blockedMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Text(
                blockedMsg,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          // Input
          TextFormField(
            controller: _passwordController,
            focusNode: _focusNode,
            obscureText: _obscureText,
            enabled: !isBlocked,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'SpaceMono',
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: '••••••••••••••••',
              errorText: hasError ? errorMessage : null,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
            ),
            onFieldSubmitted: (_) => _unlock(),
          ),

          const SizedBox(height: 16),

          // Unlock button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (isLoading || isBlocked) ? null : _unlock,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.backgroundDark,
                      ),
                    )
                  : const Text('فتح الخزنة 🔓'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeAuth() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'أو',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: Colors.white12)),
          ],
        ),

        const SizedBox(height: 16),

        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            // Face Unlock (MobileFaceNet embedding)
            _AuthOptionButton(
              icon: Icons.face_retouching_natural,
              labelAr: 'الوجه',
              labelEn: 'Face',
              color: AppConstants.primaryCyan,
              onTap: _faceUnlock,
            ),
            // Biometric (Fingerprint / system Face ID)
            _AuthOptionButton(
              icon: Icons.fingerprint,
              labelAr: 'البصمة',
              labelEn: 'Touch',
              color: AppConstants.successGreen,
              onTap: _biometricUnlock,
            ),
            // FIDO2 Key
            _AuthOptionButton(
              icon: Icons.key,
              labelAr: 'المفتاح',
              labelEn: 'Key',
              color: AppConstants.accentGold,
              onTap: _fido2Unlock,
            ),
            // Magic Link
            _AuthOptionButton(
              icon: Icons.mail_outline_rounded,
              labelAr: 'رابط سحري',
              labelEn: 'Link',
              color: AppConstants.accentPurple,
              onTap: () => context.push(AppConstants.routeMagicLink),
            ),
            // Enterprise SSO (OIDC)
            _AuthOptionButton(
              icon: Icons.business,
              labelAr: 'SSO',
              labelEn: 'SSO',
              color: Colors.blueAccent,
              onTap: _ssoLogin,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return TextButton(
      onPressed: () {
        context.push(AppConstants.routeRecoveryRestore);
      },
      child: const Text(
        'نسيت كلمة المرور؟',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _AuthOptionButton extends StatelessWidget {
  final IconData icon;
  final String labelAr;
  final String labelEn;
  final Color color;
  final VoidCallback onTap;

  const _AuthOptionButton({
    required this.icon,
    required this.labelAr,
    required this.labelEn,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$labelAr - $labelEn',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 70,
        decoration: BoxDecoration(
          color: AppConstants.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26, semanticLabel: labelAr),
            const SizedBox(height: 4),
            Text(
              labelAr,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _OwlIconFallback extends StatelessWidget {
  const _OwlIconFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppConstants.primaryCyan.withValues(alpha: 0.3), width: 1),
      ),
      child: const Center(
        child: Text('🦉', style: TextStyle(fontSize: 48)),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: MediaQuery.of(context).size,
    painter: _GridPainter(),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.primaryCyan.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


