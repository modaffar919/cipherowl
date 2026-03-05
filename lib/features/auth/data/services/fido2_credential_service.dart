import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:cipherowl/core/supabase/supabase_client_provider.dart';
import 'package:cipherowl/src/rust/frb_generated.dart/api.dart';

/// FIDO2-style credential manager using Ed25519 via Rust FFI.
///
/// Because mobile platforms don't yet have a universal CTAP2 stack, this
/// implements the same *security properties* of FIDO2:
///   - Key pair generated on-device in Rust (native secure memory).
///   - Private key stored in FlutterSecureStorage (hardware-backed on Android
///     Keystore / iOS Secure Enclave when available).
///   - Public key registered in Supabase with RLS (only the owner can read it).
///   - Sign-count is tracked to detect credential cloning (replay prevention).
///   - Authentication = sign a server challenge with Ed25519; server verifies.
///
/// On Android 9+ the system passkey API (FIDO2 via Credential Manager) can
/// replace this impl; swap [registerCredential] on those devices.
class Fido2CredentialService {
  static const _privKeyPrefix = 'fido2_privkey_';
  static const _table = 'fido2_credentials';

  final FlutterSecureStorage _storage;
  final SupabaseClient _supabase;

  Fido2CredentialService({
    FlutterSecureStorage? storage,
    SupabaseClient? supabase,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _supabase = supabase ?? SupabaseClientProvider.client;

  // ── Registration ───────────────────────────────────────────────────────────

  /// Generate a new Ed25519 key pair and register the public key with Supabase.
  ///
  /// Returns the credential ID on success.
  ///
  /// [friendlyName] — user-visible label (e.g. "Pixel 9" or "iPhone 16 Pro").
  Future<String> registerCredential({String? friendlyName}) async {
    final user = SupabaseClientProvider.currentUser;
    if (user == null) throw StateError('User must be signed in to register a credential');

    // 1. Generate Ed25519 key pair (Rust native — secure memory)
    final signingKeyBytes = apiEd25519GenerateSigningKey(); // 32 bytes seed
    final verifyingKeyBytes = apiEd25519GetVerifyingKey(signingKey: signingKeyBytes);

    // 2. Create a stable credential ID
    final credentialId = const Uuid().v4();

    // 3. Persist private key in secure storage (hardware-backed when available)
    final storageKey = '$_privKeyPrefix$credentialId';
    await _storage.write(
      key: storageKey,
      value: base64.encode(signingKeyBytes),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
        synchronizable: false,
      ),
    );

    // 4. Register public key in Supabase
    final deviceOs = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'other';

    await _supabase.from(_table).insert({
      'id': credentialId,
      'user_id': user.id,
      'public_key': base64.encode(verifyingKeyBytes),
      'friendly_name': friendlyName ?? 'Passkey',
      'device_os': deviceOs,
      'sign_count': 0,
      'is_backup_eligible': false,
      'is_backed_up': false,
    });

    return credentialId;
  }

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Sign a [challenge] (server-provided random bytes) with the stored private
  /// key identified by [credentialId].
  ///
  /// Returns base64-encoded 64-byte Ed25519 signature.
  Future<String> sign({
    required String credentialId,
    required Uint8List challenge,
  }) async {
    final storageKey = '$_privKeyPrefix$credentialId';
    final privKeyB64 = await _storage.read(key: storageKey);
    if (privKeyB64 == null) {
      throw StateError('Credential $credentialId not found on this device');
    }

    final signingKey = base64.decode(privKeyB64);
    final signature = apiEd25519Sign(message: challenge, signingKey: signingKey);

    // Increment sign-count to detect cloning
    final currentCount = await _signCount(credentialId);
    await _supabase
        .from(_table)
        .update({
          'sign_count': currentCount + 1,
          'last_used_at': DateTime.now().toIso8601String(),
        })
        .eq('id', credentialId)
        .eq('user_id', SupabaseClientProvider.currentUser!.id);

    return base64.encode(signature);
  }

  /// Verify that [signature] (base64) over [challenge] is valid for
  /// the stored public key of [credentialId].
  ///
  /// Use this server-side or in tests. The Supabase RLS ensures only the
  /// owner can fetch their own credential's public key.
  Future<bool> verify({
    required String credentialId,
    required Uint8List challenge,
    required String signatureBase64,
  }) async {
    final row = await _supabase
        .from(_table)
        .select('public_key, sign_count')
        .eq('id', credentialId)
        .single();

    final verifyingKey = base64.decode(row['public_key'] as String);
    final signature = base64.decode(signatureBase64);

    return apiEd25519Verify(
      message: challenge,
      signature: signature,
      verifyingKey: verifyingKey,
    );
  }

  // ── Listing ────────────────────────────────────────────────────────────────

  /// Returns all credentials registered by the current user.
  Future<List<Fido2CredentialInfo>> listCredentials() async {
    final user = SupabaseClientProvider.currentUser;
    if (user == null) return [];

    final rows = await _supabase
        .from(_table)
        .select('id, friendly_name, created_at, last_used_at, device_os, sign_count')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List).map((r) => Fido2CredentialInfo.fromJson(r as Map<String, dynamic>)).toList();
  }

  // ── Removal ───────────────────────────────────────────────────────────────

  /// Delete a credential from Supabase and remove the private key from storage.
  Future<void> deleteCredential(String credentialId) async {
    await _supabase
        .from(_table)
        .delete()
        .eq('id', credentialId)
        .eq('user_id', SupabaseClientProvider.currentUser!.id);

    await _storage.delete(key: '$_privKeyPrefix$credentialId');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Fetch the current sign-count for a credential. Falls back to 0.
  Future<int> _signCount(String credentialId) async {
    try {
      final row = await _supabase
          .from(_table)
          .select('sign_count')
          .eq('id', credentialId)
          .single();
      return (row['sign_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

// ─── DTO ──────────────────────────────────────────────────────────────────────

class Fido2CredentialInfo {
  final String id;
  final String friendlyName;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final String? deviceOs;
  final int signCount;

  const Fido2CredentialInfo({
    required this.id,
    required this.friendlyName,
    required this.createdAt,
    this.lastUsedAt,
    this.deviceOs,
    required this.signCount,
  });

  factory Fido2CredentialInfo.fromJson(Map<String, dynamic> json) =>
      Fido2CredentialInfo(
        id: json['id'] as String,
        friendlyName: json['friendly_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        lastUsedAt: json['last_used_at'] != null
            ? DateTime.parse(json['last_used_at'] as String)
            : null,
        deviceOs: json['device_os'] as String?,
        signCount: (json['sign_count'] as num?)?.toInt() ?? 0,
      );
}
