package com.cipherowl.cipherowl

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// ─────────────────────────────────────────────────────────────────────────────
//  MainActivity — extends FlutterActivity and handles the autofill MethodChannel.
//
//  The Dart side (autofill_bridge.dart) calls methods on the channel
//  'com.cipherowl/autofill'. This host-side handler:
//    • updateAutofillCache  → persist JSON blob in SharedPreferences
//    • clearAutofillCache   → remove the cache
//    • isAutofillServiceEnabled → query Android autofill provider
//    • requestEnableAutofillService → open system autofill settings
// ─────────────────────────────────────────────────────────────────────────────
class MainActivity : FlutterActivity() {

    private val autofillChannel = "com.cipherowl/autofill"

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
                        getSharedPreferences(
                            "cipher_owl_autofill",
                            Context.MODE_PRIVATE,
                        ).edit()
                            .putString("credential_cache", cache)
                            .apply()
                        result.success(null)
                    } else {
                        result.error("INVALID_ARG", "cache argument is null", null)
                    }
                }

                "clearAutofillCache" -> {
                    getSharedPreferences(
                        "cipher_owl_autofill",
                        Context.MODE_PRIVATE,
                    ).edit()
                        .remove("credential_cache")
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

