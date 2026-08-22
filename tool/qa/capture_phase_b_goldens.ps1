$ErrorActionPreference = 'Stop'

Write-Host '=== BrightQuest Phase B: capture/update Windows golden baselines ==='
flutter test `
    --dart-define=BRIGHTQUEST_PHASE_B_GOLDENS=true `
    --update-goldens `
    test/phase_b_alphabet_golden_test.dart
if ($LASTEXITCODE -ne 0) {
    throw "Phase B golden capture failed with exit code $LASTEXITCODE"
}
Write-Host 'Golden baselines updated under test/goldens/phase_b/.'
