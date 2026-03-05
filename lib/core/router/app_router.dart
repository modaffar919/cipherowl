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
import '../../features/enterprise/presentation/screens/admin_dashboard_screen.dart';
import '../../features/enterprise/presentation/screens/sso_settings_screen.dart';
import '../../features/auth/presentation/screens/fido2_management_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/academy/data/academy_content.dart';
import '../../features/academy/domain/entities/academy_module.dart';
import '../../features/academy/presentation/screens/module_detail_screen.dart';
import '../../features/academy/presentation/screens/quiz_screen.dart';
import '../../features/gamification/presentation/screens/badges_screen.dart';
import '../../features/academy/presentation/screens/daily_challenge_screen.dart';
import '../constants/app_constants.dart';

// ── Transition helpers ───────────────────────────────────────────────────────

/// Fade + slide from right (default drill-down transition).
Page<T> _slideRight<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          ),
        );
      },
    );

/// Fade only (top-level tab-like navigation).
Page<T> _fade<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );

/// Slide up from bottom (modal / auxiliary screens).
Page<T> _slideUp<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          ),
        );
      },
    );

/// Look up an [AcademyModule] by id (falls back to first module).
AcademyModule _findModule(String id) =>
    AcademyContent.modules.firstWhere((m) => m.id == id,
        orElse: () => AcademyContent.modules.first);

abstract class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: true,
    routes: [
      // ── Splash ──────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSplash,
        pageBuilder: (context, state) => _fade(state, const SplashScreen()),
      ),

      // ── Onboarding ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeOnboarding,
        pageBuilder: (context, state) => _fade(state, const OnboardingScreen()),
      ),

      // ── Setup (First Time) ──────────────────────────────
      GoRoute(
        path: AppConstants.routeSetup,
        pageBuilder: (context, state) => _slideRight(state, const SetupScreen()),
      ),

      // ── Lock Screen ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeLock,
        pageBuilder: (context, state) => _fade(state, const LockScreen()),
      ),

      // ── Main App Shell ───────────────────────────────────
      GoRoute(
        path: AppConstants.routeDashboard,
        pageBuilder: (context, state) => _fade(state, const DashboardScreen()),
        routes: [
          GoRoute(
            path: 'vault',
            pageBuilder: (context, state) =>
                _slideRight(state, const VaultListScreen()),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) =>
                    _slideUp(state, const AddEditItemScreen()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _slideRight(
                  state,
                  VaultItemDetailScreen(
                    itemId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => _slideUp(
                      state,
                      AddEditItemScreen(
                        itemId: state.pathParameters['id'],
                      ),
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
        pageBuilder: (context, state) =>
            _slideUp(state, const GeneratorScreen()),
      ),

      // ── Security Center ──────────────────────────────────
      GoRoute(
        path: AppConstants.routeSecurityCenter,
        pageBuilder: (context, state) =>
            _slideRight(state, const SecurityCenterScreen()),
      ),

      // ── Academy ─────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeAcademy,
        pageBuilder: (context, state) =>
            _slideRight(state, const AcademyScreen()),
      ),

      // ── Settings ─────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSettings,
        pageBuilder: (context, state) =>
            _slideRight(state, const SettingsScreen()),
      ),

      // ── Face Setup ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeFaceSetup,
        pageBuilder: (context, state) =>
            _slideUp(state, const FaceSetupScreen()),
      ),

      // ── Sharing ─────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSharing,
        pageBuilder: (context, state) =>
            _slideUp(state, const SharingScreen()),
      ),

      // ── Enterprise ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeEnterprise,
        pageBuilder: (context, state) =>
            _slideRight(state, const EnterpriseScreen()),
      ),

      // ── Admin Dashboard ───────────────────────────────────
      GoRoute(
        path: AppConstants.routeAdminDashboard,
        pageBuilder: (context, state) =>
            _slideRight(state, const AdminDashboardScreen()),
      ),

      // ── SSO Settings ──────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSsoSettings,
        pageBuilder: (context, state) =>
            _slideRight(state, const SsoSettingsScreen()),
      ),

      // ── FIDO2 Management ────────────────────────────────
      GoRoute(
        path: AppConstants.routeFido2Manage,
        pageBuilder: (context, state) =>
            _slideRight(state, const Fido2ManagementScreen()),
      ),

      // ── Import / Export ───────────────────────────────────────
      GoRoute(
        path: AppConstants.routeImportExport,
        pageBuilder: (context, state) =>
            _slideRight(state, const ImportExportScreen()),
      ),
      // ── Notification Centre ──────────────────────────────
      GoRoute(
        path: AppConstants.routeNotifications,
        pageBuilder: (context, state) =>
            _slideRight(state, const NotificationCenterScreen()),
      ),

      // ── Academy sub-routes ───────────────────────────────
      GoRoute(
        path: AppConstants.routeAcademyModule,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final module = _findModule(id);
          return _slideRight(state, ModuleDetailScreen(module: module));
        },
      ),
      GoRoute(
        path: AppConstants.routeAcademyQuiz,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slideRight(state, QuizScreen(moduleId: id));
        },
      ),
      GoRoute(
        path: AppConstants.routeAcademyBadges,
        pageBuilder: (context, state) =>
            _slideRight(state, const BadgesScreen()),
      ),
      GoRoute(
        path: AppConstants.routeAcademyDaily,
        pageBuilder: (context, state) =>
            _slideUp(state, const DailyChallengeScreen()),
      ),
    ],

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

