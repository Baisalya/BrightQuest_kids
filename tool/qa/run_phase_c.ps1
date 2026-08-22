$ErrorActionPreference = 'Stop'

function Invoke-PhaseCStep {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    Write-Host "=== $Title ==="
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Phase C step failed with exit code ${LASTEXITCODE}: $Title"
    }
}

Invoke-PhaseCStep 'BrightQuest Phase C: formatting gate' {
    dart format --output=none --set-exit-if-changed lib test tool
}

Invoke-PhaseCStep 'BrightQuest Phase C: verified Phase B baseline' {
    & "$PSScriptRoot\run_phase_b.ps1"
}

Invoke-PhaseCStep 'BrightQuest Phase C: Math + My World audit' {
    dart run tool/qa/simulate_nursery_math_world_phase_c.dart
}

Invoke-PhaseCStep 'BrightQuest Phase C: Nursery content validator' {
    dart run tool/content/validate_nursery_content.dart
}

Invoke-PhaseCStep 'BrightQuest Phase C: release-safety validator' {
    dart run tool/release/readiness_report.dart
}

Invoke-PhaseCStep 'BrightQuest Phase C: Count / Quiz integration regressions' {
    flutter test test/phase_c_math_world_correctness_test.dart test/phase_c_count_quiz_integration_test.dart
}

Invoke-PhaseCStep 'BrightQuest Phase C: complete Flutter regression suite' {
    flutter test
}

Invoke-PhaseCStep 'BrightQuest Phase C: static analysis' {
    flutter analyze
}

Write-Host '=== Phase C completed successfully ==='
