import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Owl mascot animation states, mirroring Rive state machine inputs.
enum OwlState {
  /// Calm, idle blinking — used on splash and onboarding page 1.
  idle,

  /// Alert / scanning — used on lock screen and onboarding page 2.
  watching,

  /// Processing / thinking ring — used during auth unlock.
  verifying,

  /// Success celebration — used on onboarding page 3, auth success.
  success,

  /// Shake + red glow — used on failed auth.
  failed,

  /// High-alert pulsing red — used for security warnings.
  danger,
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Animated owl mascot widget.
///
/// Driven entirely by Flutter's animation framework as a code-first replacement
/// for a Rive asset (*.riv). The same [OwlState] enum maps to Rive state
/// machine triggers — swap the painter with [RiveAnimation.asset] once a .riv
/// file is provided without changing the public API.
class OwlMascotWidget extends StatefulWidget {
  final OwlState state;

  /// Overall diameter of the widget (glow ring included). Default 200.
  final double size;

  const OwlMascotWidget({
    super.key,
    this.state = OwlState.idle,
    this.size = 200,
  });

  @override
  State<OwlMascotWidget> createState() => _OwlMascotWidgetState();
}

class _OwlMascotWidgetState extends State<OwlMascotWidget>
    with TickerProviderStateMixin {
  // ── Breathing / idle pulse ────────────────────────────────────────────────
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  // ── Eye blink ─────────────────────────────────────────────────────────────
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  // ── Glow ring ─────────────────────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // ── State-change reaction (shake / pop) ───────────────────────────────────
  late final AnimationController _reactCtrl;


  // ── Verifying spin ────────────────────────────────────────────────────────
  late final AnimationController _spinCtrl;


  @override
  void initState() {
    super.initState();

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _blinkAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 1.0), weight: 50),
    ]).animate(_blinkCtrl);
    _scheduleBlink();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _reactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  Future<void> _scheduleBlink() async {
    while (mounted) {
      final delay = 2000 + math.Random().nextInt(3000);
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;
      if (widget.state != OwlState.watching) {
        await _blinkCtrl.forward(from: 0);
        _blinkCtrl.reset();
      }
    }
  }

  @override
  void didUpdateWidget(OwlMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _onStateChange(widget.state);
    }
  }

  void _onStateChange(OwlState state) {
    _reactCtrl.forward(from: 0);
    switch (state) {
      case OwlState.verifying:
        _spinCtrl.repeat();
      case OwlState.idle:
      case OwlState.watching:
      case OwlState.success:
      case OwlState.failed:
      case OwlState.danger:
        _spinCtrl.stop();
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _blinkCtrl.dispose();
    _glowCtrl.dispose();
    _reactCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  Color get _stateColor {
    switch (widget.state) {
      case OwlState.idle:
        return AppConstants.primaryCyan;
      case OwlState.watching:
        return AppConstants.accentGold;
      case OwlState.verifying:
        return AppConstants.primaryCyan;
      case OwlState.success:
        return AppConstants.successGreen;
      case OwlState.failed:
      case OwlState.danger:
        return AppConstants.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathAnim,
        _blinkAnim,
        _glowAnim,
        _reactCtrl,
        _spinCtrl,
      ]),
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform.scale(
            scale: _breathAnim.value *
                (widget.state == OwlState.failed
                    ? 1.0 + 0.04 * math.sin(_reactCtrl.value * math.pi * 6)
                    : 1.0),
            child: CustomPaint(
              painter: _OwlPainter(
                state: widget.state,
                stateColor: _stateColor,
                blinkProgress: _blinkAnim.value,
                glowOpacity: _glowAnim.value,
                spinAngle: _spinCtrl.value * 2 * math.pi,
                reactProgress: _reactCtrl.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _OwlPainter extends CustomPainter {
  final OwlState state;
  final Color stateColor;
  final double blinkProgress;
  final double glowOpacity;
  final double spinAngle;
  final double reactProgress;

  const _OwlPainter({
    required this.state,
    required this.stateColor,
    required this.blinkProgress,
    required this.glowOpacity,
    required this.spinAngle,
    required this.reactProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    _drawGlow(canvas, cx, cy, r);
    if (state == OwlState.verifying) _drawSpinner(canvas, cx, cy, r);
    _drawBody(canvas, cx, cy, r);
    _drawWings(canvas, cx, cy, r);
    _drawHead(canvas, cx, cy, r);
    _drawEarTufts(canvas, cx, cy, r);
    _drawFaceMask(canvas, cx, cy, r);
    _drawEyes(canvas, cx, cy, r);
    _drawBeak(canvas, cx, cy, r);
    if (state == OwlState.success) _drawSparkles(canvas, cx, cy, r);
  }

  void _drawGlow(Canvas canvas, double cx, double cy, double r) {
    final effectiveOpacity = state == OwlState.danger
        ? glowOpacity
        : glowOpacity * 0.6;
    final paint = Paint()
      ..color = stateColor.withValues(alpha: effectiveOpacity * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(Offset(cx, cy), r * 0.88, paint);
  }

  void _drawSpinner(Canvas canvas, double cx, double cy, double r) {
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.9);
    final paint = Paint()
      ..color = stateColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, spinAngle, math.pi * 1.3, false, paint);
  }

  void _drawBody(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..color = const Color(0xFF1A2035)
      ..style = PaintingStyle.fill;
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy + r * 0.18),
      width: r * 1.0,
      height: r * 1.08,
    );
    canvas.drawOval(bodyRect, paint);

    // Belly lighter patch
    final bellyPaint = Paint()
      ..color = const Color(0xFF232B40)
      ..style = PaintingStyle.fill;
    final bellyRect = Rect.fromCenter(
      center: Offset(cx, cy + r * 0.28),
      width: r * 0.62,
      height: r * 0.72,
    );
    canvas.drawOval(bellyRect, bellyPaint);

    // Belly stripe lines
    final stripePaint = Paint()
      ..color = const Color(0xFF2E3A55)
      ..strokeWidth = r * 0.025
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      final yOff = cy + r * 0.08 + i * r * 0.14;
      final xSpan = r * 0.22 * (1 - i * 0.12);
      canvas.drawLine(
          Offset(cx - xSpan, yOff), Offset(cx + xSpan, yOff), stripePaint);
    }
  }

  void _drawWings(Canvas canvas, double cx, double cy, double r) {
    double wingLift = 0.0;
    if (state == OwlState.success) wingLift = -r * 0.08 * reactProgress;
    if (state == OwlState.danger) wingLift = r * 0.04;

    final paint = Paint()
      ..color = const Color(0xFF141C2E)
      ..style = PaintingStyle.fill;

    // Left wing
    final leftPath = Path()
      ..moveTo(cx - r * 0.45, cy + wingLift)
      ..quadraticBezierTo(
          cx - r * 0.78, cy + r * 0.2 + wingLift, cx - r * 0.52, cy + r * 0.55)
      ..quadraticBezierTo(
          cx - r * 0.28, cy + r * 0.4 + wingLift, cx - r * 0.44, cy + wingLift)
      ..close();
    canvas.drawPath(leftPath, paint);

    // Right wing (mirrored)
    final rightPath = Path()
      ..moveTo(cx + r * 0.45, cy + wingLift)
      ..quadraticBezierTo(
          cx + r * 0.78, cy + r * 0.2 + wingLift, cx + r * 0.52, cy + r * 0.55)
      ..quadraticBezierTo(
          cx + r * 0.28, cy + r * 0.4 + wingLift, cx + r * 0.44, cy + wingLift)
      ..close();
    canvas.drawPath(rightPath, paint);
  }

  void _drawHead(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..color = const Color(0xFF1A2035)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - r * 0.22), r * 0.45, paint);
  }

  void _drawEarTufts(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..color = const Color(0xFF1A2035)
      ..style = PaintingStyle.fill;

    // Left tuft
    final leftTuft = Path()
      ..moveTo(cx - r * 0.22, cy - r * 0.6)
      ..lineTo(cx - r * 0.36, cy - r * 0.82)
      ..lineTo(cx - r * 0.08, cy - r * 0.64)
      ..close();
    canvas.drawPath(leftTuft, paint);

    // Right tuft
    final rightTuft = Path()
      ..moveTo(cx + r * 0.22, cy - r * 0.6)
      ..lineTo(cx + r * 0.36, cy - r * 0.82)
      ..lineTo(cx + r * 0.08, cy - r * 0.64)
      ..close();
    canvas.drawPath(rightTuft, paint);
  }

  void _drawFaceMask(Canvas canvas, double cx, double cy, double r) {
    // Lighter heart-shaped face disc
    final paint = Paint()
      ..color = const Color(0xFF232B40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - r * 0.22), r * 0.36, paint);
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double r) {
    const eyeOffsetX = 0.155;
    const eyeOffsetY = -0.24;

    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * r * eyeOffsetX;
      final ey = cy + r * eyeOffsetY;
      final eyeR = r * 0.13;

      // Eye socket
      final socketPaint = Paint()
        ..color = AppConstants.backgroundDark
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ex, ey), eyeR, socketPaint);

      // Eye glow ring
      final ringPaint = Paint()
        ..color = stateColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.018;
      canvas.drawCircle(Offset(ex, ey), eyeR, ringPaint);

      // Pupil (squished for blinking)
      final pupilH = eyeR * 0.82 * blinkProgress.clamp(0.05, 1.0);
      final pupilPaint = Paint()
        ..color = stateColor
        ..style = PaintingStyle.fill;
      final pupilRect = Rect.fromCenter(
          center: Offset(ex, ey), width: eyeR * 0.82, height: pupilH * 2);
      canvas.drawOval(pupilRect, pupilPaint);

      // Iris highlight
      if (blinkProgress > 0.3) {
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
            Offset(ex - eyeR * 0.22, ey - eyeR * 0.22), eyeR * 0.18,
            highlightPaint);
      }
    }
  }

  void _drawBeak(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..color = AppConstants.accentGold
      ..style = PaintingStyle.fill;
    final beak = Path()
      ..moveTo(cx - r * 0.07, cy - r * 0.12)
      ..lineTo(cx + r * 0.07, cy - r * 0.12)
      ..lineTo(cx, cy + r * 0.02)
      ..close();
    canvas.drawPath(beak, paint);
  }

  void _drawSparkles(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..color = AppConstants.successGreen.withValues(alpha: reactProgress * 0.9)
      ..style = PaintingStyle.fill;
    final angles = [0.3, 1.1, 1.9, 2.8, 3.6, 4.7, 5.5];
    for (final angle in angles) {
      final dist = r * 0.75 + r * 0.1 * math.sin(angle * 3);
      final sx = cx + math.cos(angle) * dist;
      final sy = cy + math.sin(angle) * dist;
      canvas.drawCircle(
          Offset(sx, sy), r * 0.035 * reactProgress, paint);
    }
  }

  @override
  bool shouldRepaint(_OwlPainter old) =>
      old.state != state ||
      old.stateColor != stateColor ||
      old.blinkProgress != blinkProgress ||
      old.glowOpacity != glowOpacity ||
      old.spinAngle != spinAngle ||
      old.reactProgress != reactProgress;
}
