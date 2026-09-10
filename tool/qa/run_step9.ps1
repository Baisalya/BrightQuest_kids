$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-ReleaseGate {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][scriptblock]$Command
  )

  Write-Host "`n== $Label ==" -ForegroundColor Cyan
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE."
  }
}

Invoke-ReleaseGate 'Static analysis' { flutter analyze }
Invoke-ReleaseGate 'Step 9 production release tests' {
  flutter test test/mission_run_step9_production_release_gate_test.dart --reporter=expanded
}
Invoke-ReleaseGate 'Crash/resume/reward recovery regression' {
  flutter test test/game_session_resume_safety_test.dart
}
Invoke-ReleaseGate 'Step 8 focused balance/content regression' {
  flutter test test/mission_run_step8_balance_quality_test.dart
}
Invoke-ReleaseGate 'Step 8 128-seed scale audit' {
  flutter test test/mission_step8_balance_quality_audit_test.dart --dart-define=STEP8_SEEDS=128 --reporter=expanded
}
Invoke-ReleaseGate 'Full BrightQuest regression suite' { flutter test }

Write-Host "`nAUTOMATED STEP 9 RELEASE GATE: PASS" -ForegroundColor Green
Write-Host 'Manual Android and Windows device checks in docs/STEP9_MISSION_SYSTEM_RELEASE_GATE.md remain required before shipping.' -ForegroundColor Yellow
