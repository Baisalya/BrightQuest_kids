$ErrorActionPreference = 'Stop'

function Invoke-PhaseAStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    Write-Host "=== $Title ==="
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Phase A step failed with exit code ${LASTEXITCODE}: $Title"
    }
}

Invoke-PhaseAStep 'BrightQuest Phase A: content contracts' {
    dart run tool/qa/validate_content_contracts.dart
}

Invoke-PhaseAStep 'BrightQuest Phase A: Nursery letters / phonics simulation' {
    dart run tool/qa/simulate_nursery_letters.dart --seeds 256
}

Invoke-PhaseAStep 'BrightQuest Phase A: Nursery numbers / early math simulation' {
    dart run tool/qa/simulate_nursery_numbers.dart --seeds 256
}

Invoke-PhaseAStep 'BrightQuest Phase A: whole-app teaching correctness audit' {
    dart run tool/qa/phase_a_teaching_audit.dart --seeds 128
}

Invoke-PhaseAStep 'BrightQuest Phase A: regression tests' {
    flutter test test/phase_a_teaching_correctness_audit_test.dart test/phase_a_feedback_alignment_test.dart
}

Write-Host '=== Phase A completed successfully ==='
