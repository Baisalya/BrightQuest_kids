#!/usr/bin/env bash
set -euo pipefail

run_gate() {
  local label="$1"
  shift
  printf '\n== %s ==\n' "$label"
  "$@"
}

run_gate "Static analysis" flutter analyze
run_gate "Step 9 production release tests" flutter test test/mission_run_step9_production_release_gate_test.dart --reporter=expanded
run_gate "Crash/resume/reward recovery regression" flutter test test/game_session_resume_safety_test.dart
run_gate "Step 8 focused balance/content regression" flutter test test/mission_run_step8_balance_quality_test.dart
run_gate "Step 8 128-seed scale audit" flutter test test/mission_step8_balance_quality_audit_test.dart --dart-define=STEP8_SEEDS=128 --reporter=expanded
run_gate "Full BrightQuest regression suite" flutter test

printf '\nAUTOMATED STEP 9 RELEASE GATE: PASS\n'
printf '%s\n' 'Manual Android and Windows device checks in docs/STEP9_MISSION_SYSTEM_RELEASE_GATE.md remain required before shipping.'
