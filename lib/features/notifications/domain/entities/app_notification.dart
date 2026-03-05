import 'package:equatable/equatable.dart';

/// Types of in-app notifications.
enum AppNotificationType {
  breach,        // Dark-web / HaveIBeenPwned breach alert
  suspiciousLogin, // Unusual sign-in detected
  weakPassword,  // Weak/reused password recommendation
  syncComplete,  // Vault sync succeeded
  achievement,   // Gamification badge/XP unlocked
  security,      // Generic security recommendation
  system,        // App-level system message
}

extension AppNotificationTypeX on AppNotificationType {
  String get labelAr {
    switch (this) {
      case AppNotificationType.breach:          return 'تنبيه اختراق';
      case AppNotificationType.suspiciousLogin: return 'نشاط مشبوه';
      case AppNotificationType.weakPassword:    return 'كلمة مرور ضعيفة';
      case AppNotificationType.syncComplete:    return 'مزامنة';
      case AppNotificationType.achievement:     return 'إنجاز';
      case AppNotificationType.security:        return 'أمان';
      case AppNotificationType.system:          return 'نظام';
    }
  }

  bool get isCritical =>
      this == AppNotificationType.breach ||
      this == AppNotificationType.suspiciousLogin;
}

/// Immutable domain entity for a single notification.
class AppNotification extends Equatable {
  final String id;
  final AppNotificationType type;
  final String titleAr;
  final String bodyAr;
  final bool isRead;
  final DateTime createdAt;
  /// Optional deep-link route (e.g. /security-center)
  final String? route;
  /// Optional payload for routing (e.g. vault item id)
  final Map<String, dynamic>? payload;

  const AppNotification({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.bodyAr,
    this.isRead = false,
    required this.createdAt,
    this.route,
    this.payload,
  });

  AppNotification copyWith({
    String? id,
    AppNotificationType? type,
    String? titleAr,
    String? bodyAr,
    bool? isRead,
    DateTime? createdAt,
    String? route,
    Map<String, dynamic>? payload,
  }) {
    return AppNotification(
      id:        id        ?? this.id,
      type:      type      ?? this.type,
      titleAr:   titleAr   ?? this.titleAr,
      bodyAr:    bodyAr    ?? this.bodyAr,
      isRead:    isRead    ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      route:     route     ?? this.route,
      payload:   payload   ?? this.payload,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:        json['id'] as String,
      type:      AppNotificationType.values.firstWhere(
                   (e) => e.name == json['type'],
                   orElse: () => AppNotificationType.system,
                 ),
      titleAr:   json['titleAr'] as String,
      bodyAr:    json['bodyAr'] as String,
      isRead:    json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      route:     json['route'] as String?,
      payload:   json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'type':      type.name,
    'titleAr':   titleAr,
    'bodyAr':    bodyAr,
    'isRead':    isRead,
    'createdAt': createdAt.toIso8601String(),
    if (route   != null) 'route':   route,
    if (payload != null) 'payload': payload,
  };

  @override
  List<Object?> get props => [id, type, titleAr, bodyAr, isRead, createdAt, route, payload];
}
