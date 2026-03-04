import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/database/smartvault_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/vault/data/repositories/vault_repository.dart';
import 'features/vault/presentation/bloc/vault_bloc.dart';

class CipherOwlApp extends StatelessWidget {
  const CipherOwlApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Singletons — created once, disposed when the widget tree is torn down.
    final db = SmartVaultDatabase();
    final vaultRepo = VaultRepository(db);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SmartVaultDatabase>.value(value: db),
        RepositoryProvider<VaultRepository>.value(value: vaultRepo),
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
          create: (_) => VaultBloc(repository: vaultRepo),
          lazy: true,
        ),
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
