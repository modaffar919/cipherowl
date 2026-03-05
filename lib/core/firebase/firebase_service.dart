import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initialises Firebase once at app startup.
///
/// Call [FirebaseService.init] inside main() before [runApp].
/// A placeholder [FirebaseOptions] is provided so the project compiles
/// without a real google-services.json / GoogleService-Info.plist.
/// Replace [_placeholderOptions] values with your actual Firebase project
/// settings (or use flutterfire CLI: `flutterfire configure`).
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: _placeholderOptions,
      );
      _initialized = true;
    } catch (e) {
      // Firebase is optional — app continues without it.
      debugPrint('[FirebaseService] Init skipped: $e');
    }
  }

  /// Replace with actual values from your Firebase Console or via
  /// `flutterfire configure` which auto-generates firebase_options.dart.
  static const FirebaseOptions _placeholderOptions = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'cipherowl-app',
    storageBucket: 'cipherowl-app.appspot.com',
  );
}
