#!/usr/bin/env bash
set -euo pipefail

echo '=== BrightQuest Phase B: formatting gate ==='
dart format --output=none --set-exit-if-changed lib test tool

echo '=== BrightQuest Phase B: verified Phase A baseline ==='
bash tool/qa/run_phase_a.sh

echo '=== BrightQuest Phase B: focused letters / sounds audit ==='
dart run tool/qa/simulate_nursery_phonics_phase_b.dart

echo '=== BrightQuest Phase B: Nursery content validator ==='
dart run tool/content/validate_nursery_content.dart

echo '=== BrightQuest Phase B: release-safety validator ==='
dart run tool/release/readiness_report.dart

echo '=== BrightQuest Phase B: focused unit and widget regressions ==='
flutter test test/phase_b_phonics_correctness_test.dart test/phase_b_alphabet_ui_test.dart test/phase_a_feedback_alignment_test.dart

echo '=== BrightQuest Phase B: complete Flutter regression suite ==='
flutter test

echo '=== BrightQuest Phase B: static analysis ==='
flutter analyze

echo '=== Phase B completed successfully ==='
