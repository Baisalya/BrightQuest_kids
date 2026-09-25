#!/usr/bin/env bash
set -euo pipefail

step() {
  printf '\n=== %s ===\n' "$1"
}

step 'Step 12: formatting gate'
dart format --output=none --set-exit-if-changed lib test tool

step 'Step 12: static production-hardening audit'
dart run tool/qa/step12_production_readiness_audit.dart

step 'Step 12: existing release-safety contract'
dart run tool/release/readiness_report.dart

step 'Step 12: content contracts'
dart run tool/content/validate_content.dart
dart run tool/content/validate_nursery_content.dart

step 'Step 12: focused production regressions'
flutter test test/step12_production_hardening_test.dart test/game_session_resume_safety_test.dart test/learning_audio_accessibility_test.dart test/nursery_simple_game_flow_test.dart test/phase_d_release_candidate_test.dart

step 'Step 12: complete regression sweep'
flutter test

step 'Step 12: final static analysis'
flutter analyze

printf '\nStep 12 QA gates completed. No Android AAB, Windows build, or MSIX was generated. External real-device/store/teacher/pilot/privacy qualification remains pending.\n'
