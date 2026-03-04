/// A lightweight credential representation safe to pass across the
/// Flutter ↔ Android MethodChannel boundary.
///
/// Contains only plaintext values — never encrypted blobs.
/// Only created after the vault password has been decrypted in the
/// presentation layer.
class AutofillCredential {
  final String id;
  final String title;

  /// Login username or email. Empty string if not applicable.
  final String username;

  /// Plaintext password. Empty string if not yet decrypted or not set.
  final String password;

  /// Associated URL / domain. Empty string if not set.
  final String url;

  const AutofillCredential({
    required this.id,
    required this.title,
    this.username = '',
    this.password = '',
    this.url = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'username': username,
        'password': password,
        'url': url,
      };

  @override
  String toString() =>
      'AutofillCredential(id: $id, title: $title, username: $username, url: $url)';
}
