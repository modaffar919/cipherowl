part of 'travel_mode_bloc.dart';

abstract class TravelModeEvent {
  const TravelModeEvent();
}

/// Load persisted Travel Mode state on app start.
class TravelModeStarted extends TravelModeEvent {
  const TravelModeStarted();
}

/// Enable or disable Travel Mode.
class TravelModeToggled extends TravelModeEvent {
  const TravelModeToggled();
}

/// Update which vault categories are hidden during Travel Mode.
class TravelModeHiddenCategoriesUpdated extends TravelModeEvent {
  final Set<String> categories;
  const TravelModeHiddenCategoriesUpdated(this.categories);
}
