import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cipherowl/core/supabase/supabase_client_provider.dart';
import 'package:cipherowl/src/rust/api.dart' as rust;

/// Zero-knowledge secure sharing service.
///
/// Flow:
/// 1. Generate random AES-256 key (Rust)
/// 2. Encrypt item JSON with this key (Rust AES-GCM)
/// 3. POST encrypted blob to Supabase Edge Function
/// 4. Build link with key in URL fragment (never sent to server)
///
/// Retrieval:
/// 1. GET encrypted blob from Edge Function by share ID
/// 2. Decrypt with key from URL fragment (Rust AES-GCM)
class SharingService {
  final SupabaseClient _client;

  SharingService({SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  /// Create a new encrypted share and return the full sharing URL.
  ///
  /// [itemJson] — the vault item data to share (plaintext JSON string).
  /// Returns the full URL including the decryption key in the fragment.
  Future<ShareResult> createShare({
    required String itemJson,
    required String recipientEmail,
    required int expiryHours,
    bool isOneTime = true,
    bool requirePin = false,
    String? pin,
  }) async {
    // 1. Generate AES-256 key and encrypt
    final key = rust.apiGenerateKey(); // 32 bytes
    final plaintext = utf8.encode(itemJson);
    final ciphertext = rust.apiEncrypt(
      plaintext: plaintext,
      key: key.toList(),
    );

    final encryptedBase64 = base64Url.encode(ciphertext);
    final keyBase64 = base64Url.encode(key);

    // 2. If PIN required, hash it (using Rust Argon2id)
    String? pinHash;
    if (requirePin && pin != null && pin.isNotEmpty) {
      pinHash = await rust.apiHashPassword(password: pin);
    }

    // 3. POST to Edge Function
    final response = await _client.functions.invoke(
      'share-item',
      method: HttpMethod.post,
      body: {
        'encrypted_data': encryptedBase64,
        'recipient_email': recipientEmail,
        'expires_in_hours': expiryHours,
        'is_one_time': isOneTime,
        'require_pin': requirePin,
        'pin_hash': pinHash,
      },
    );

    if (response.status != 201) {
      final err = response.data is Map ? response.data['error'] : 'Unknown error';
      throw Exception('Failed to create share: $err');
    }

    final shareId = response.data['id'] as String;
    final expiresAt = response.data['expires_at'] as String;

    // 4. Build URL with key in fragment (never sent to server)
    final url = 'https://cipherowl.app/share/$shareId#key=$keyBase64';

    return ShareResult(
      id: shareId,
      url: url,
      expiresAt: DateTime.parse(expiresAt),
    );
  }

  /// Retrieve and decrypt a shared item from its URL.
  ///
  /// [shareId] — UUID from the URL path.
  /// [keyBase64] — base64url-encoded AES-256 key from the URL fragment.
  Future<String> retrieveShare({
    required String shareId,
    required String keyBase64,
  }) async {
    final response = await _client.functions.invoke(
      'share-item',
      method: HttpMethod.get,
      queryParameters: {'id': shareId},
    );

    if (response.status != 200) {
      final err = response.data is Map ? response.data['error'] : 'Unknown error';
      throw Exception('Failed to retrieve share: $err');
    }

    final encryptedBase64 = response.data['encrypted_data'] as String;
    final ciphertext = base64Url.decode(encryptedBase64);
    final key = base64Url.decode(keyBase64);

    final plaintext = rust.apiDecrypt(
      ciphertextWithNonce: ciphertext.toList(),
      key: key.toList(),
    );

    return utf8.decode(plaintext);
  }

  /// List active shares for the current user.
  Future<List<SharedItemInfo>> listMyShares() async {
    final userId = SupabaseClientProvider.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('shared_items')
        .select('id, recipient_email, expires_at, is_one_time, accessed_at, is_revoked, created_at')
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => SharedItemInfo.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Revoke an active share.
  Future<void> revokeShare(String shareId) async {
    await _client
        .from('shared_items')
        .update({'is_revoked': true})
        .eq('id', shareId);
  }
}

/// Result of creating a new share.
class ShareResult {
  final String id;
  final String url;
  final DateTime expiresAt;

  const ShareResult({
    required this.id,
    required this.url,
    required this.expiresAt,
  });
}

/// Info about an existing shared item.
class SharedItemInfo {
  final String id;
  final String? recipientEmail;
  final DateTime expiresAt;
  final bool isOneTime;
  final DateTime? accessedAt;
  final bool isRevoked;
  final DateTime createdAt;

  SharedItemInfo({
    required this.id,
    this.recipientEmail,
    required this.expiresAt,
    required this.isOneTime,
    this.accessedAt,
    required this.isRevoked,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isExpired && !isRevoked && !(isOneTime && accessedAt != null);

  String get status {
    if (isRevoked) return 'revoked';
    if (isExpired) return 'expired';
    if (isOneTime && accessedAt != null) return 'used';
    return 'active';
  }

  factory SharedItemInfo.fromJson(Map<String, dynamic> json) => SharedItemInfo(
    id: json['id'] as String,
    recipientEmail: json['recipient_email'] as String?,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    isOneTime: json['is_one_time'] as bool? ?? true,
    accessedAt: json['accessed_at'] != null ? DateTime.parse(json['accessed_at'] as String) : null,
    isRevoked: json['is_revoked'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
