import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

// ── Loading Animation ─────────────────────────────────────────────────────────

/// Pulsing arc spinner — replaces a Lottie loading JSON.
///
/// Used on the splash screen, data-fetch states, and anywhere a
/// non-blocking progress indicator is needed.
class CipherLoadingWidget extends StatefulWidget {
  final double size;
  final Color? color;

  const CipherLoadingWidget({
    super.key,
    this.size = 72,
    this.color,
  });

  @override
  State<CipherLoadingWidget> createState() => _CipherLoadingWidgetState();
}

class _CipherLoadingWidgetState extends State<CipherLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _spin;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _spin = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppConstants.primaryCyan;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _LoadingPainter(
              angle: _spin.value,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final double angle;
  final Color color;

  const _LoadingPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;

    // Track ring
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12;
    canvas.drawCircle(Offset(cx, cy), r * 0.8, trackPaint);

    // Spinning arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.8);
    canvas.drawArc(rect, angle - math.pi / 2, math.pi * 1.4, false, arcPaint);

    // Glow dot at arc start
    final dotPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final dotX = cx + math.cos(angle - math.pi / 2) * r * 0.8;
    final dotY = cy + math.sin(angle - math.pi / 2) * r * 0.8;
    canvas.drawCircle(Offset(dotX, dotY), r * 0.09, dotPaint);
  }

  @override
  bool shouldRepaint(_LoadingPainter old) =>
      old.angle != angle || old.color != color;
}

// ── Success Animation ─────────────────────────────────────────────────────────

/// Self-drawing checkmark in a circle — replaces a Lottie success JSON.
///
/// Plays once when [key] changes or [play] is called. Loops once from
/// the beginning if you call `GlobalKey<CipherSuccessWidgetState>.currentState?.play()`.
class CipherSuccessWidget extends StatefulWidget {
  final double size;
  final Color? color;

  const CipherSuccessWidget({
    super.key,
    this.size = 72,
    this.color,
  });

  @override
  State<CipherSuccessWidget> createState() => CipherSuccessWidgetState();
}

class CipherSuccessWidgetState extends State<CipherSuccessWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _circleAnim;
  late final Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _circleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _checkAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  /// Re-trigger the animation.
  void play() => _ctrl.forward(from: 0);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppConstants.successGreen;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _SuccessPainter(
            circleProgress: _circleAnim.value,
            checkProgress: _checkAnim.value,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  const _SuccessPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;

    // Background fill
    if (circleProgress > 0) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: circleProgress * 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r * 0.9 * circleProgress, fillPaint);
    }

    // Stroke circle
    final circlePaint = Paint()
      ..color = color.withValues(alpha: circleProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1
      ..strokeCap = StrokeCap.round;
    final cRect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.8);
    canvas.drawArc(
        cRect, -math.pi / 2, 2 * math.pi * circleProgress, false, circlePaint);

    // Checkmark path (draws progressively)
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Two segments: P0→P1 (the short downstroke), P1→P2 (the long stroke)
      final p0 = Offset(cx - r * 0.34, cy + r * 0.02);
      final p1 = Offset(cx - r * 0.06, cy + r * 0.3);
      final p2 = Offset(cx + r * 0.38, cy - r * 0.24);

      const seg1Frac = 0.35;
      final path = Path();

      if (checkProgress <= seg1Frac) {
        final t = checkProgress / seg1Frac;
        path.moveTo(p0.dx, p0.dy);
        path.lineTo(
            p0.dx + (p1.dx - p0.dx) * t, p0.dy + (p1.dy - p0.dy) * t);
      } else {
        final t = (checkProgress - seg1Frac) / (1 - seg1Frac);
        path.moveTo(p0.dx, p0.dy);
        path.lineTo(p1.dx, p1.dy);
        path.lineTo(
            p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
      }
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter old) =>
      old.circleProgress != circleProgress ||
      old.checkProgress != checkProgress ||
      old.color != color;
}

// ── Data Loading (3 dots) ─────────────────────────────────────────────────────

/// Three staggered bouncing dots — replaces a Lottie data-loading JSON.
///
/// Used inside list skeletons, async data fetch overlays, etc.
class CipherDotsWidget extends StatefulWidget {
  final double dotSize;
  final Color? color;

  const CipherDotsWidget({
    super.key,
    this.dotSize = 10,
    this.color,
  });

  @override
  State<CipherDotsWidget> createState() => _CipherDotsWidgetState();
}

class _CipherDotsWidgetState extends State<CipherDotsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppConstants.primaryCyan;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.22s
            final phase = (_ctrl.value - i * 0.3).clamp(0.0, 1.0);
            final bounce =
                math.sin(phase * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: widget.dotSize * 0.3),
              child: Transform.translate(
                offset: Offset(0, -widget.dotSize * 0.9 * bounce),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.4 + 0.6 * bounce),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
