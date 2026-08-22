#!/usr/bin/env bash
set -euo pipefail

echo '=== BrightQuest Phase D: formatting gate ==='
dart format --output=none --set-exit-if-changed lib test tool

echo '=== BrightQuest Phase D: verified Phase C baseline ==='
"$(dirname "$0")/run_phase_c.sh"

echo '=== BrightQuest Phase D: release-candidate static audit ==='
dart run tool/qa/phase_d_release_candidate_audit.dart

echo '=== BrightQuest Phase D: content contracts ==='
dart run tool/content/validate_content.dart
dart run tool/content/validate_nursery_content.dart

echo '=== BrightQuest Phase D: release-safety contract ==='
dart run tool/release/readiness_report.dart

echo '=== BrightQuest Phase D: accessibility/localization/performance regressions ==='
flutter test test/phase_d_release_candidate_test.dart test/phase_d_accessibility_polish_test.dart

echo '=== BrightQuest Phase D: final complete Flutter regression sweep ==='
flutter test

echo '=== BrightQuest Phase D: final static analysis ==='
flutter analyze

echo '=== BrightQuest Phase D: Android release candidate AAB ==='
flutter build appbundle --release

echo '=== Phase D non-Windows automated gate completed ==='
echo 'Run tool/qa/run_phase_d.ps1 on Windows to build the safe Windows release candidate and close the automated Phase D gate.'
