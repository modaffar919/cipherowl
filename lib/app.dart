import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/crypto/vault_crypto_service.dart';
import 'core/database/smartvault_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/gamification/presentation/bloc/gamification_bloc.dart';
import 'features/security_center/presentation/bloc/security_bloc.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/autofill/browser_autofill_sync_service.dart';
import 'features/vault/data/repositories/vault_repository.dart';
import 'features/vault/presentation/bloc/vault_bloc.dart';
import 'features/enterprise/data/repositories/org_repository.dart';
import 'features/enterprise/presentation/bloc/org_bloc.dart';
import 'features/notifications/data/repositories/notification_repository.dart';
import 'features/notifications/data/services/fcm_service.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
import 'core/supabase/supabase_client_provider.dart';

class CipherOwlApp extends StatefulWidget {
  final SmartVaultDatabase db;
  const CipherOwlApp({super.key, required this.db});

  @override
  State<CipherOwlApp> createState() => _CipherOwlAppState();
}

class _CipherOwlAppState extends State<CipherOwlApp> {
  // ── Repositories & Services ───────────────────────────────────────────────
  late final VaultRepository _vaultRepo;
  late final VaultCryptoService _vaultCrypto;
  late final BrowserAutofillSyncService _browserSync;
  late final SettingsRepository _settingsRepo;
  late final OrgRepository _orgRepo;
  late final NotificationRepository _notifRepo;

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  late final NotificationBloc _notifBloc;

  @override
  void initState() {
    super.initState();
    _vaultRepo    = VaultRepository(widget.db);
    _vaultCrypto  = VaultCryptoService();
    _browserSync  = BrowserAutofillSyncService();
    _settingsRepo = SettingsRepository(widget.db);
    _orgRepo      = OrgRepository(SupabaseClientProvider.client);
    _notifRepo    = NotificationRepository();

    _notifBloc = NotificationBloc(_notifRepo)
      ..add(const NotificationsLoadRequested());

    // FCM: store incoming messages in repo and forward to BLoC.
    FcmService.instance.onNotificationReceived =
        (n) => _notifBloc.add(NotificationReceived(n));
    // ignore: discarded_futures
    FcmService.instance.init(_notifRepo);
  }

  @override
  void dispose() {
    _notifBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SmartVaultDatabase>.value(value: widget.db),
        RepositoryProvider<VaultRepository>.value(value: _vaultRepo),
        RepositoryProvider<VaultCryptoService>.value(value: _vaultCrypto),
        RepositoryProvider<BrowserAutofillSyncService>.value(value: _browserSync),
        RepositoryProvider<SettingsRepository>.value(value: _settingsRepo),
        RepositoryProvider<OrgRepository>.value(value: _orgRepo),
        RepositoryProvider<NotificationRepository>.value(value: _notifRepo),
      ],
      child: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: AuthRepository(),
          )..add(const AuthAppStarted()),
          lazy: false,
        ),
        BlocProvider<VaultBloc>(
          create: (_) => VaultBloc(
            repository: _vaultRepo,
            cryptoService: _vaultCrypto,
            browserSyncService: _browserSync,
          ),
          lazy: true,
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(repository: _settingsRepo)
            ..add(const SettingsStarted()),
          lazy: false,
        ),
        BlocProvider<SecurityBloc>(
          create: (_) => SecurityBloc(),
          lazy: true,
        ),
        BlocProvider<GamificationBloc>(
          create: (_) => GamificationBloc()..add(const GamificationStarted()),
          lazy: false,
        ),
        BlocProvider<OrgBloc>(
          create: (_) => OrgBloc(_orgRepo),
          lazy: true,
        ),
        BlocProvider<NotificationBloc>.value(value: _notifBloc),
      ],
      child: ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'CipherOwl',
          debugShowCheckedModeBanner: false,

          // ── Routing ──────────────────────────────────────
          routerConfig: AppRouter.router,

          // ── Theming ──────────────────────────────────────
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,

          // ── Localization ─────────────────────────────────
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'), // Arabic (primary)
            Locale('en'), // English
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return const Locale('ar');
            for (final supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return const Locale('ar');
          },
        );
      },
      ),  // ScreenUtilInit
    ),    // MultiBlocProvider
    );    // MultiRepositoryProvider
  }
}
