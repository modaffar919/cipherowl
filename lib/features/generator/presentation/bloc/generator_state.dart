part of 'generator_bloc.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class GeneratorState {
  final String password;

  /// zxcvbn score 0–4.
  final int strengthScore;

  /// Human-readable Arabic strength label.
  final String strengthLabel;

  /// Hex colour for the strength indicator.
  final Color strengthColor;

  // ── Config ───────────────────────────────────────────────────────────────
  final double length;
  final bool useUppercase;
  final bool useLowercase;
  final bool useDigits;
  final bool useSymbols;
  final bool excludeAmbiguous;

  const GeneratorState({
    required this.password,
    required this.strengthScore,
    required this.strengthLabel,
    required this.strengthColor,
    this.length = 20,
    this.useUppercase = true,
    this.useLowercase = true,
    this.useDigits = true,
    this.useSymbols = true,
    this.excludeAmbiguous = false,
  });

  GeneratorState copyWith({
    String? password,
    int? strengthScore,
    String? strengthLabel,
    Color? strengthColor,
    double? length,
    bool? useUppercase,
    bool? useLowercase,
    bool? useDigits,
    bool? useSymbols,
    bool? excludeAmbiguous,
  }) =>
      GeneratorState(
        password: password ?? this.password,
        strengthScore: strengthScore ?? this.strengthScore,
        strengthLabel: strengthLabel ?? this.strengthLabel,
        strengthColor: strengthColor ?? this.strengthColor,
        length: length ?? this.length,
        useUppercase: useUppercase ?? this.useUppercase,
        useLowercase: useLowercase ?? this.useLowercase,
        useDigits: useDigits ?? this.useDigits,
        useSymbols: useSymbols ?? this.useSymbols,
        excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
      );
}
