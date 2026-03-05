import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repo;
  static const _uuid = Uuid();

  NotificationBloc(this._repo) : super(const NotificationState()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationReceived>(_onReceived);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationMarkAllRead>(_onMarkAllRead);
    on<NotificationDeleted>(_onDeleted);
    on<NotificationsClearAll>(_onClearAll);
    on<SecurityAlertPosted>(_onSecurityAlert);
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final notifications = await _repo.getAll();
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.add(event.notification);
    final updated = await _repo.getAll();
    emit(state.copyWith(
      status: NotificationStatus.loaded,
      notifications: updated,
    ));
  }

  Future<void> _onMarkRead(
    NotificationMarkRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.markRead(event.id);
    final updated = await _repo.getAll();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.markAllRead();
    final updated = await _repo.getAll();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onDeleted(
    NotificationDeleted event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.remove(event.id);
    final updated = await _repo.getAll();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onClearAll(
    NotificationsClearAll event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.clearAll();
    emit(state.copyWith(
      status: NotificationStatus.loaded,
      notifications: const [],
    ));
  }

  Future<void> _onSecurityAlert(
    SecurityAlertPosted event,
    Emitter<NotificationState> emit,
  ) async {
    final notification = AppNotification(
      id:        _uuid.v4(),
      type:      event.type,
      titleAr:   event.titleAr,
      bodyAr:    event.bodyAr,
      createdAt: DateTime.now(),
      route:     event.route,
    );
    await _repo.add(notification);
    final updated = await _repo.getAll();
    emit(state.copyWith(
      status: NotificationStatus.loaded,
      notifications: updated,
    ));
  }
}
