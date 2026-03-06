import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/features/travel_mode/data/repositories/travel_mode_repository.dart';

part 'travel_mode_event.dart';
part 'travel_mode_state.dart';

/// BLoC that manages Travel Mode — a privacy feature that hides sensitive
/// vault categories (e.g. cards, identities) at border crossings or while
/// travelling to high-risk regions.
class TravelModeBloc extends Bloc<TravelModeEvent, TravelModeState> {
  final TravelModeRepository _repo;

  TravelModeBloc({TravelModeRepository? repository})
      : _repo = repository ?? const TravelModeRepository(),
        super(const TravelModeInitial()) {
    on<TravelModeStarted>(_onStarted);
    on<TravelModeToggled>(_onToggled);
    on<TravelModeHiddenCategoriesUpdated>(_onHiddenCategoriesUpdated);
  }

  TravelModeLoaded? get _current =>
      state is TravelModeLoaded ? state as TravelModeLoaded : null;

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onStarted(
      TravelModeStarted event, Emitter<TravelModeState> emit) async {
    emit(const TravelModeLoading());
    try {
      final enabled = await _repo.isEnabled();
      final hidden = await _repo.getHiddenCategories();
      emit(TravelModeLoaded(isEnabled: enabled, hiddenCategories: hidden));
    } catch (e) {
      emit(TravelModeError('فشل تحميل وضع السفر: $e'));
    }
  }

  Future<void> _onToggled(
      TravelModeToggled event, Emitter<TravelModeState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(isEnabled: !s.isEnabled);
    emit(next);
    await _repo.setEnabled(next.isEnabled);
  }

  Future<void> _onHiddenCategoriesUpdated(
      TravelModeHiddenCategoriesUpdated event,
      Emitter<TravelModeState> emit) async {
    final s = _current;
    if (s == null) return;
    final next = s.copyWith(hiddenCategories: event.categories);
    emit(next);
    await _repo.setHiddenCategories(next.hiddenCategories);
  }
}
