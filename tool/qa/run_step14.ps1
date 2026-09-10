$ErrorActionPreference = 'Stop'

function Invoke-Gate([string]$Label, [scriptblock]$Command) {
    Write-Host "`n== $Label ==" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }
}

Invoke-Gate 'Static analysis' { flutter analyze }
Invoke-Gate 'Step 14 logical unlimited practice tests' { flutter test test/step14_logical_unlimited_practice_test.dart test/step14_logical_unlimited_practice_ui_test.dart }
Invoke-Gate 'Step 13 adaptive non-repeat regression' { flutter test test/step13_adaptive_non_repeat_engine_test.dart }
Invoke-Gate 'Skill Studio UI regression' { flutter test test/phase_e_skill_studio_ui_test.dart }
Invoke-Gate 'Endless Practice regression' { flutter test test/endless_practice_phase_test.dart }
Invoke-Gate 'Step 9 production regression' { flutter test test/mission_run_step9_production_release_gate_test.dart }
Invoke-Gate 'Step 8 focused balance/content regression' { flutter test test/mission_run_step8_balance_quality_test.dart }
Invoke-Gate 'Step 8 128-seed scale audit' { flutter test test/mission_step8_balance_quality_audit_test.dart --dart-define=STEP8_SEEDS=128 --reporter=expanded }
Invoke-Gate 'Full BrightQuest regression suite' { flutter test }

Write-Host "`nSTEP 14 LOGICAL UNLIMITED PRACTICE RELEASE GATE: PASS" -ForegroundColor Green
Write-Host 'Manual Android and Windows device checks still remain required before shipping.'
