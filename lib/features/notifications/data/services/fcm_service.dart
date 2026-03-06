import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:cipherowl/core/platform/platform_info.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../repositories/notification_repository.dart';

/// Background FCM handler — must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Background messages are stored by LocalNotificationService when the app
  // resumes via FlutterLocalNotificationsPlugin.
}

/// Wraps Firebase Cloud Messaging:
/// - Token registration & refresh
/// - Foreground / background / terminated message handlers
/// - Persisting incoming FCM messages as [AppNotification] objects
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  NotificationRepository? _repo;

  // Callback invoked when a new notification is received (foreground).
  void Function(AppNotification)? onNotificationReceived;

  Future<void> init(NotificationRepository repo) async {
    _repo = repo;

    // Register background handler (must be before any Firebase call).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and persist FCM token to Supabase for push delivery.
    final token = await _fcm.getToken();
    if (token != null) {
      debugPrint('[FCM] Device token: $token');
      await _persistToken(token);
    }

    // Listen for token refresh (e.g. app reinstall, new device).
    _fcm.onTokenRefresh.listen(_persistToken);

    // Foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened from background notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // App launched from terminated state via notification.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleMessageOpenedApp(initial);
  }

  /// Persist FCM token to Supabase profiles table for server push delivery.
  Future<void> _persistToken(String token) async {
    try {
      final user = SupabaseClientProvider.currentUser;
      if (user == null) return;
      await SupabaseClientProvider.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
      debugPrint('[FCM] Token persisted to Supabase');
    } catch (e) {
      debugPrint('[FCM] Failed to persist token: $e');
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = _fromRemoteMessage(message);
    await _repo?.add(notification);
    onNotificationReceived?.call(notification);
    await LocalNotificationService.instance.show(notification);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final notification = _fromRemoteMessage(message);
    onNotificationReceived?.call(notification);
  }

  AppNotification _fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final type = _parseType(data['type'] as String?);
    return AppNotification(
      id:        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type:      type,
      titleAr:   message.notification?.title ?? _defaultTitleFor(type),
      bodyAr:    message.notification?.body  ?? '',
      createdAt: message.sentTime ?? DateTime.now(),
      route:     data['route'] as String?,
    );
  }

  static AppNotificationType _parseType(String? raw) {
    if (raw == null) return AppNotificationType.system;
    try {
      return AppNotificationType.values.firstWhere((e) => e.name == raw);
    } catch (_) {
      return AppNotificationType.system;
    }
  }

  static String _defaultTitleFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.breach:          return 'تنبيه اختراق بيانات!';
      case AppNotificationType.suspiciousLogin: return 'نشاط تسجيل دخول مشبوه';
      case AppNotificationType.weakPassword:    return 'كلمة مرور ضعيفة';
      case AppNotificationType.syncComplete:    return 'تمت المزامنة';
      case AppNotificationType.achievement:     return 'إنجاز جديد!';
      case AppNotificationType.security:        return 'توصية أمنية';
      case AppNotificationType.system:          return 'إشعار النظام';
    }
  }
}

// ── Local Notification helper ────────────────────────────────────────────────

/// Thin wrapper over [FlutterLocalNotificationsPlugin] for showing heads-up
/// banners when the app is in the foreground.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings: settings);

    // Create high-priority channel for security alerts (Android 8+).
    if (PlatformInfo.isAndroid) {
      const channel = AndroidNotificationChannel(
        'cipherowl_security',
        'تنبيهات الأمان',
        description: 'إشعارات مهمة تتعلق بأمان حسابك',
        importance: Importance.max,
        enableVibration: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<void> show(AppNotification n) async {
    if (!_initialized) await init();
    final id = n.id.hashCode.abs() % 2147483647;
    await _plugin.show(
      id: id,
      title: n.titleAr,
      body: n.bodyAr,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'cipherowl_security',
          'تنبيهات الأمان',
          importance: n.type.isCritical ? Importance.max : Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
