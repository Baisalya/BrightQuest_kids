[CmdletBinding()]
param(
    [switch]$BuildAndroidAab,
    [switch]$BuildWindows
)

$ErrorActionPreference = 'Stop'

function Invoke-PhaseDStep {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    Write-Host "=== $Title ==="
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Phase D step failed with exit code ${LASTEXITCODE}: $Title"
    }
}

Invoke-PhaseDStep 'BrightQuest Phase D: formatting gate' {
    dart format --output=none --set-exit-if-changed lib test tool
}

Invoke-PhaseDStep 'BrightQuest Phase D: verified Phase C baseline' {
    & "$PSScriptRoot\run_phase_c.ps1"
}

Invoke-PhaseDStep 'BrightQuest Phase D: release-candidate static audit' {
    dart run tool/qa/phase_d_release_candidate_audit.dart
}

Invoke-PhaseDStep 'BrightQuest Phase D: content contracts' {
    dart run tool/content/validate_content.dart
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    dart run tool/content/validate_nursery_content.dart
}

Invoke-PhaseDStep 'BrightQuest Phase D: release-safety contract' {
    dart run tool/release/readiness_report.dart
}

Invoke-PhaseDStep 'BrightQuest Phase D: accessibility/localization/performance regressions' {
    flutter test test/phase_d_release_candidate_test.dart test/phase_d_accessibility_polish_test.dart
}

Invoke-PhaseDStep 'BrightQuest Phase D: final complete Flutter regression sweep' {
    flutter test
}

Invoke-PhaseDStep 'BrightQuest Phase D: final static analysis' {
    flutter analyze
}

if ($BuildAndroidAab) {
    Invoke-PhaseDStep 'BrightQuest Phase D: Android release candidate AAB' {
        flutter build appbundle --release
    }
}

if ($BuildWindows) {
    Invoke-PhaseDStep 'BrightQuest Phase D: safe Windows release candidate' {
        flutter build windows --release
    }
}

Write-Host '=== Phase D completed successfully ==='
Write-Host "Android AAB built: $($BuildAndroidAab.IsPresent)"
Write-Host "Windows release built: $($BuildWindows.IsPresent)"
Write-Host 'QA completed. Artifact builds run only when their explicit switches are supplied. External teacher/pilot/store/privacy/real-device qualification gates remain pending.'
