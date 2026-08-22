#!/usr/bin/env bash
set -euo pipefail

step() {
  echo "=== $1 ==="
  shift
  "$@"
}

step "BrightQuest Phase E: formatting gate" dart format --output=none --set-exit-if-changed lib test tool
step "BrightQuest Phase E: verified Phase D baseline" bash tool/qa/run_phase_d.sh
step "BrightQuest Phase E: Classes 3-5 teacher/curriculum hardening audit" dart run tool/qa/phase_e_curriculum_hardening_audit.dart
step "BrightQuest Phase E: content contracts" dart run tool/content/validate_content.dart
step "BrightQuest Phase E: release-safety contract" dart run tool/release/readiness_report.dart
step "BrightQuest Phase E: focused curriculum and Skill Studio regressions" flutter test test/phase_e_curriculum_hardening_test.dart test/phase_e_skill_studio_ui_test.dart
step "BrightQuest Phase E: final complete Flutter regression sweep" flutter test
step "BrightQuest Phase E: final static analysis" flutter analyze

echo "=== Phase E completed successfully ==="
echo "Technical Class 3-5 hardening is green. Qualified teacher sign-off and constructed-response review remain external gates."
