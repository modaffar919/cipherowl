import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/src/rust/api.dart';

part 'generator_event.dart';
part 'generator_state.dart';

/// Signature for the password-generation function so it can be overridden in
/// tests without loading the native Rust library.
typedef PasswordGeneratorFn = String Function({
  required ApiGeneratorConfig config,
});

/// Signature for the strength-scoring function (returns 0-4).
typedef StrengthScorerFn = int Function(String password);

/// BLoC that drives the password generator tab.
///
/// Password generation is delegated to the Rust core (ChaCha20Rng) via FFI.
/// Strength scoring uses the zxcvbn algorithm.
class GeneratorBloc extends Bloc<GeneratorEvent, GeneratorState> {
  static const _ambiguousChars = 'iIlLoO01';
  final PasswordGeneratorFn _generatePassword;
  final StrengthScorerFn _strengthScorer;

  GeneratorBloc({
    @visibleForTesting PasswordGeneratorFn? passwordGenerator,
    @visibleForTesting StrengthScorerFn? strengthScorer,
  })  : _generatePassword = passwordGenerator ?? apiGeneratePassword,
        _strengthScorer = strengthScorer ??
            ((p) => p.isEmpty ? 0 : apiEstimateStrength(password: p).score.clamp(0, 4)),
        super(const GeneratorState(
          password: '',
          strengthScore: 0,
          strengthLabel: 'ضعيفة',
          strengthColor: AppConstants.errorRed,
        )) {
    on<GeneratorRefreshRequested>(_onRefresh);
    on<GeneratorConfigUpdated>(_onConfigUpdated);
    // Generate an initial password immediately.
    add(const GeneratorRefreshRequested());
  }

  // ── Handlers ─────────────────────────────────────────────────────────────

  void _onRefresh(
      GeneratorRefreshRequested event, Emitter<GeneratorState> emit) {
    emit(_generate(state));
  }

  void _onConfigUpdated(
      GeneratorConfigUpdated event, Emitter<GeneratorState> emit) {
    final updated = state.copyWith(
      length: event.length,
      useUppercase: event.useUppercase,
      useLowercase: event.useLowercase,
      useDigits: event.useDigits,
      useSymbols: event.useSymbols,
      excludeAmbiguous: event.excludeAmbiguous,
    );
    emit(_generate(updated));
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  GeneratorState _generate(GeneratorState cfg) {
    // Ensure at least one charset is active.
    final useLower =
        cfg.useLowercase || (!cfg.useUppercase && !cfg.useDigits && !cfg.useSymbols);

    var pwd = _generatePassword(
      config: ApiGeneratorConfig(
        length: BigInt.from(cfg.length.toInt()),
        useLowercase: useLower,
        useUppercase: cfg.useUppercase,
        useDigits: cfg.useDigits,
        useSymbols: cfg.useSymbols,
      ),
    );

    if (cfg.excludeAmbiguous) {
      pwd = pwd.split('').where((c) => !_ambiguousChars.contains(c)).join();
    }

    final score = _score(pwd);
    return cfg.copyWith(
      password: pwd,
      strengthScore: score,
      strengthLabel: _label(score),
      strengthColor: _color(score),
      useLowercase: useLower,
    );
  }

  int _score(String password) => _strengthScorer(password);

  static String _label(int score) => switch (score) {
        0 || 1 => 'ضعيفة',
        2 => 'متوسطة',
        3 => 'جيدة',
        _ => 'قوية جداً',
      };

  static Color _color(int score) => switch (score) {
        0 || 1 => AppConstants.errorRed,
        2 => AppConstants.warningAmber,
        3 => Colors.lightGreenAccent,
        _ => AppConstants.successGreen,
      };
}
