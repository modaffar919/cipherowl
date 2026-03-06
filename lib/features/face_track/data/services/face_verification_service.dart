import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cipherowl/core/crypto/vault_crypto_service.dart';
import 'package:cipherowl/src/rust/api.dart';

/// Manages enrolled face embeddings and verifies identity via Rust FFI.
///
/// Enrolled embedding is the L2-normalised average of 5 captures (one per pose).
/// Verification uses cosine similarity threshold of **0.6** as specified in EPIC-6.
///
/// Embeddings are encrypted with AES-256-GCM via [VaultCryptoService] before
/// storage, ensuring zero-plaintext at rest even if SecureStorage is compromised.
///
/// Storage: AES-256-GCM ciphertext in `FlutterSecureStorage`.
class FaceVerificationService {
  static const _enrollmentKey = 'face_enrolled_embedding_v1';

  /// Cosine similarity threshold for same-person decision (EPIC-6 spec: 0.6).
  static const double verificationThreshold = 0.6;

  final FlutterSecureStorage _storage;
  final VaultCryptoService _crypto;

  FaceVerificationService({
    FlutterSecureStorage? storage,
    VaultCryptoService? crypto,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _crypto = crypto ?? VaultCryptoService();

  // ── Enrollment ────────────────────────────────────────────────────────────

  /// Whether a face has been enrolled on this device.
  Future<bool> hasEnrolledFace() async {
    final raw = await _storage.read(key: _enrollmentKey);
    return raw != null;
  }

  /// Enrolls the user by averaging [captures] and storing the L2-normalised result.
  ///
  /// [captures] must contain 5 non-empty 128-dim embeddings (one per pose).
  /// The embedding is encrypted with AES-256-GCM before storage.
  Future<void> enroll(List<List<double>> captures) async {
    assert(captures.isNotEmpty, 'Need at least one capture to enroll');
    assert(
      captures.every((e) => e.length == 128),
      'Each embedding must be 128-dimensional',
    );

    final averaged = _averageEmbeddings(captures);
    final normalized = apiFaceNormalizeEmbedding(embeddingVec: averaged);
    await _storeEncrypted(normalized.toList());
  }

  /// Re-enrolls from a pre-computed normalised embedding (e.g. restored from backup).
  /// The embedding is encrypted with AES-256-GCM before storage.
  Future<void> enrollFromEmbedding(Float32List embedding) async {
    await _storeEncrypted(embedding.toList());
  }

  /// Removes the enrolled face from secure storage.
  Future<void> clearEnrolledFace() async {
    await _storage.delete(key: _enrollmentKey);
  }

  // ── Verification ──────────────────────────────────────────────────────────

  /// Compares [probe] against the enrolled embedding.
  ///
  /// Returns `false` if no face is enrolled.
  /// Uses [verificationThreshold] = 0.6 (Rust apiFaceIsSamePerson).
  Future<bool> verify(List<double> probe) async {
    final enrolled = await _loadEnrolled();
    if (enrolled == null) return false;

    final normalizedProbe = apiFaceNormalizeEmbedding(embeddingVec: probe);
    return apiFaceIsSamePerson(
      a: enrolled,
      b: normalizedProbe.toList(),
      threshold: verificationThreshold,
    );
  }

  /// Returns the raw cosine similarity score between [probe] and the enrolled face.
  ///
  /// Returns `null` if no face is enrolled.
  Future<double?> similarityScore(List<double> probe) async {
    final enrolled = await _loadEnrolled();
    if (enrolled == null) return null;

    final normalizedProbe = apiFaceNormalizeEmbedding(embeddingVec: probe);
    return apiFaceCosineSimilarity(a: enrolled, b: normalizedProbe.toList());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<double>?> _loadEnrolled() async {
    final raw = await _storage.read(key: _enrollmentKey);
    if (raw == null) return null;

    // Attempt AES-256-GCM decryption; fall back to legacy plain JSON.
    try {
      final ciphertext = base64Decode(raw);
      final plainBytes = await _crypto.decryptBytes(Uint8List.fromList(ciphertext));
      return List<double>.from(jsonDecode(utf8.decode(plainBytes)) as List);
    } catch (_) {
      // Legacy unencrypted format — migrate on next enroll.
      return List<double>.from(jsonDecode(raw) as List);
    }
  }

  /// Encrypts [embedding] via AES-256-GCM and stores the base64 ciphertext.
  Future<void> _storeEncrypted(List<double> embedding) async {
    final jsonBytes = utf8.encode(jsonEncode(embedding));
    final ciphertext = await _crypto.encryptBytes(jsonBytes);
    await _storage.write(
      key: _enrollmentKey,
      value: base64Encode(ciphertext),
    );
  }

  List<double> _averageEmbeddings(List<List<double>> embeddings) {
    const dim = 128;
    final result = List.filled(dim, 0.0);
    for (final emb in embeddings) {
      for (int i = 0; i < dim; i++) {
        result[i] += emb[i] / embeddings.length;
      }
    }
    return result;
  }
}
