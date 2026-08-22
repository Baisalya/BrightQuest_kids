#!/usr/bin/env bash
set -euo pipefail

echo '=== BrightQuest Phase C: formatting gate ==='
dart format --output=none --set-exit-if-changed lib test tool

echo '=== BrightQuest Phase C: verified Phase B baseline ==='
bash tool/qa/run_phase_b.sh

echo '=== BrightQuest Phase C: Math + My World audit ==='
dart run tool/qa/simulate_nursery_math_world_phase_c.dart

echo '=== BrightQuest Phase C: Nursery content validator ==='
dart run tool/content/validate_nursery_content.dart

echo '=== BrightQuest Phase C: release-safety validator ==='
dart run tool/release/readiness_report.dart

echo '=== BrightQuest Phase C: Count / Quiz integration regressions ==='
flutter test test/phase_c_math_world_correctness_test.dart test/phase_c_count_quiz_integration_test.dart

echo '=== BrightQuest Phase C: complete Flutter regression suite ==='
flutter test

echo '=== BrightQuest Phase C: static analysis ==='
flutter analyze

echo '=== Phase C completed successfully ==='
