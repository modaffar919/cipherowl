import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// CipherOwl animated logo widget
/// Used in SplashScreen with individual animation controllers.
/// Falls back to emoji version if Rive file isn't loaded yet.
class CipherOwlLogo extends StatelessWidget {
  final Animation<double> eyeOpacity;
  final Animation<double> bodyOpacity;
  final Animation<double> keyRotation;
  final Animation<double> keyOpacity;
  final double size;

  const CipherOwlLogo({
    super.key,
    required this.eyeOpacity,
    required this.bodyOpacity,
    required this.keyRotation,
    required this.keyOpacity,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // â”€â”€ Outer ring (subtle) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.primaryCyan.withValues(alpha: 0.1), width: 1),
            ),
          ),

          // â”€â”€ Owl body + wings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          FadeTransition(
            opacity: bodyOpacity,
            child: _OwlBodyPainter(size: size),
          ),

          // â”€â”€ Glowing eyes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          FadeTransition(
            opacity: eyeOpacity,
            child: _OwlEyesPainter(size: size),
          ),

          // â”€â”€ Key (rotates in) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          FadeTransition(
            opacity: keyOpacity,
            child: AnimatedBuilder(
              animation: keyRotation,
              builder: (_, child) => Transform.rotate(
                angle: keyRotation.value,
                child: child,
              ),
              child: _KeyPainter(size: size * 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the owl outline as a CustomPainter
class _OwlBodyPainter extends StatelessWidget {
  final double size;
  const _OwlBodyPainter({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OwlOutlinePainter(),
    );
  }
}

class _OwlOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Body â€” oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.1), width: r * 1.2, height: r * 1.6),
      paint,
    );

    // Head â€” circle
    canvas.drawCircle(Offset(cx, cy - r * 0.35), r * 0.52, paint);

    // Left ear tuft
    final path = Path()
      ..moveTo(cx - r * 0.3, cy - r * 0.75)
      ..lineTo(cx - r * 0.42, cy - r * 1.0)
      ..lineTo(cx - r * 0.15, cy - r * 0.82);
    canvas.drawPath(path, paint);

    // Right ear tuft
    final path2 = Path()
      ..moveTo(cx + r * 0.3, cy - r * 0.75)
      ..lineTo(cx + r * 0.42, cy - r * 1.0)
      ..lineTo(cx + r * 0.15, cy - r * 0.82);
    canvas.drawPath(path2, paint);

    // Wings (simplified lines)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - r * 0.8, cy + r * 0.2), width: r, height: r * 0.6),
      -0.5, 1.5, false, paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + r * 0.8, cy + r * 0.2), width: r, height: r * 0.6),
      -2.6, 1.5, false, paint,
    );

    // Beak
    final beakPath = Path()
      ..moveTo(cx - r * 0.1, cy - r * 0.25)
      ..lineTo(cx, cy - r * 0.08)
      ..lineTo(cx + r * 0.1, cy - r * 0.25);
    canvas.drawPath(beakPath, paint..color = AppConstants.accentGold.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _OwlEyesPainter extends StatelessWidget {
  final double size;
  const _OwlEyesPainter({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EyesPainter(),
    );
  }
}

class _EyesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;
    final eyeR = r * 0.17;
    final eyeY = cy - r * 0.38;

    // Glow halo
    final glowPaint = Paint()
      ..color = AppConstants.primaryCyan.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(cx - r * 0.22, eyeY), eyeR + 4, glowPaint);
    canvas.drawCircle(Offset(cx + r * 0.22, eyeY), eyeR + 4, glowPaint);

    // Eye ring
    final ringPaint = Paint()
      ..color = AppConstants.primaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(cx - r * 0.22, eyeY), eyeR, ringPaint);
    canvas.drawCircle(Offset(cx + r * 0.22, eyeY), eyeR, ringPaint);

    // Pupil
    final pupilPaint = Paint()..color = AppConstants.primaryCyan;
    canvas.drawCircle(Offset(cx - r * 0.22, eyeY), eyeR * 0.5, pupilPaint);
    canvas.drawCircle(Offset(cx + r * 0.22, eyeY), eyeR * 0.5, pupilPaint);

    // Highlight dot
    final hlPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx - r * 0.22 + eyeR * 0.2, eyeY - eyeR * 0.2), eyeR * 0.18, hlPaint);
    canvas.drawCircle(Offset(cx + r * 0.22 + eyeR * 0.2, eyeY - eyeR * 0.2), eyeR * 0.18, hlPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _KeyPainter extends StatelessWidget {
  final double size;
  const _KeyPainter({required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: size * 0.8),
      child: CustomPaint(
        size: Size(size, size * 0.5),
        painter: _KeyOutlinePainter(),
      ),
    );
  }
}

class _KeyOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Key head (ring)
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.5), size.height * 0.4, paint);

    // Key shaft
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.5),
      Offset(size.width * 0.95, size.height * 0.5),
      paint,
    );

    // Key teeth
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.5),
      Offset(size.width * 0.65, size.height * 0.75),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.80, size.height * 0.5),
      Offset(size.width * 0.80, size.height * 0.65),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
