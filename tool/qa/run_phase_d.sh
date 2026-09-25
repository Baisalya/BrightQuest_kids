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

echo '=== Phase D non-Windows automated gate completed ==='
echo 'QA only: no Android AAB, Windows build, or MSIX was generated. Use a separate packaging command for artifacts.'
