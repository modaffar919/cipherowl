import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

/// Load all persisted notifications on startup.
class NotificationsLoadRequested extends NotificationEvent {
  const NotificationsLoadRequested();
}

/// A new notification arrived (from FCM or internal).
class NotificationReceived extends NotificationEvent {
  final AppNotification notification;
  const NotificationReceived(this.notification);
  @override
  List<Object?> get props => [notification];
}

/// Mark a single notification as read.
class NotificationMarkRead extends NotificationEvent {
  final String id;
  const NotificationMarkRead(this.id);
  @override
  List<Object?> get props => [id];
}

/// Mark all notifications as read.
class NotificationMarkAllRead extends NotificationEvent {
  const NotificationMarkAllRead();
}

/// Delete a single notification.
class NotificationDeleted extends NotificationEvent {
  final String id;
  const NotificationDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

/// Clear all notifications.
class NotificationsClearAll extends NotificationEvent {
  const NotificationsClearAll();
}

/// Post an in-app security alert (used by SecurityBloc / VaultBloc).
class SecurityAlertPosted extends NotificationEvent {
  final String titleAr;
  final String bodyAr;
  final AppNotificationType type;
  final String? route;
  const SecurityAlertPosted({
    required this.titleAr,
    required this.bodyAr,
    this.type = AppNotificationType.security,
    this.route,
  });
  @override
  List<Object?> get props => [titleAr, bodyAr, type, route];
}
