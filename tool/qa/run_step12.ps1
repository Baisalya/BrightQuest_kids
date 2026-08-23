param(
    [switch]$BuildReleaseArtifacts
)

$ErrorActionPreference = 'Stop'

function Invoke-Step12 {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )
    Write-Host "=== $Title ==="
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Step 12 failed with exit code ${LASTEXITCODE}: $Title"
    }
}

Invoke-Step12 'Step 12: formatting gate' {
    dart format --output=none --set-exit-if-changed lib test tool
}

Invoke-Step12 'Step 12: static production-hardening audit' {
    dart run tool/qa/step12_production_readiness_audit.dart
}

Invoke-Step12 'Step 12: existing release-safety contract' {
    dart run tool/release/readiness_report.dart
}

Invoke-Step12 'Step 12: content contracts' {
    dart run tool/content/validate_content.dart
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    dart run tool/content/validate_nursery_content.dart
}

Invoke-Step12 'Step 12: focused production regressions' {
    flutter test test/step12_production_hardening_test.dart test/game_session_resume_safety_test.dart test/learning_audio_accessibility_test.dart test/nursery_simple_game_flow_test.dart test/phase_d_release_candidate_test.dart
}

Invoke-Step12 'Step 12: complete regression sweep' {
    flutter test
}

Invoke-Step12 'Step 12: final static analysis' {
    flutter analyze
}

if ($BuildReleaseArtifacts) {
    Invoke-Step12 'Step 12: Android release AAB build' {
        flutter build appbundle --release
    }
    Invoke-Step12 'Step 12: Windows release build' {
        flutter build windows --release
    }
}

Write-Host '=== Step 12 automated gates completed ==='
Write-Host 'Real-device, native Windows soak, teacher/pilot, store billing, privacy/listing and signed-artifact gates remain external and must not be auto-approved.'
