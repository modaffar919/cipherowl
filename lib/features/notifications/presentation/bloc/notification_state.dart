import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<AppNotification> notifications;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<AppNotification> get criticalNotifications =>
      notifications.where((n) => n.type.isCritical).toList();

  List<AppNotification> get unread =>
      notifications.where((n) => !n.isRead).toList();

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotification>? notifications,
    String? errorMessage,
  }) {
    return NotificationState(
      status:        status        ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage:  errorMessage  ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, errorMessage];
}
