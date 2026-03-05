import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/lock_screen.dart';
import '../../features/auth/presentation/screens/setup_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/vault/presentation/screens/dashboard_screen.dart';
import '../../features/vault/presentation/screens/vault_list_screen.dart';
import '../../features/vault/presentation/screens/vault_item_detail_screen.dart';
import '../../features/vault/presentation/screens/add_edit_item_screen.dart';
import '../../features/generator/presentation/generator_screen.dart';
import '../../features/security_center/presentation/screens/security_center_screen.dart';
import '../../features/academy/presentation/screens/academy_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/face_track/presentation/screens/face_setup_screen.dart';
import '../../features/vault/presentation/screens/import_export_screen.dart';
import '../../features/sharing/presentation/screens/sharing_screen.dart';
import '../../features/enterprise/presentation/screens/enterprise_screen.dart';
import '../../features/auth/presentation/screens/fido2_management_screen.dart';
import '../constants/app_constants.dart';

abstract class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: true,
    routes: [
      // ── Splash ──────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Setup (First Time) ──────────────────────────────
      GoRoute(
        path: AppConstants.routeSetup,
        builder: (context, state) => const SetupScreen(),
      ),

      // ── Lock Screen ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeLock,
        builder: (context, state) => const LockScreen(),
      ),

      // ── Main App Shell ───────────────────────────────────
      GoRoute(
        path: AppConstants.routeDashboard,
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'vault',
            builder: (context, state) => const VaultListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddEditItemScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => VaultItemDetailScreen(
                  itemId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => AddEditItemScreen(
                      itemId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Generator ───────────────────────────────────────
      GoRoute(
        path: AppConstants.routeGenerator,
        builder: (context, state) => const GeneratorScreen(),
      ),

      // ── Security Center ──────────────────────────────────
      GoRoute(
        path: AppConstants.routeSecurityCenter,
        builder: (context, state) => const SecurityCenterScreen(),
      ),

      // ── Academy ─────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeAcademy,
        builder: (context, state) => const AcademyScreen(),
      ),

      // ── Settings ─────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSettings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Face Setup ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeFaceSetup,
        builder: (context, state) => const FaceSetupScreen(),
      ),

      // ── Sharing ─────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSharing,
        builder: (context, state) => const SharingScreen(),
      ),

      // ── Enterprise ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeEnterprise,
        builder: (context, state) => const EnterpriseScreen(),
      ),

      // ── FIDO2 Management ────────────────────────────────
      GoRoute(
        path: AppConstants.routeFido2Manage,
        builder: (context, state) => const Fido2ManagementScreen(),
      ),
      // ── Import / Export ───────────────────────────────────────
      GoRoute(
        path: AppConstants.routeImportExport,
        builder: (context, state) => const ImportExportScreen(),
      ),    ],

    // ── Error handler ────────────────────────────────────
    errorBuilder: (context, state) => const _ErrorScreen(),
  );
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('404 - Page not found', style: TextStyle(color: Colors.white))),
  );
}

