$ErrorActionPreference = 'Stop'

function Invoke-PhaseEStep {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )
    Write-Host "=== $Title ==="
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Phase E step failed with exit code ${LASTEXITCODE}: $Title"
    }
}

Invoke-PhaseEStep 'BrightQuest Phase E: formatting gate' {
    dart format --output=none --set-exit-if-changed lib test tool
}
Invoke-PhaseEStep 'BrightQuest Phase E: verified Phase D baseline' {
    & .\tool\qa\run_phase_d.ps1
}
Invoke-PhaseEStep 'BrightQuest Phase E: Classes 3-5 teacher/curriculum hardening audit' {
    dart run tool/qa/phase_e_curriculum_hardening_audit.dart
}
Invoke-PhaseEStep 'BrightQuest Phase E: content contracts' {
    dart run tool/content/validate_content.dart
}
Invoke-PhaseEStep 'BrightQuest Phase E: release-safety contract' {
    dart run tool/release/readiness_report.dart
}
Invoke-PhaseEStep 'BrightQuest Phase E: focused curriculum and Skill Studio regressions' {
    flutter test test/phase_e_curriculum_hardening_test.dart test/phase_e_skill_studio_ui_test.dart
}
Invoke-PhaseEStep 'BrightQuest Phase E: final complete Flutter regression sweep' {
    flutter test
}
Invoke-PhaseEStep 'BrightQuest Phase E: final static analysis' {
    flutter analyze
}

Write-Host '=== Phase E completed successfully ==='
Write-Host 'Technical Class 3-5 hardening is green. Qualified teacher sign-off and constructed-response review remain external gates.'
