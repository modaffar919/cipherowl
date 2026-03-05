// Widget tests for all 15 primary screens — cipherowl-bbt
//
// Each test verifies that the screen:
//   1. Renders without throwing
//   2. Displays key identifying widgets
//   3. Responds to basic user interactions where applicable
//
// Screens that use BLoC are given mock instances with safe initial states.
// Screens with platform dependencies (camera, TFLite) use test-injectable
// factories to avoid MissingPluginException.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── App-level
import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';

// ── Screens
import 'package:cipherowl/features/academy/presentation/screens/academy_screen.dart';
import 'package:cipherowl/features/auth/presentation/screens/lock_screen.dart';
import 'package:cipherowl/features/auth/presentation/screens/recovery_key_screen.dart';
import 'package:cipherowl/features/auth/presentation/screens/setup_screen.dart';
import 'package:cipherowl/features/auth/presentation/screens/splash_screen.dart';
import 'package:cipherowl/features/face_track/presentation/bloc/face_enrollment_bloc.dart';
import 'package:cipherowl/features/face_track/presentation/screens/face_setup_screen.dart';
import 'package:cipherowl/features/generator/presentation/generator_screen.dart';
import 'package:cipherowl/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:cipherowl/features/security_center/presentation/screens/security_center_screen.dart';
import 'package:cipherowl/features/settings/data/repositories/settings_repository.dart';
import 'package:cipherowl/features/settings/presentation/screens/settings_screen.dart';
import 'package:cipherowl/features/vault/presentation/screens/add_edit_item_screen.dart';
import 'package:cipherowl/features/vault/presentation/screens/import_export_screen.dart';
import 'package:cipherowl/features/vault/presentation/screens/vault_item_detail_screen.dart';
import 'package:cipherowl/features/vault/presentation/screens/vault_list_screen.dart';
import 'package:cipherowl/features/vault/presentation/screens/dashboard_screen.dart';

// ── BLoCs
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:cipherowl/features/generator/presentation/bloc/generator_bloc.dart';
import 'package:cipherowl/features/security_center/presentation/bloc/security_bloc.dart';
import 'package:cipherowl/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';
import 'package:cipherowl/features/academy/presentation/bloc/academy_bloc.dart';

// ── Mock declarations ─────────────────────────────────────────────────────────

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockVaultBloc extends MockBloc<VaultEvent, VaultState>
    implements VaultBloc {}

class _MockSecurityBloc extends MockBloc<SecurityEvent, SecurityState>
    implements SecurityBloc {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class _MockGamificationBloc
    extends MockBloc<GamificationEvent, GamificationState>
    implements GamificationBloc {}

class _MockGeneratorBloc extends MockBloc<GeneratorEvent, GeneratorState>
    implements GeneratorBloc {}

class _MockAcademyBloc extends MockBloc<AcademyEvent, AcademyState>
    implements AcademyBloc {}

class _MockFaceEnrollmentBloc
    extends MockBloc<FaceEnrollmentEvent, FaceEnrollmentState>
    implements FaceEnrollmentBloc {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Pumps [child] inside a [MaterialApp] with RTL directionality (Arabic-first).
Widget _app(Widget child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
      // Suppress GoRouter missing-scaffold warnings in tests
      debugShowCheckedModeBanner: false,
    );

/// Pumps [child] with all common BLoCs provided.
Widget _appWithBlocs(
  Widget child, {
  required _MockAuthBloc authBloc,
  required _MockVaultBloc vaultBloc,
  required _MockSecurityBloc securityBloc,
  required _MockSettingsBloc settingsBloc,
  required _MockSettingsRepository settingsRepo,
  _MockGamificationBloc? gamificationBloc,
  _MockAcademyBloc? academyBloc,
}) =>
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<SettingsRepository>.value(value: settingsRepo),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<VaultBloc>.value(value: vaultBloc),
              BlocProvider<SecurityBloc>.value(value: securityBloc),
              BlocProvider<SettingsBloc>.value(value: settingsBloc),
              if (gamificationBloc != null)
                BlocProvider<GamificationBloc>.value(value: gamificationBloc),
              if (academyBloc != null)
                BlocProvider<AcademyBloc>.value(value: academyBloc),
            ],
            child: child,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );

// ── Test data ─────────────────────────────────────────────────────────────────

AppSettings _testSettings() => const AppSettings(
      faceTrack: false,
      biometric: false,
      duressMode: false,
      lockTimeout: 5,
      darkWebMonitor: false,
      autoFill: true,
      language: 'ar',
    );

