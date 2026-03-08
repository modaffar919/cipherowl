import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Firebase configuration for CipherOwl.
///
/// To regenerate, run: `flutterfire configure`
/// Or replace the values below with your Firebase Console credentials.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android; // fallback
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TODO: Replace with real values from Firebase Console → Project Settings
  // ──────────────────────────────────────────────────────────────────────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'cipherowl-app',
    storageBucket: 'cipherowl-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'cipherowl-app',
    storageBucket: 'cipherowl-app.firebasestorage.app',
    iosBundleId: 'com.cipherowl.cipherowl',
  );
}
