#!/usr/bin/env pwsh
# Build smartvault_core Rust library for Android
# Usage: ./scripts/build_rust_android.ps1 [--release]
#
# Requires:
#   - Rust toolchain + Android targets:
#     rustup target add aarch64-linux-android armv7-linux-androideabi
#   - cargo-ndk: cargo install cargo-ndk
#   - Android NDK (any version ≥ 25)

param(
    [switch]$Release,
    [string]$NdkVersion = "28.2.13676358"
)

$ErrorActionPreference = "Stop"

$AndroidHome = $env:ANDROID_HOME ?? "$env:LOCALAPPDATA\Android\Sdk"
$NdkHome = "$AndroidHome\ndk\$NdkVersion"
$RustDir = Join-Path $PSScriptRoot "..\native\smartvault_core"
$OutDir = Join-Path $PSScriptRoot "..\android\app\src\main\jniLibs"

Write-Host "🦀 Building SmartVault Core (Rust) for Android..."
Write-Host "   NDK: $NdkHome"
Write-Host "   Targets: arm64-v8a, armeabi-v7a"
Write-Host "   Profile: $(if ($Release) { 'release' } else { 'debug' })"

# Verify cargo-ndk is installed
if (-not (Get-Command cargo-ndk -ErrorAction SilentlyContinue)) {
    Write-Error "cargo-ndk not found. Install with: cargo install cargo-ndk"
}

# Verify NDK exists
if (-not (Test-Path $NdkHome)) {
    Write-Error "NDK not found at: $NdkHome. Install NDK $NdkVersion via Android Studio."
}

# Verify Android targets are installed
$targets = rustup target list --installed 2>&1
if (-not ($targets -match "aarch64-linux-android")) {
    Write-Host "Adding aarch64-linux-android target..."
    rustup target add aarch64-linux-android
}
if (-not ($targets -match "armv7-linux-androideabi")) {
    Write-Host "Adding armv7-linux-androideabi target..."
    rustup target add armv7-linux-androideabi
}

# Build
Push-Location $RustDir
try {
    $env:ANDROID_NDK_HOME = $NdkHome

    $buildArgs = @(
        "ndk",
        "-t", "arm64-v8a",
        "-t", "armeabi-v7a",
        "--output-dir", $OutDir,
        "build"
    )
    if ($Release) { $buildArgs += "--release" }

    Write-Host "Running: cargo $($buildArgs -join ' ')"
    cargo @buildArgs

    Write-Host ""
    Write-Host "✅ Build complete! Output:"
    Get-ChildItem $OutDir -Recurse -Filter "*.so" | ForEach-Object {
        Write-Host "   $($_.FullName.Replace((Resolve-Path "$PSScriptRoot\..").Path, ''))"
    }
} finally {
    Pop-Location
}
