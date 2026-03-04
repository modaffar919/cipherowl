import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/shared/widgets/cipherowl_logo.dart';
import '../bloc/auth_bloc.dart';

/// Splash Screen — shows animated CipherOwl logo then navigates
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────
  late final AnimationController _eyeController;
  late final AnimationController _bodyController;
  late final AnimationController _keyController;
  late final AnimationController _textController;
  late final AnimationController _particleController;

  // ── Animations ──────────────────────────────────────────
  late final Animation<double> _eyeOpacity;
  late final Animation<double> _bodyOpacity;
  late final Animation<double> _keyRotation;
  late final Animation<double> _keyOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    // Eyes glow (0.5s – 2.0s)
    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _eyeOpacity = CurvedAnimation(parent: _eyeController, curve: Curves.easeIn);

    // Body reveal (1.5s – 2.7s)
    _bodyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bodyOpacity = CurvedAnimation(parent: _bodyController, curve: Curves.easeOut);

    // Key turn (2.2s – 3.0s)
    _keyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _keyRotation = Tween<double>(begin: -1.57, end: 0.0).animate(
      CurvedAnimation(parent: _keyController, curve: Curves.elasticOut),
    );
    _keyOpacity = CurvedAnimation(parent: _keyController, curve: Curves.easeIn);

    // Text fade-in (2.8s – 3.6s)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOpacity = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Particles (loop after 2.5s)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Phase 1: Eyes appear
    _eyeController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Phase 2: Body reveals
    _bodyController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // Phase 3: Key rotates in
    _keyController.forward();
    _particleController.repeat();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Phase 4: Text appears
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Navigate to lock or onboarding
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthFirstTimeSetup) {
      context.go(AppConstants.routeOnboarding);
    } else if (authState is AuthAuthenticated) {
      context.go(AppConstants.routeDashboard);
    } else {
      // AuthLocked or still AuthChecking → go to lock screen
      context.go(AppConstants.routeLock);
    }
  }

  @override
  void dispose() {
    _eyeController.dispose();
    _bodyController.dispose();
    _keyController.dispose();
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: Stack(
        children: [
          // ── Background subtle grid ─────────────────────
          const _GridBackground(),

          // ── Center content ─────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animations
                CipherOwlLogo(
                  eyeOpacity: _eyeOpacity,
                  bodyOpacity: _bodyOpacity,
                  keyRotation: _keyRotation,
                  keyOpacity: _keyOpacity,
                  size: 220,
                ),

                const SizedBox(height: 32),

                // App name
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'CIPHER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 6,
                                ),
                              ),
                              TextSpan(
                                text: 'OWL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Cyan divider
                        Container(
                          width: 80,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppConstants.primaryCyan,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'S E C U R I T Y',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 8,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          AppConstants.appTaglineAr,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Version watermark ──────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Text(
                'v${AppConstants.appVersion}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle dot-grid background ────────────────────────────────
class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.primaryCyan.withOpacity(0.04)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner dots
    final dotPaint = Paint()
      ..color = AppConstants.primaryCyan.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

