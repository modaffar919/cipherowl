# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Rust FFI (flutter_rust_bridge native library)
-keep class com.cipherowl.** { *; }

# Supabase / OkHttp / Retrofit
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.squareup.okhttp3.** { *; }

# ML Kit (Face detection)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-dontwarn com.google.mlkit.**

# SQLCipher
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }

# CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
