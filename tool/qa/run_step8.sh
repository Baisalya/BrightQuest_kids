#!/usr/bin/env bash
set -euo pipefail

echo 'Running BrightQuest Step 8 mission balance/content audit...'
flutter test test/mission_step8_balance_quality_audit_test.dart --dart-define=STEP8_SEEDS=128 --reporter=expanded

echo 'Running Step 8 focused tests...'
flutter test test/mission_run_step8_balance_quality_test.dart
