import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_key_service.dart';
import 'core/database/smartvault_database.dart';
import 'core/firebase/firebase_service.dart';
import 'core/monitoring/app_monitor.dart';
import 'features/notifications/data/services/fcm_service.dart';
import 'src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── App health monitoring ──────────────────────────────
  AppMonitor.instance.init();

  // ── Rust FFI init (must be first) ──────────────────────
  await RustLib.init();

  // ── Firebase init (optional — continues on failure) ─────
  await FirebaseService.init();
  await LocalNotificationService.instance.init();

  // ── Lock orientation to portrait on mobile ──────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar & navigation bar style ──────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppConstants.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ── Supabase init ────────────────────────────────────────
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // ── BLoC observer (debug only) ──────────────────────────
  assert(() {
    Bloc.observer = _AppBlocObserver();
    return true;
  }());

  // ── Encrypted database init ─────────────────────────
  final dbKey = await DatabaseKeyService.getDatabaseKey();
  final db = SmartVaultDatabase(encryptionKey: dbKey);

  runApp(CipherOwlApp(db: db));
}

class _AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('[BLoC Error] ${bloc.runtimeType}: $error');
    AppMonitor.instance.logSecurityEvent(
      'bloc_error',
      metadata: {'bloc': '${bloc.runtimeType}', 'error': '$error'},
    );
  }
}
