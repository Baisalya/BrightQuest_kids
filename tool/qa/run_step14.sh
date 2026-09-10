#!/usr/bin/env bash
set -euo pipefail

run_gate() {
  local label="$1"
  shift
  printf '\n== %s ==\n' "$label"
  "$@"
}

run_gate "Static analysis" flutter analyze
run_gate "Step 14 logical unlimited practice tests" flutter test test/step14_logical_unlimited_practice_test.dart test/step14_logical_unlimited_practice_ui_test.dart
run_gate "Step 13 adaptive non-repeat regression" flutter test test/step13_adaptive_non_repeat_engine_test.dart
run_gate "Skill Studio UI regression" flutter test test/phase_e_skill_studio_ui_test.dart
run_gate "Endless Practice regression" flutter test test/endless_practice_phase_test.dart
run_gate "Step 9 production regression" flutter test test/mission_run_step9_production_release_gate_test.dart
run_gate "Step 8 focused balance/content regression" flutter test test/mission_run_step8_balance_quality_test.dart
run_gate "Step 8 128-seed scale audit" flutter test test/mission_step8_balance_quality_audit_test.dart --dart-define=STEP8_SEEDS=128 --reporter=expanded
run_gate "Full BrightQuest regression suite" flutter test

printf '\nSTEP 14 LOGICAL UNLIMITED PRACTICE RELEASE GATE: PASS\n'
printf 'Manual Android and Windows device checks still remain required before shipping.\n'
