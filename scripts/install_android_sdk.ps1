$ErrorActionPreference = "Stop"
$java17   = "C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot"
$sdk      = "$env:LOCALAPPDATA\Android\Sdk"
$sdkman   = "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
$env:JAVA_HOME    = $java17
$env:ANDROID_HOME = $sdk
$env:PATH = "$java17\bin;$env:PATH"

Write-Host "[1/3] Installing platform-tools..."
$yes = "y`ny`ny`ny`ny`n"
cmd /c "echo $yes | `"$sdkman`" `"--sdk_root=$sdk`" `"platform-tools`"" 2>&1

Write-Host "[2/3] Installing platforms;android-35..."
cmd /c "echo $yes | `"$sdkman`" `"--sdk_root=$sdk`" `"platforms;android-35`"" 2>&1

Write-Host "[3/3] Installing build-tools;35.0.0..."
cmd /c "echo $yes | `"$sdkman`" `"--sdk_root=$sdk`" `"build-tools;35.0.0`"" 2>&1

Write-Host "DONE. Configuring flutter..."
& "C:\src\flutter\bin\flutter.bat" config --android-sdk $sdk
& "C:\src\flutter\bin\flutter.bat" doctor 2>&1 | Select-String "Android|√|X"
Write-Host "INSTALL_COMPLETE"
