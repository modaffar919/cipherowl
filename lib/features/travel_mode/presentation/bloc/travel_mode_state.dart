part of 'travel_mode_bloc.dart';

abstract class TravelModeState {
  const TravelModeState();
}

class TravelModeInitial extends TravelModeState {
  const TravelModeInitial();
}

class TravelModeLoading extends TravelModeState {
  const TravelModeLoading();
}

class TravelModeLoaded extends TravelModeState {
  final bool isEnabled;

  /// Set of [VaultCategory.name] strings that are hidden from the vault list.
  final Set<String> hiddenCategories;

  const TravelModeLoaded({
    required this.isEnabled,
    required this.hiddenCategories,
  });

  TravelModeLoaded copyWith({
    bool? isEnabled,
    Set<String>? hiddenCategories,
  }) =>
      TravelModeLoaded(
        isEnabled: isEnabled ?? this.isEnabled,
        hiddenCategories: hiddenCategories ?? this.hiddenCategories,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelModeLoaded &&
          isEnabled == other.isEnabled &&
          _setsEqual(hiddenCategories, other.hiddenCategories);

  @override
  int get hashCode =>
      isEnabled.hashCode ^ Object.hashAll(hiddenCategories.toList()..sort());

  static bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.every(b.contains);
  }
}

class TravelModeError extends TravelModeState {
  final String message;
  const TravelModeError(this.message);
}
