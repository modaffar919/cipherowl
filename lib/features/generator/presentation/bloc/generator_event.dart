part of 'generator_bloc.dart';

// ─── Events ────────────────────────────────────────────────────────────────

abstract class GeneratorEvent {
  const GeneratorEvent();
}

/// User pressed the refresh / generate button.
class GeneratorRefreshRequested extends GeneratorEvent {
  const GeneratorRefreshRequested();
}

/// User changed any configuration option.
class GeneratorConfigUpdated extends GeneratorEvent {
  final double? length;
  final bool? useUppercase;
  final bool? useLowercase;
  final bool? useDigits;
  final bool? useSymbols;
  final bool? excludeAmbiguous;

  const GeneratorConfigUpdated({
    this.length,
    this.useUppercase,
    this.useLowercase,
    this.useDigits,
    this.useSymbols,
    this.excludeAmbiguous,
  });
}
