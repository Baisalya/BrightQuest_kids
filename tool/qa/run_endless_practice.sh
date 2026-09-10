#!/usr/bin/env bash
set -euo pipefail

gate() {
  printf '\n== %s ==\n' "$1"
  shift
  "$@"
}

gate 'Static analysis' flutter analyze
gate 'Endless Practice focused tests' flutter test test/endless_practice_phase_test.dart
gate 'Step 9 production regression' flutter test test/mission_run_step9_production_release_gate_test.dart
gate 'Step 8 balance/content regression' flutter test test/mission_run_step8_balance_quality_test.dart
gate 'Step 8 128-seed scale audit' flutter test test/mission_step8_balance_quality_audit_test.dart --dart-define=STEP8_SEEDS=128 --reporter=expanded
gate 'Full BrightQuest regression suite' flutter test

printf '\nENDLESS PRACTICE RELEASE GATE: PASS\n'
printf 'Manual Android and Windows device checks still remain required before shipping.\n'
