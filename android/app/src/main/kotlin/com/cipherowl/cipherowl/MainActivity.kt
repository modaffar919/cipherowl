package com.cipherowl.cipherowl

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// ─────────────────────────────────────────────────────────────────────────────
//  MainActivity — extends FlutterActivity and handles the autofill MethodChannel.
//
//  The Dart side (autofill_bridge.dart) calls methods on the channel
//  'com.cipherowl/autofill'. This host-side handler:
//    • updateAutofillCache  → persist JSON blob in EncryptedSharedPreferences
//    • clearAutofillCache   → remove the cache
//    • isAutofillServiceEnabled → query Android autofill provider
//    • requestEnableAutofillService → open system autofill settings
//
//  Security:
//    FLAG_SECURE prevents screenshots and screen recording (MASVS-PLATFORM-2).
//    EncryptedSharedPreferences protects the credential cache (MASVS-STORAGE-1).
// ─────────────────────────────────────────────────────────────────────────────
class MainActivity : FlutterActivity() {

    private val autofillChannel = "com.cipherowl/autofill"

    // MASVS-PLATFORM-2: Block screenshots and screen recording for all vault screens.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }

    // Returns an EncryptedSharedPreferences instance backed by the Android Keystore.
    // MASVS-STORAGE-1: credential cache is AES-256-GCM encrypted at rest.
    private fun getSecurePrefs() = EncryptedSharedPreferences.create(
        this,
        CipherOwlAutofillService.PREFS_NAME,
        MasterKey.Builder(this)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            autofillChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "updateAutofillCache" -> {
                    val cache = call.argument<String>("cache")
                    if (cache != null) {
                        getSecurePrefs().edit()
                            .putString(CipherOwlAutofillService.KEY_CACHE, cache)
                            .apply()
                        result.success(null)
                    } else {
                        result.error("INVALID_ARG", "cache argument is null", null)
                    }
                }

                "clearAutofillCache" -> {
                    getSecurePrefs().edit()
                        .remove(CipherOwlAutofillService.KEY_CACHE)
                        .apply()
                    result.success(null)
                }

                "isAutofillServiceEnabled" -> {
                    val enabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val autofillManager =
                            getSystemService(android.view.autofill.AutofillManager::class.java)
                        autofillManager?.hasEnabledAutofillServices() == true
                    } else {
                        false
                    }
                    result.success(enabled)
                }

                "requestEnableAutofillService" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startActivity(Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE).apply {
                            data = android.net.Uri.parse("package:$packageName")
                        })
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}

