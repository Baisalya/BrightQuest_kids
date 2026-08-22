#!/usr/bin/env sh
set -eu

echo '=== BrightQuest Phase A: content contracts ==='
dart run tool/qa/validate_content_contracts.dart

echo '=== BrightQuest Phase A: Nursery letters / phonics simulation ==='
dart run tool/qa/simulate_nursery_letters.dart --seeds 256

echo '=== BrightQuest Phase A: Nursery numbers / early math simulation ==='
dart run tool/qa/simulate_nursery_numbers.dart --seeds 256

echo '=== BrightQuest Phase A: whole-app teaching correctness audit ==='
dart run tool/qa/phase_a_teaching_audit.dart --seeds 128

echo '=== BrightQuest Phase A: regression tests ==='
flutter test test/phase_a_teaching_correctness_audit_test.dart test/phase_a_feedback_alignment_test.dart

echo '=== Phase A completed successfully ==='
