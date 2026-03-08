import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable Lottie animation widgets for CipherOwl transitions.
///
/// These complement the CustomPaint widgets in [animated_widgets.dart]
/// by providing asset-based Lottie animations for specific use cases.

/// Animated success checkmark using Lottie.
class LottieSuccessCheck extends StatelessWidget {
  final double size;
  final bool repeat;

  const LottieSuccessCheck({
    super.key,
    this.size = 80,
    this.repeat = false,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/success_check.json',
      width: size,
      height: size,
      repeat: repeat,
    );
  }
}

/// Animated loading spinner using Lottie.
class LottieLoadingSpinner extends StatelessWidget {
  final double size;

  const LottieLoadingSpinner({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/loading_spinner.json',
      width: size,
      height: size,
      repeat: true,
    );
  }
}

/// Animated shield lock icon using Lottie — used for security screens.
class LottieShieldLock extends StatelessWidget {
  final double size;
  final bool repeat;

  const LottieShieldLock({
    super.key,
    this.size = 100,
    this.repeat = false,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/shield_lock.json',
      width: size,
      height: size,
      repeat: repeat,
    );
  }
}