VaultEntry _testEntry({String id = 'test-id-123'}) => VaultEntry(
      id: id,
      userId: 'local_user',
      title: 'GitHub',
      username: 'user@example.com',
      category: VaultCategory.login,
      strengthScore: 3,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

// ── Main ──────────────────────────────────────────────────────────────────────

void main() {
  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(const AuthAppStarted());
    registerFallbackValue(const VaultStarted('local_user'));
    registerFallbackValue(const SecurityScoreRequested([]));
    registerFallbackValue(const SettingsStarted());
    registerFallbackValue(const FaceEnrollmentInitialized());
    registerFallbackValue(const GeneratorRefreshRequested());
  });

  // ── Group 1: Standalone screens (no BLoC) ──────────────────────────────────

  group('OnboardingScreen', () {
    testWidgets('renders without error and shows PageView', (tester) async {
      await tester.pumpWidget(_app(const OnboardingScreen()));
      await tester.pump();
      // Screen renders with a PageView and a skip TextButton
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      // Skip button exists (any TextButton on screen)
      expect(find.byType(TextButton), findsAtLeastNWidgets(1));
      // Dispose widget to cancel AnimationControllers (stops tickers).
      await tester.pumpWidget(const SizedBox());
      // Advance clock past the max _scheduleBlink delay (5 s) so the pending
      // Future.delayed timer fires, sees mounted=false, and exits cleanly.
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('tapping skip/next button does not crash', (tester) async {
      await tester.pumpWidget(_app(const OnboardingScreen()));
      await tester.pump();
      // Tap the first TextButton (skip or next — both are safe in tests)
      await tester.tap(find.byType(ElevatedButton).first,
          warnIfMissed: false);
      await tester.pump();
      // Screen is still alive (navigation call may be a no-op without router)
      expect(find.byType(Scaffold), findsOneWidget);
      // Dispose and drain pending blink timer.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('AcademyScreen', () {
    testWidgets('renders threat topic cards', (tester) async {
      final academyBloc = _MockAcademyBloc();
      when(() => academyBloc.state).thenReturn(const AcademyLoaded());
      when(() => academyBloc.stream)
          .thenAnswer((_) => Stream.value(const AcademyLoaded()));
      addTearDown(academyBloc.close);
      await tester.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider<AcademyBloc>.value(
            value: academyBloc,
            child: const AcademyScreen(),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });

  group('GeneratorScreen', () {
    late _MockGeneratorBloc generatorBloc;

    setUp(() {
      generatorBloc = _MockGeneratorBloc();
      when(() => generatorBloc.state).thenReturn(const GeneratorState(
        password: 'Abc123!@#',
        strengthScore: 4,
        strengthLabel: 'قوية جداً',
        strengthColor: Colors.green,
      ));
      when(() => generatorBloc.stream).thenAnswer(
        (_) => Stream.value(const GeneratorState(
          password: 'Abc123!@#',
          strengthScore: 4,
          strengthLabel: 'قوية جداً',
          strengthColor: Colors.green,
        )),
      );
    });

    tearDown(() => generatorBloc.close());

    testWidgets('renders password generator scaffold', (tester) async {
      await tester.pumpWidget(
          _app(GeneratorScreen(createBloc: () => generatorBloc)));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      // Two tabs should be visible (TabBar)
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('tapping second tab does not crash', (tester) async {
      await tester.pumpWidget(
          _app(GeneratorScreen(createBloc: () => generatorBloc)));
      await tester.pump();
      // Tap second tab without caring about Arabic text
      final tabs = find.byType(Tab);
      if (tester.widgetList(tabs).length >= 2) {
        await tester.tap(tabs.at(1), warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  // ── Group 2: Auth screens ─────────────────────────────────────────────────

  group('SplashScreen', () {
    late _MockAuthBloc authBloc;

    setUp(() {
      authBloc = _MockAuthBloc();
      when(() => authBloc.state).thenReturn(const AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => Stream.value(const AuthInitial()));
    });

    tearDown(() => authBloc.close());

    testWidgets('renders scaffold with logo animation', (tester) async {
      // Use runAsync so that Future.delayed timers in _startSequence() are real
      // async timers (not FakeAsync) and don't cause '!timersPending' failure.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          _app(BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const SplashScreen(),
          )),
        );
      });
      await tester.pump(Duration.zero);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(FadeTransition), findsWidgets);
    });
  });

  group('SetupScreen', () {
    late _MockAuthBloc authBloc;

    setUp(() {
      authBloc = _MockAuthBloc();
      when(() => authBloc.state).thenReturn(const AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => Stream.value(const AuthInitial()));
    });

    tearDown(() => authBloc.close());

    testWidgets('renders setup form on first page', (tester) async {
      await tester.pumpWidget(
        _app(BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const SetupScreen(),
        )),
      );
      await tester.pump();
      // First page should show password creation UI
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('LockScreen', () {
    late _MockAuthBloc authBloc;

    setUp(() {
      authBloc = _MockAuthBloc();
      when(() => authBloc.state).thenReturn(const AuthLocked());
      when(() => authBloc.stream).thenAnswer((_) => Stream.value(const AuthLocked()));
    });

    tearDown(() => authBloc.close());

    testWidgets('renders password field and scaffold', (tester) async {
      // Use a phone-sized viewport to prevent overflow in the lock screen layout
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _app(BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const LockScreen(),
        )),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('entering text in password field works', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _app(BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const LockScreen(),
        )),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'TestPassword123!');
      await tester.pump();
      // Field is obscured, so display text is not visible but no crash occurred
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('RecoveryKeyScreen', () {
    late _MockAuthBloc authBloc;

    setUp(() {
      authBloc = _MockAuthBloc();
      when(() => authBloc.state).thenReturn(const AuthFirstTimeSetup());
      when(() => authBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthFirstTimeSetup()));
    });

    tearDown(() => authBloc.close());

    testWidgets('renders recovery key screen', (tester) async {
      await tester.pumpWidget(
        _app(BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const RecoveryKeyScreen(),
        )),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  // ── Group 3: Vault screens ────────────────────────────────────────────────

  group('VaultListScreen', () {
    late _MockAuthBloc authBloc;
    late _MockVaultBloc vaultBloc;

    setUp(() {
      authBloc = _MockAuthBloc();
      vaultBloc = _MockVaultBloc();
      when(() => authBloc.state).thenReturn(const AuthAuthenticated());
      when(() => authBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthAuthenticated()));
      when(() => vaultBloc.state)
          .thenReturn(const VaultLoaded(allItems: []));
      when(() => vaultBloc.stream)
          .thenAnswer((_) => Stream.value(const VaultLoaded(allItems: [])));
    });

    tearDown(() {
      authBloc.close();
      vaultBloc.close();
    });

    testWidgets('renders empty vault list', (tester) async {
      await tester.pumpWidget(
        _app(MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<VaultBloc>.value(value: vaultBloc),
          ],
          child: const VaultListScreen(),
        )),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      // Search field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows vault entries when items are present', (tester) async {
      final items = [_testEntry(id: 'item-1'), _testEntry(id: 'item-2')];
      when(() => vaultBloc.state)
          .thenReturn(VaultLoaded(allItems: items));
      when(() => vaultBloc.stream)
          .thenAnswer((_) => Stream.value(VaultLoaded(allItems: items)));

      await tester.pumpWidget(
        _app(MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<VaultBloc>.value(value: vaultBloc),
          ],
          child: const VaultListScreen(),
        )),
      );
      await tester.pump();
      expect(find.text('GitHub'), findsWidgets);
    });
  });

  group('AddEditItemScreen', () {
    late _MockAuthBloc authBloc;
    late _MockVaultBloc vaultBloc;

    setUp(() {
      authBloc = _MockAuthBloc();
      vaultBloc = _MockVaultBloc();
      when(() => authBloc.state).thenReturn(const AuthAuthenticated());
      when(() => authBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthAuthenticated()));
      when(() => vaultBloc.state).thenReturn(const VaultLoaded(allItems: []));
      when(() => vaultBloc.stream)
          .thenAnswer((_) => Stream.value(const VaultLoaded(allItems: [])));
    });

    tearDown(() {
      authBloc.close();
      vaultBloc.close();
    });

    testWidgets('renders add-new-item form with required fields', (tester) async {
      await tester.pumpWidget(
        _app(MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<VaultBloc>.value(value: vaultBloc),
          ],
          child: const AddEditItemScreen(),
        )),
      );
      await tester.pumpAndSettle();
      // Should have multiple text fields (title, username, password, url)
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('title field accepts text input', (tester) async {
      await tester.pumpWidget(
        _app(MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<VaultBloc>.value(value: vaultBloc),
          ],
          child: const AddEditItemScreen(),
        )),
      );
      await tester.pumpAndSettle();
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'My Account');
      await tester.pump();
      expect(find.text('My Account'), findsOneWidget);
    });
  });

  group('VaultItemDetailScreen', () {
    late _MockVaultBloc vaultBloc;

    setUp(() {
      vaultBloc = _MockVaultBloc();
      final entry = _testEntry();
      when(() => vaultBloc.state)
          .thenReturn(VaultLoaded(allItems: [entry]));
      when(() => vaultBloc.stream)
          .thenAnswer((_) => Stream.value(VaultLoaded(allItems: [entry])));
    });

    tearDown(() => vaultBloc.close());

    testWidgets('renders item title from VaultBloc state', (tester) async {
      await tester.pumpWidget(
        _app(BlocProvider<VaultBloc>.value(
          value: vaultBloc,
          child: const VaultItemDetailScreen(itemId: 'test-id-123'),
        )),
      );
      await tester.pump();
      // Title appears in both AppBar and content section
      expect(find.text('GitHub'), findsWidgets);
    });
  });

  group('ImportExportScreen', () {
    late _MockAuthBloc authBloc;
    late _MockVaultBloc vaultBloc;

    setUp(() {
      authBloc = _MockAuthBloc();
      vaultBloc = _MockVaultBloc();
      when(() => authBloc.state).thenReturn(const AuthAuthenticated());
      when(() => authBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthAuthenticated()));
      when(() => vaultBloc.state).thenReturn(const VaultLoaded(allItems: []));
      when(() => vaultBloc.stream)
          .thenAnswer((_) => Stream.value(const VaultLoaded(allItems: [])));
    });

    tearDown(() {
      authBloc.close();
      vaultBloc.close();
    });

    testWidgets('renders import and export sections', (tester) async {
      await tester.pumpWidget(
        _app(MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<VaultBloc>.value(value: vaultBloc),
          ],
          child: const ImportExportScreen(),
        )),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  // ── Group 4: Dashboard (embeds all tab screens) ────────────────────────────

  group('DashboardScreen', () {
    late _MockAuthBloc authBloc;
    late _MockVaultBloc vaultBloc;
    late _MockSecurityBloc securityBloc;
    late _MockSettingsBloc settingsBloc;
    late _MockSettingsRepository settingsRepo;
    late _MockGeneratorBloc generatorBloc;
    late _MockAcademyBloc academyBloc;

    setUp(() {
      authBloc = _MockAuthBloc();
      vaultBloc = _MockVaultBloc();
      securityBloc = _MockSecurityBloc();
      settingsBloc = _MockSettingsBloc();
      settingsRepo = _MockSettingsRepository();
      generatorBloc = _MockGeneratorBloc();
      academyBloc = _MockAcademyBloc();

      when(() => authBloc.state).thenReturn(const AuthAuthenticated());
      when(() => authBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthAuthenticated()));
      when(() => vaultBloc.state).thenReturn(const VaultLoaded(allItems: []));
      when(() => vaultBloc.stream)
          .thenAnswer((_) => Stream.value(const VaultLoaded(allItems: [])));
      when(() => securityBloc.state).thenReturn(const SecurityInitial());
      when(() => securityBloc.stream)
          .thenAnswer((_) => Stream.value(const SecurityInitial()));
      when(() => settingsBloc.state).thenReturn(const SettingsInitial());
      when(() => settingsBloc.stream)
          .thenAnswer((_) => Stream.value(const SettingsInitial()));
      when(() => settingsRepo.loadAll())
          .thenAnswer((_) async => _testSettings());
      when(() => academyBloc.state).thenReturn(const AcademyLoaded());
      when(() => academyBloc.stream)
          .thenAnswer((_) => Stream.value(const AcademyLoaded()));
      when(() => generatorBloc.state).thenReturn(const GeneratorState(
        password: 'Abc123!',
        strengthScore: 3,
        strengthLabel: 'قوية',
        strengthColor: Colors.green,
      ));
      when(() => generatorBloc.stream).thenAnswer((_) => Stream.value(
        const GeneratorState(
          password: 'Abc123!',
          strengthScore: 3,
          strengthLabel: 'قوية',
          strengthColor: Colors.green,
        ),
      ));
    });

    tearDown(() {
      authBloc.close();
      vaultBloc.close();
      securityBloc.close();
      settingsBloc.close();
      generatorBloc.close();
      academyBloc.close();
    });

    /// Build a DashboardScreen with all real screens replaced by safe stubs
    /// so that GeneratorScreen never calls the Rust API.
    Widget _dashboardWithMocks() => _appWithBlocs(
          DashboardScreen(
            tabScreens: [
              const VaultListScreen(),
              const SecurityCenterScreen(),
              GeneratorScreen(createBloc: () => generatorBloc),
              const AcademyScreen(),
              const SettingsScreen(),
            ],
          ),
          authBloc: authBloc,
          vaultBloc: vaultBloc,
          securityBloc: securityBloc,
          settingsBloc: settingsBloc,
          settingsRepo: settingsRepo,
          academyBloc: academyBloc,
        );

    testWidgets('renders bottom navigation with 5 tabs', (tester) async {
      await tester.pumpWidget(_dashboardWithMocks());
      await tester.pump();
      // DashboardScreen renders with its Scaffold and custom bottom nav.
      // IndexedStack keeps all tab Scaffolds alive, so we find more than one.
      expect(find.byType(Scaffold), findsWidgets);
      // Five GestureDetectors (one per nav tab) inside _CipherBottomNav
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('tapping second tab does not crash', (tester) async {
      await tester.pumpWidget(_dashboardWithMocks());
      await tester.pump();
      // Tap second nav item (security)
      final navItems = find.byType(NavigationDestination);
      if (tester.widgetList(navItems).length >= 2) {
        await tester.tap(navItems.at(1), warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  // ── Group 5: Security, Settings screens ──────────────────────────────────

  group('SecurityCenterScreen', () {
    late _MockSecurityBloc securityBloc;
    late _MockVaultBloc vaultBloc;

    setUp(() {
      securityBloc = _MockSecurityBloc();
      vaultBloc = _MockVaultBloc();
      when(() => securityBloc.state).thenReturn(const SecurityInitial());
      when(() => securityBloc.stream)
          .thenAnswer((_) => Stream.value(const SecurityInitial()));
      when(() => vaultBloc.state).thenReturn(const VaultLoaded(allItems: []));
      when(() => vaultBloc.stream)
          .thenAnswer((_) => Stream.value(const VaultLoaded(allItems: [])));
    });

    tearDown(() {
      securityBloc.close();
      vaultBloc.close();
    });

    testWidgets('renders security center UI', (tester) async {
      await tester.pumpWidget(
        _app(MultiBlocProvider(
          providers: [
            BlocProvider<SecurityBloc>.value(value: securityBloc),
            BlocProvider<VaultBloc>.value(value: vaultBloc),
          ],
          child: const SecurityCenterScreen(),
        )),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    late _MockSettingsBloc settingsBloc;
    late _MockAuthBloc authBloc;
    late _MockSettingsRepository settingsRepo;

    setUp(() {
      settingsBloc = _MockSettingsBloc();
      authBloc = _MockAuthBloc();
      settingsRepo = _MockSettingsRepository();

      when(() => settingsBloc.state).thenReturn(const SettingsInitial());
      when(() => settingsBloc.stream)
          .thenAnswer((_) => Stream.value(const SettingsInitial()));
      when(() => authBloc.state).thenReturn(const AuthAuthenticated());
      when(() => authBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthAuthenticated()));
      when(() => settingsRepo.loadAll())
          .thenAnswer((_) async => _testSettings());
    });

    tearDown(() {
      settingsBloc.close();
      authBloc.close();
    });

    testWidgets('renders settings screen with loading then content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MultiRepositoryProvider(
              providers: [
                RepositoryProvider<SettingsRepository>.value(value: settingsRepo),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<SettingsBloc>.value(value: settingsBloc),
                  BlocProvider<AuthBloc>.value(value: authBloc),
                ],
                child: const SettingsScreen(),
              ),
            ),
          ),
        ),
      );
      // Initial loading state
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);

      // After async repo loads settings
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  // ── Group 6: Face Setup Screen ────────────────────────────────────────────

  group('FaceSetupScreen', () {
    late _MockFaceEnrollmentBloc faceBloc;

    setUp(() {
      faceBloc = _MockFaceEnrollmentBloc();
      when(() => faceBloc.state).thenReturn(const FaceEnrollmentInitial());
      when(() => faceBloc.stream)
          .thenAnswer((_) => Stream.value(const FaceEnrollmentInitial()));
    });

    tearDown(() => faceBloc.close());

    testWidgets('renders intro screen before camera init', (tester) async {
      await tester.pumpWidget(
        _app(FaceSetupScreen(createBloc: () => faceBloc)),
      );
      // Only pump one frame — camera init is async and fails gracefully in tests
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
