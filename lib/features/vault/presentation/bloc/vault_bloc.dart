import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/features/vault/data/repositories/vault_repository.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';

part 'vault_event.dart';
part 'vault_state.dart';

/// BLoC responsible for all vault CRUD and filtering logic.
///
/// Uses [VaultRepository] for persistence and lives in [MultiBlocProvider]
/// inside [app.dart] after the user authenticates.
class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final VaultRepository _repo;
  StreamSubscription<List<VaultEntry>>? _itemsSub;

  VaultBloc({required VaultRepository repository})
      : _repo = repository,
        super(const VaultInitial()) {
    on<VaultStarted>(_onStarted);
    on<_VaultItemsReceived>(_onItemsReceived);
    on<VaultSearchChanged>(_onSearchChanged);
    on<VaultCategoryChanged>(_onCategoryChanged);
    on<VaultItemAdded>(_onItemAdded);
    on<VaultItemUpdated>(_onItemUpdated);
    on<VaultItemDeleted>(_onItemDeleted);
    on<VaultFavoriteToggled>(_onFavoriteToggled);
    on<VaultRefreshRequested>(_onRefreshRequested);
    on<VaultMessageDismissed>(_onMessageDismissed);
    on<VaultItemsImported>(_onItemsImported);
  }

  // ── Event handlers ───────────────────────────────────────────────────────

  Future<void> _onStarted(
      VaultStarted event, Emitter<VaultState> emit) async {
    emit(const VaultLoading());
    await _itemsSub?.cancel();
    _itemsSub = _repo.watchItems(event.userId).listen(
          (items) => add(_VaultItemsReceived(items)),
          onError: (Object e) =>
              add(_VaultItemsReceived(const [])), // fallback
        );
  }

  void _onItemsReceived(
      _VaultItemsReceived event, Emitter<VaultState> emit) {
    final current = state is VaultLoaded ? state as VaultLoaded : null;
    emit(VaultLoaded(
      allItems: event.items,
      searchQuery: current?.searchQuery ?? '',
      categoryFilter: current?.categoryFilter,
    ));
  }

  void _onSearchChanged(
      VaultSearchChanged event, Emitter<VaultState> emit) {
    if (state is! VaultLoaded) return;
    emit((state as VaultLoaded).copyWith(searchQuery: event.query));
  }

  void _onCategoryChanged(
      VaultCategoryChanged event, Emitter<VaultState> emit) {
    if (state is! VaultLoaded) return;
    final current = state as VaultLoaded;
    // Toggle off if same category is tapped again
    if (current.categoryFilter == event.category) {
      emit(current.copyWith(clearCategory: true));
    } else {
      emit(current.copyWith(categoryFilter: event.category));
    }
  }

  Future<void> _onItemAdded(
      VaultItemAdded event, Emitter<VaultState> emit) async {
    if (state is! VaultLoaded) return;
    emit((state as VaultLoaded).copyWith(isOperating: true));
    try {
      await _repo.addItem(event.entry);
      // Stream will auto-update allItems — just clear operating flag + message
      if (state is VaultLoaded) {
        emit((state as VaultLoaded).copyWith(
          isOperating: false,
          message: 'تم الحفظ بنجاح ✓',
        ));
      }
    } catch (e) {
      if (state is VaultLoaded) {
        emit((state as VaultLoaded).copyWith(
          isOperating: false,
          message: 'خطأ في الحفظ: $e',
          isError: true,
        ));
      }
    }
  }

  Future<void> _onItemUpdated(
      VaultItemUpdated event, Emitter<VaultState> emit) async {
    if (state is! VaultLoaded) return;
    emit((state as VaultLoaded).copyWith(isOperating: true));
    try {
      await _repo.updateItem(event.entry);
      if (state is VaultLoaded) {
        emit((state as VaultLoaded).copyWith(
          isOperating: false,
          message: 'تم التحديث بنجاح ✓',
        ));
      }
    } catch (e) {
      if (state is VaultLoaded) {
        emit((state as VaultLoaded).copyWith(
          isOperating: false,
          message: 'خطأ في التحديث: $e',
          isError: true,
        ));
      }
    }
  }

  Future<void> _onItemDeleted(
      VaultItemDeleted event, Emitter<VaultState> emit) async {
    if (state is! VaultLoaded) return;
    emit((state as VaultLoaded).copyWith(isOperating: true));
    try {
      await _repo.deleteItem(event.itemId);
      if (state is VaultLoaded) {
        emit((state as VaultLoaded).copyWith(
          isOperating: false,
          message: 'تم الحذف',
        ));
      }
    } catch (e) {
      if (state is VaultLoaded) {
        emit((state as VaultLoaded).copyWith(
          isOperating: false,
          message: 'فشل الحذف: $e',
          isError: true,
        ));
      }
    }
  }

  Future<void> _onFavoriteToggled(
      VaultFavoriteToggled event, Emitter<VaultState> emit) async {
    try {
      await _repo.toggleFavorite(event.itemId, value: event.isFavorite);
    } catch (_) {
      // Silent fail — non-critical
    }
  }

  Future<void> _onRefreshRequested(
      VaultRefreshRequested event, Emitter<VaultState> emit) async {
    // The DB stream already live-updates — re-emit current state as reload
    if (state is VaultLoaded) {
      final loaded = state as VaultLoaded;
      emit(const VaultLoading());
      emit(loaded);
    }
  }

  void _onMessageDismissed(
      VaultMessageDismissed event, Emitter<VaultState> emit) {
    if (state is VaultLoaded) {
      emit((state as VaultLoaded).copyWith(clearMessage: true));
    }
  }

  Future<void> _onItemsImported(
      VaultItemsImported event, Emitter<VaultState> emit) async {
    if (state is! VaultLoaded) return;
    final current = state as VaultLoaded;
    emit(current.copyWith(isOperating: true));
    int imported = 0;
    int skipped = 0;
    for (final entry in event.entries) {
      try {
        await _repo.addItem(entry);
        imported++;
      } catch (_) {
        skipped++;
      }
    }
    final msg = skipped == 0
        ? 'تم استيراد $imported حساب بنجاح ✓'
        : 'تم $imported حساب | تخطّي $skipped';
    emit(current.copyWith(isOperating: false, message: msg));
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _itemsSub?.cancel();
    return super.close();
  }
}
