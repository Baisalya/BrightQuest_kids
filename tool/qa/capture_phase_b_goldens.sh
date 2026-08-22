#!/usr/bin/env bash
set -euo pipefail

echo '=== BrightQuest Phase B: capture/update golden baselines ==='
flutter test \
  --dart-define=BRIGHTQUEST_PHASE_B_GOLDENS=true \
  --update-goldens \
  test/phase_b_alphabet_golden_test.dart

echo 'Golden baselines updated under test/goldens/phase_b/.'
