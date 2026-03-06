import 'package:supabase_flutter/supabase_flutter.dart';

/// Cloud authentication service using Supabase Auth.
///
/// This service handles *cloud* sign-in / sign-up (email + Google OAuth).
/// It is **separate** from the local master-password auth ([AuthRepository]):
///   - Local auth = master password → unlocks the local encrypted database.
///   - Cloud auth = Supabase session → enables cross-device sync.
///
/// Enable Google OAuth in Supabase Dashboard:
///   Auth → Providers → Google → enter Client ID & Secret from Google Cloud Console.
class SupabaseAuthService {
  final SupabaseClient _client;

  SupabaseAuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Getters ────────────────────────────────────────────────────────────────

  /// Currently signed-in cloud user, or null.
  User? get currentUser => _client.auth.currentUser;

  /// True if a cloud session is active.
  bool get isSignedIn => currentUser != null;

  /// Stream of auth state changes (sign-in, sign-out, token refresh).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Email ──────────────────────────────────────────────────────────────────

  /// Sign up with email and password. Supabase sends a confirmation email.
  ///
  /// Throws [AuthException] on failure (e.g., email already in use).
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'full_name': displayName} : null,
      );

  /// Sign in with email and password.
  ///
  /// Throws [AuthException] on invalid credentials or unconfirmed email.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail(String email) =>
      _client.auth.resetPasswordForEmail(email);

  // ── Magic Link (Passwordless) ──────────────────────────────────────────────

  /// Send a magic link to the user's email.
  ///
  /// Supabase sends a one-time link. When clicked, the app receives
  /// the session via deep-link (`com.cipherowl.app://login-callback`).
  ///
  /// This only authenticates the **cloud session** — the user still
  /// needs to verify their master password to decrypt the local vault.
  Future<void> sendMagicLink(String email) =>
      _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'com.cipherowl.app://login-callback',
      );

  /// Verify a magic link token received via deep-link callback.
  ///
  /// Call this when the app is opened from a magic link URL.
  Future<AuthResponse> verifyMagicLinkToken({
    required String token,
    OtpType type = OtpType.magiclink,
  }) =>
      _client.auth.verifyOTP(token: token, type: type);

  // ── OAuth ──────────────────────────────────────────────────────────────────

  /// Sign in with Google OAuth.
  ///
  /// On mobile, this opens the system browser and returns via deep-link.
  /// Deep-link scheme must be configured:
  ///   - Android: <data android:scheme="com.cipherowl.app" /> in AndroidManifest
  ///   - iOS:    CFBundleURLSchemes in Info.plist
  ///
  /// Returns true if the user approved, false if cancelled.
  Future<bool> signInWithGoogle() async {
    final result = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.cipherowl.app://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    return result;
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  /// Sign out from the cloud session.
  ///
  /// This does NOT clear the local encrypted database or master password.
  Future<void> signOut() => _client.auth.signOut();

  // ── Profile ────────────────────────────────────────────────────────────────

  /// Update the display name in the profiles table.
  Future<void> updateDisplayName(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('profiles')
        .update({'display_name': name, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', user.id);
  }

  /// Fetch the current user profile row.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final rows = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, created_at')
        .eq('id', user.id)
        .maybeSingle();
    return rows;
  }
}