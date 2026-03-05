import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

/// Provides access to the Supabase client initialized in [main.dart].
///
/// Setup guide:
/// 1. Go to https://app.supabase.com → New project
/// 2. Copy "Project URL" → set [AppConstants.supabaseUrl]
/// 3. Copy "anon (public)" key → set [AppConstants.supabaseAnonKey]
/// 4. Run migrations: supabase db push (or paste SQL in Supabase Dashboard → SQL Editor)
/// 5. Enable Google OAuth: Supabase Dashboard → Auth → Providers → Google
///
/// The client is safe to call after [Supabase.initialize()] completes in main.
class SupabaseClientProvider {
  SupabaseClientProvider._();

  /// Returns the Supabase client singleton.
  static SupabaseClient get client => Supabase.instance.client;

  /// Currently signed-in cloud user, or null if not signed in.
  static User? get currentUser => client.auth.currentUser;

  /// Stream of cloud auth state changes.
  static Stream<AuthState> get authStateStream =>
      client.auth.onAuthStateChange;

  /// True once real project credentials are set (not placeholder values).
  static bool get isConfigured =>
      !AppConstants.supabaseUrl.contains('YOUR_PROJECT') &&
      !AppConstants.supabaseAnonKey.contains('YOUR_ANON_KEY');
}