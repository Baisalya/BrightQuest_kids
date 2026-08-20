#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found in PATH. Install Flutter and run this script again." >&2
  exit 1
fi

# Generate only missing Android/Windows runner files. Existing BrightQuest source
# and tests are preserved.
flutter create . --platforms=android,windows

# Keep audioplayers compatible with newer Visual Studio/CMake policy requirements.
if [[ -f windows/CMakeLists.txt ]]; then
  sed -i 's/cmake_minimum_required(VERSION 3.14)/cmake_minimum_required(VERSION 3.15)/' windows/CMakeLists.txt
  sed -i 's/cmake_policy(VERSION 3.14...3.25)/cmake_policy(VERSION 3.15...3.25)/' windows/CMakeLists.txt
fi

# Android 11+ package visibility: make installed TTS engines discoverable.
android_manifest="android/app/src/main/AndroidManifest.xml"
if [[ -f "$android_manifest" ]] && ! grep -q 'android.intent.action.TTS_SERVICE' "$android_manifest"; then
  awk '
    BEGIN { inserted = 0 }
    {
      print
      if (!inserted && $0 ~ /<manifest[^>]*>/) {
        print "    <queries>"
        print "        <intent>"
        print "            <action android:name=\"android.intent.action.TTS_SERVICE\" />"
        print "        </intent>"
        print "    </queries>"
        print ""
        inserted = 1
      }
    }
  ' "$android_manifest" > "$android_manifest.tmp"
  mv "$android_manifest.tmp" "$android_manifest"
fi

# Remove only the stale stock Flutter counter test if an older bootstrap created it.
if [[ -f test/widget_test.dart ]] && grep -Eq 'pumpWidget[[:space:]]*\([[:space:]]*const[[:space:]]+MyApp[[:space:]]*\(' test/widget_test.dart; then
  echo "Removing stale generated MyApp widget test..."
  rm -f test/widget_test.dart
fi

flutter pub upgrade --unlock-transitive audioplayers
flutter pub get
flutter analyze
flutter test

echo "Bootstrap + QA completed."
echo "Android: flutter run"
echo "Windows: flutter run -d windows"
