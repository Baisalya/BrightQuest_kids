$ErrorActionPreference = 'Stop'

function Invoke-Gate([string]$Label, [scriptblock]$Command) {
  Write-Host "`n== $Label ==" -ForegroundColor Cyan
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE"
  }
}

Invoke-Gate 'Static analysis' { flutter analyze }
Invoke-Gate 'Saved mission responsive UI tests' {
  flutter test test/saved_missions_responsive_ui_test.dart
}
Invoke-Gate 'Cosmetic ownership, equip and responsive UI regression' {
  flutter test test/cosmetic_equipment_ui_test.dart
}
Invoke-Gate 'Endless Practice regression' {
  flutter test test/endless_practice_phase_test.dart
}
Invoke-Gate 'Step 9 production regression' {
  flutter test test/mission_run_step9_production_release_gate_test.dart
}
Invoke-Gate 'Step 8 128-seed scale audit' {
  flutter test test/mission_step8_balance_quality_audit_test.dart --dart-define=STEP8_SEEDS=128 --reporter=expanded
}
Invoke-Gate 'Full BrightQuest regression suite' { flutter test }

Write-Host "`nSAVED MISSION RESPONSIVE UI RELEASE GATE: PASS" -ForegroundColor Green
Write-Host 'Manual Android and Windows device checks still remain required before shipping.'
