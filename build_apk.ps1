$ErrorActionPreference = "Stop"

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$flutterRoot = Join-Path $PSScriptRoot "tools\flutter"
$env:Path = (Join-Path $env:JAVA_HOME "bin") + ";" + (Join-Path $env:ANDROID_HOME "platform-tools") + ";" + (Join-Path $flutterRoot "bin") + ";" + $env:Path

Set-Location -LiteralPath $PSScriptRoot
& (Join-Path $flutterRoot "bin\flutter.bat") config --no-enable-windows-desktop
& (Join-Path $flutterRoot "bin\flutter.bat") build apk --release
