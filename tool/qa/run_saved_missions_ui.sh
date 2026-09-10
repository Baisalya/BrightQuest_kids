#!/usr/bin/env bash
set -euo pipefail

gate() {
  printf '\n== %s ==\n' "$1"
  shift
  "$@"
}

gate 'Static analysis' flutter analyze
gate 'Saved mission responsive UI tests' flutter test test/saved_missions_responsive_ui_test.dart
gate 'Cosmetic ownership, equip and responsive UI regression' flutter test test/cosmetic_equipment_ui_test.dart
gate 'Endless Practice regression' flutter test test/endless_practice_phase_test.dart
gate 'Step 9 production regression' flutter test test/mission_run_step9_production_release_gate_test.dart
gate 'Step 8 128-seed scale audit' flutter test test/mission_step8_balance_quality_audit_test.dart --dart-define=STEP8_SEEDS=128 --reporter=expanded
gate 'Full BrightQuest regression suite' flutter test

printf '\nSAVED MISSION RESPONSIVE UI RELEASE GATE: PASS\n'
printf 'Manual Android and Windows device checks still remain required before shipping.\n'
