/// Stub for native platforms — WebCryptoStorage is only used on web.
///
/// This file is imported on non-web targets via conditional import.
class WebCryptoStorage {
  Future<void> init() async {}
  Future<String?> read(String key) async => null;
  Future<void> write(String key, String value) async {}
  Future<void> delete(String key) async {}
  Future<Map<String, String>> readAll() async => {};
  Future<void> deleteAll() async {}
  Future<bool> containsKey(String key) async => false;
}
