import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zxcvbn/zxcvbn.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/src/rust/frb_generated.dart/api.dart';

part 'generator_event.dart';
part 'generator_state.dart';

/// BLoC that drives the password generator tab.
///
/// Password generation is delegated to the Rust core (ChaCha20Rng) via FFI.
/// Strength scoring uses the zxcvbn algorithm.
class GeneratorBloc extends Bloc<GeneratorEvent, GeneratorState> {
  static const _ambiguousChars = 'iIlLoO01';
  final _zxcvbn = Zxcvbn();

  GeneratorBloc()
      : super(const GeneratorState(
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

    var pwd = apiGeneratePassword(
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

  int _score(String password) {
    final result = _zxcvbn.evaluate(password);
    return (result.score ?? 0).toInt().clamp(0, 4);
  }

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
