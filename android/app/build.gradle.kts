import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load signing credentials from key.properties (not committed to git)
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.cipherowl.cipherowl"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.cipherowl.cipherowl"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // applicationIdSuffix = ".debug"  // optional if you want separate debug install
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug keys if keystore not present (CI without secrets)
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// ─── Rust (cargo-ndk) build ───────────────────────────────────────────────────
//
// Compiles the native/smartvault_core Rust crate for Android targets.
// Requires: cargo-ndk (`cargo install cargo-ndk`)
//           Android targets: `rustup target add aarch64-linux-android armv7-linux-androideabi`
//
// Skip gracefully if cargo-ndk is not installed (allows dev builds without Rust).
val rustBuild by tasks.registering {
    doLast {
        val ndkVersion = "28.2.13676358"
        val androidHome = System.getenv("ANDROID_HOME")
            ?: "${System.getProperty("user.home")}/AppData/Local/Android/Sdk"
        val ndkHome = "$androidHome/ndk/$ndkVersion"
        // Resolve cargo-ndk — prefer absolute path on Windows so Gradle's
        // subprocess inherits the correct PATH even if .cargo\bin is not in
        // the system-wide PATH (common on Windows developer machines).
        val userHome = System.getProperty("user.home")
        val cargoNdkAbs = if (System.getProperty("os.name").lowercase().contains("windows")) {
            val candidate = file("$userHome/.cargo/bin/cargo-ndk.exe")
            if (candidate.exists()) candidate.absolutePath else "cargo-ndk"
        } else {
            "cargo-ndk"
        }
        val cargoNdk = cargoNdkAbs

        // Check if cargo-ndk is available
        val hasCargoNdk = try {
            ProcessBuilder(cargoNdk, "--version")
                .start().waitFor() == 0
        } catch (_: Exception) { false }

        if (!hasCargoNdk) {
            println("⚠️  cargo-ndk not found — skipping Rust build (run `cargo install cargo-ndk`)")
            return@doLast
        }

        val rustDir = file("../../native/smartvault_core")
        val outDir = file("src/main/jniLibs")
        val profile = if (project.hasProperty("release")) "release" else "debug"

        exec {
            workingDir = rustDir
            environment("ANDROID_NDK_HOME", ndkHome)
            commandLine =
                listOf(
                    cargoNdk,
                    "-t", "arm64-v8a",
                    "-t", "armeabi-v7a",
                    "--output-dir", outDir.absolutePath,
                    "build",
                    if (profile == "release") "--release" else "--"
                ).filter { it != "--" || profile != "release" }
        }
        println("✅ Rust library built → $outDir")
    }
}

// Run Rust build before JNI libs are merged (debug and release)
tasks.whenTaskAdded {
    if (name.startsWith("merge") && name.contains("JniLibFolders")) {
        dependsOn(rustBuild)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // MASVS-STORAGE-1: EncryptedSharedPreferences for the autofill credential cache
    // MasterKey API requires 1.1.0-alpha06+
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
}
