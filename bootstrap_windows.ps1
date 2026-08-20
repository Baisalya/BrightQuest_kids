$ErrorActionPreference = "Stop"

Write-Host "BrightQuest Kids bootstrap" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter SDK was not found in PATH. Install Flutter, reopen the terminal, then run this script again."
}

function Invoke-Flutter {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & flutter @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "flutter $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
  }
}

# Generate only missing Android/Windows runner files. Existing app source and tests
# are preserved. Keeping our own widget_test.dart prevents flutter create from
# introducing the stock MyApp test, which does not apply to BrightQuestApp.
Invoke-Flutter @("create", ".", "--platforms=android,windows")

# Windows audio safety:
# BrightQuest keeps audioplayers 6.7.1 for Android, but overrides only the
# Windows implementation with a local no-op registration shim. The app uses
# its own event-channel-free MCI backend on Windows, avoiding the native
# callback-thread crash seen with audioplayers_windows 4.3.1 + Flutter 3.41.x.
$windowsAudioShim = Join-Path $PSScriptRoot "third_party\audioplayers_windows_stub\pubspec.yaml"
if (-not (Test-Path $windowsAudioShim)) {
  throw "BrightQuest Windows audio shim is missing: $windowsAudioShim"
}

$shimHeader = Join-Path $PSScriptRoot "third_party\audioplayers_windows_stub\windows\include\audioplayers_windows\audioplayers_windows_plugin.h"
if (-not (Test-Path $shimHeader)) {
  throw "BrightQuest Windows audio shim public header is missing: $shimHeader"
}

$androidTtsFork = Join-Path $PSScriptRoot "third_party\flutter_tts_android\pubspec.yaml"
if (-not (Test-Path $androidTtsFork)) {
  throw "BrightQuest Android-only TTS fork is missing: $androidTtsFork"
}

# Remove stale native plugin products/registrants from previous runs before
# resolving the local Windows shim.
Invoke-Flutter @("clean")

# Android 11+ limits package visibility. flutter_tts recommends declaring the
# system TTS service query so installed speech engines can be discovered.
$androidManifest = Join-Path $PSScriptRoot "android\app\src\main\AndroidManifest.xml"
if (Test-Path $androidManifest) {
  $manifest = Get-Content $androidManifest -Raw
  if ($manifest -notmatch 'android\.intent\.action\.TTS_SERVICE') {
    $ttsQuery = @"
    <queries>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
    </queries>

"@
    $manifest = $manifest -replace '(?s)(<manifest[^>]*>\s*)', ('$1' + $ttsQuery)
    Set-Content -Path $androidManifest -Value $manifest -NoNewline
  }
}

# Defensive cleanup for projects previously bootstrapped with the stock Flutter
# counter test. Never remove a project-owned test unless it still references MyApp.
$generatedWidgetTest = Join-Path $PSScriptRoot "test\widget_test.dart"
if (Test-Path $generatedWidgetTest) {
  $widgetTestContents = Get-Content $generatedWidgetTest -Raw
  if ($widgetTestContents -match "pumpWidget\s*\(\s*const\s+MyApp\s*\(") {
    Write-Host "Removing stale generated MyApp widget test..." -ForegroundColor Yellow
    Remove-Item $generatedWidgetTest -Force
  }
}

# Flutter 3.41.x cannot resolve audioplayers 6.8.x. Keep 6.7.1 for the
# Android implementation; dependency_overrides redirects only the Windows
# implementation to BrightQuest's local event-channel-free shim.
Invoke-Flutter @("pub", "get")

$lockFile = Join-Path $PSScriptRoot "pubspec.lock"
if (-not (Test-Path $lockFile)) {
  throw "pubspec.lock was not created after flutter pub get."
}

$lock = Get-Content $lockFile -Raw
if ($lock -notmatch '(?ms)^  audioplayers:\s+.*?^    version: "6\.7\.1"') {
  throw "BrightQuest v0.4.16 requires audioplayers 6.7.1 for Flutter 3.41.x compatibility."
}
if ($lock -notmatch '(?ms)^  audioplayers_windows:\s+.*?^    source: path\s+.*?^    version: "4\.3\.1\+brightquest\.2"') {
  throw "Windows audio safety shim did not resolve. Expected local audioplayers_windows 4.3.1+brightquest.2."
}
if ($lock -notmatch '(?ms)^  flutter_tts:\s+.*?^    source: path\s+.*?^    version: "4\.2\.5\+brightquest\.1"') {
  throw "Android-only TTS fork did not resolve. Expected local flutter_tts 4.2.5+brightquest.1."
}

$pluginsMetadata = Join-Path $PSScriptRoot ".flutter-plugins-dependencies"
if (Test-Path $pluginsMetadata) {
  $plugins = Get-Content $pluginsMetadata -Raw
  if ($plugins -notmatch 'audioplayers_windows_stub') {
    throw "Flutter plugin metadata does not point to the BrightQuest Windows audio shim."
  }
  $pluginData = $plugins | ConvertFrom-Json
  $windowsPluginNames = @($pluginData.plugins.windows | ForEach-Object { $_.name })
  $androidPluginNames = @($pluginData.plugins.android | ForEach-Object { $_.name })
  if ($windowsPluginNames -contains 'flutter_tts') {
    throw "Unsafe flutter_tts Windows plugin is still registered."
  }
  if ($androidPluginNames -notcontains 'flutter_tts') {
    throw "Android flutter_tts plugin was not registered."
  }
}

Invoke-Flutter @("analyze")
Invoke-Flutter @("test")

Write-Host "Bootstrap + QA completed successfully." -ForegroundColor Green
Write-Host "Android: flutter run"
Write-Host "Windows: flutter run -d windows"
