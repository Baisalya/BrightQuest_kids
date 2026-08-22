$ErrorActionPreference = 'Stop'

function Invoke-PhaseBStep {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    Write-Host "=== $Title ==="
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Phase B step failed with exit code ${LASTEXITCODE}: $Title"
    }
}

Invoke-PhaseBStep 'BrightQuest Phase B: formatting gate' {
    dart format --output=none --set-exit-if-changed lib test tool
}

Invoke-PhaseBStep 'BrightQuest Phase B: verified Phase A baseline' {
    & "$PSScriptRoot\run_phase_a.ps1"
}

Invoke-PhaseBStep 'BrightQuest Phase B: focused letters / sounds audit' {
    dart run tool/qa/simulate_nursery_phonics_phase_b.dart
}

Invoke-PhaseBStep 'BrightQuest Phase B: Nursery content validator' {
    dart run tool/content/validate_nursery_content.dart
}

Invoke-PhaseBStep 'BrightQuest Phase B: release-safety validator' {
    dart run tool/release/readiness_report.dart
}

Invoke-PhaseBStep 'BrightQuest Phase B: focused unit and widget regressions' {
    flutter test test/phase_b_phonics_correctness_test.dart test/phase_b_alphabet_ui_test.dart test/phase_a_feedback_alignment_test.dart
}

Invoke-PhaseBStep 'BrightQuest Phase B: complete Flutter regression suite' {
    flutter test
}

Invoke-PhaseBStep 'BrightQuest Phase B: static analysis' {
    flutter analyze
}

Write-Host '=== Phase B completed successfully ==='
