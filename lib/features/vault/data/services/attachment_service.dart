import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:cipherowl/core/crypto/vault_crypto_service.dart';
import 'package:cipherowl/core/database/smartvault_database.dart';

/// Maximum attachment file size: 10 MB.
const int kMaxAttachmentBytes = 10 * 1024 * 1024;

/// Manages encrypted file attachments for vault items.
///
/// Files are encrypted with AES-256-GCM via [VaultCryptoService] and stored
/// in a local `encrypted_attachments/` subfolder. Metadata (filename, size,
/// MIME type) is tracked in the [VaultAttachments] Drift table.
class AttachmentService {
  final VaultDao _dao;
  final VaultCryptoService _crypto;
  static const _uuid = Uuid();

  AttachmentService({
    required VaultDao dao,
    required VaultCryptoService crypto,
  })  : _dao = dao,
        _crypto = crypto;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Pick a file via system dialog, encrypt, and attach to [itemId].
  ///
  /// Returns the created [VaultAttachment] or `null` if the
  /// user cancelled the picker.
  Future<VaultAttachment?> pickAndAttach(String itemId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;

    if (file.bytes == null || file.bytes!.isEmpty) return null;
    if (file.bytes!.length > kMaxAttachmentBytes) {
      throw AttachmentTooLargeException(file.bytes!.length);
    }

    return addAttachment(
      itemId: itemId,
      fileName: file.name,
      mimeType: _guessMime(file.name),
      bytes: file.bytes!,
    );
  }

  /// Encrypt [bytes] and store as an attachment for [itemId].
  Future<VaultAttachment> addAttachment({
    required String itemId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final id = _uuid.v4();
    final encrypted = await _crypto.encryptBytes(bytes);

    // Write encrypted blob to local storage
    final dir = await _attachmentsDir();
    final localPath = p.join(dir.path, '$id.enc');
    await File(localPath).writeAsBytes(encrypted, flush: true);

    final companion = VaultAttachmentsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      fileSize: Value(bytes.length),
      localPath: Value(localPath),
      createdAt: Value(DateTime.now()),
    );

    await _dao.insertAttachment(companion);
    return (await _dao.getAttachments(itemId))
        .firstWhere((a) => a.id == id);
  }

  /// List all attachments for a vault item.
  Future<List<VaultAttachment>> listAttachments(String itemId) =>
      _dao.getAttachments(itemId);

  /// Decrypt and return the raw bytes of an attachment.
  Future<Uint8List> readAttachment(VaultAttachment attachment) async {
    final file = File(attachment.localPath);
    if (!await file.exists()) {
      throw AttachmentNotFoundException(attachment.id);
    }
    final encrypted = await file.readAsBytes();
    return _crypto.decryptBytes(encrypted);
  }

  /// Delete an attachment from both disk and database.
  Future<void> deleteAttachment(String attachmentId) async {
    final dir = await _attachmentsDir();
    final file = File(p.join(dir.path, '$attachmentId.enc'));
    if (await file.exists()) {
      await file.delete();
    }
    await _dao.deleteAttachment(attachmentId);
  }

  /// Delete all attachments for a vault item (used during item deletion).
  Future<void> deleteAllForItem(String itemId) async {
    final attachments = await _dao.getAttachments(itemId);
    for (final att in attachments) {
      final file = File(att.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _dao.deleteAttachmentsForItem(itemId);
  }

  /// Human-readable file size string.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ── Private ─────────────────────────────────────────────────────────────

  Future<Directory> _attachmentsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'encrypted_attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _guessMime(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    const mimeMap = {
      '.pdf': 'application/pdf',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.txt': 'text/plain',
      '.json': 'application/json',
      '.csv': 'text/csv',
      '.doc': 'application/msword',
      '.docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.zip': 'application/zip',
    };
    return mimeMap[ext] ?? 'application/octet-stream';
  }
}

/// Thrown when an attachment exceeds [kMaxAttachmentBytes].
class AttachmentTooLargeException implements Exception {
  final int actualBytes;
  AttachmentTooLargeException(this.actualBytes);

  @override
  String toString() =>
      'Attachment too large: ${AttachmentService.formatFileSize(actualBytes)} '
      '(max ${AttachmentService.formatFileSize(kMaxAttachmentBytes)})';
}

/// Thrown when the encrypted file for an attachment is missing from disk.
class AttachmentNotFoundException implements Exception {
  final String attachmentId;
  AttachmentNotFoundException(this.attachmentId);

  @override
  String toString() => 'Attachment file not found: $attachmentId';
}
