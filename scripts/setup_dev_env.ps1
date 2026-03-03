# Install Flutter SDK
$flutterDir = "C:\src\flutter"
if (-Not (Test-Path $flutterDir)) {
    Write-Host "Cloning Flutter SDK..."
    New-Item -ItemType Directory -Force -Path "C:\src" | Out-Null
    git clone https://github.com/flutter/flutter.git -b stable $flutterDir
}

# Add Flutter to User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notmatch "flutter\\bin") {
    $newUserPath = "$userPath;$flutterDir\bin"
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    $env:Path = "$env:Path;$flutterDir\bin"
    Write-Host "Added Flutter to PATH"
}

# Disable analytics and run doctor
flutter config --no-analytics
flutter doctor

# Install Rust Toolchain
Write-Host "Installing Rust Toolchain..."
Invoke-WebRequest -Uri "https://win.rustup.rs" -OutFile "rustup-init.exe"
.\rustup-init.exe -y --default-toolchain stable
Remove-Item ".\rustup-init.exe"

# Add Rust to Data Path
$cargoEnvPath = "$env:USERPROFILE\.cargo\bin"
if ($userPath -notmatch "\.cargo\\bin") {
    $newUserPath = [Environment]::GetEnvironmentVariable("Path", "User") + ";$cargoEnvPath"
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    $env:Path = "$env:Path;$cargoEnvPath"
    Write-Host "Added Cargo to PATH"
}

# Add targets for cross-compilation
rustup target add aarch64-linux-android armv7-linux-androideabi aarch64-apple-ios x86_64-apple-ios

Write-Host "✅ Dev Environment Setup Complete!"
