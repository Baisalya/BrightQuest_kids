$ErrorActionPreference = 'Stop'

function Invoke-Step13 {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )
    Write-Host "=== $Title ==="
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Step 13 failed with exit code ${LASTEXITCODE}: $Title"
    }
}

Invoke-Step13 'Step 13: formatting gate' {
    dart format --output=none --set-exit-if-changed lib test tool
}

Invoke-Step13 'Step 13: adaptive non-repeat regressions' {
    flutter test test/step13_adaptive_non_repeat_engine_test.dart
}

Invoke-Step13 'Step 13: existing persistent rotation and Endless Practice' {
    flutter test test/mission_run_step5_persistent_rotation_test.dart test/endless_practice_phase_test.dart
}

Invoke-Step13 'Step 13: Skill Studio and curriculum regression' {
    flutter test test/phase_e_skill_studio_ui_test.dart test/phase_e_curriculum_hardening_test.dart
}

Invoke-Step13 'Step 13: mission balance/content-quality gates' {
    flutter test test/mission_run_step8_balance_quality_test.dart test/mission_step8_balance_quality_audit_test.dart
}

Invoke-Step13 'Step 13: complete regression sweep' {
    flutter test
}

Invoke-Step13 'Step 13: static analysis' {
    flutter analyze
}

Write-Host '=== Step 13 automated gates completed ==='
Write-Host 'Unlimited practice means unlimited sessions with bounded anti-repeat/spaced review; it is not a claim of infinitely many unique authored questions.'
