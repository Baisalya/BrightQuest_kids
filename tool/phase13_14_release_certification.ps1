param(
  [switch]$RequireCleanGit,
  [switch]$BuildWindows,
  [switch]$BuildAndroid
)

$ErrorActionPreference = "Stop"

function Invoke-GateStep {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][scriptblock]$Command
  )

  Write-Host ""
  Write-Host "=== $Label ==="
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE."
  }
}

function Get-CommandOutput {
  param([scriptblock]$Command)
  try {
    $value = & $Command 2>$null
    if ($LASTEXITCODE -ne 0) { return "unavailable" }
    return ($value -join "`n").Trim()
  } catch {
    return "unavailable"
  }
}

$GitHead = Get-CommandOutput { git rev-parse HEAD }
$GitBranch = Get-CommandOutput { git branch --show-current }
$GitStatus = Get-CommandOutput { git status --porcelain }

if ($RequireCleanGit -and $GitStatus -ne "" -and $GitStatus -ne "unavailable") {
  throw "Git working tree is not clean. Commit/stash changes or omit -RequireCleanGit."
}

Invoke-GateStep "Phase 13 migration hardening" {
  dart run .\tool\apply_phase13_migration_hardening.dart
}

Invoke-GateStep "Format Phase 13+14 files" {
  dart format `
    lib\core\models\progress_models.dart `
    test\phase13_progress_store_migration_test.dart `
    test\phase13_snapshot_compatibility_test.dart `
    test\phase13_session_store_recovery_test.dart `
    test\phase13_controller_upgrade_test.dart `
    test\phase13_14_architecture_test.dart `
    tool\apply_phase13_migration_hardening.dart `
    tool\verify_phase13_14_release_invariants.dart
}

Invoke-GateStep "Phase 13+14 semantic invariant verification" {
  dart run .\tool\verify_phase13_14_release_invariants.dart
}

Invoke-GateStep "Flutter analyzer" {
  flutter analyze
}

$FocusedTests = @(
  "test\phase13_progress_store_migration_test.dart",
  "test\phase13_snapshot_compatibility_test.dart",
  "test\phase13_session_store_recovery_test.dart",
  "test\phase13_controller_upgrade_test.dart",
  "test\phase13_14_architecture_test.dart",
  "test\learner_capability_boundary_test.dart",
  "test\learner_shell_policy_test.dart",
  "test\learner_stage_persistence_test.dart",
  "test\nursery_first_class_shell_test.dart",
  "test\phase5_6_home_worlds_architecture_test.dart",
  "test\phase7_8_architecture_test.dart",
  "test\phase9_10_architecture_test.dart",
  "test\phase11_12_architecture_test.dart",
  "test\child_progress_reward_ui_test.dart",
  "test\parent_learning_report_separation_test.dart",
  "test\bright_accessibility_layout_test.dart",
  "test\phase11_12_accessibility_ui_test.dart",
  "test\learning_session_continue_test.dart",
  "test\game_session_resume_safety_test.dart",
  "test\cosmetic_equipment_ui_test.dart",
  "test\audio_experience_test.dart",
  "test\step12_production_hardening_test.dart",
  "test\widget_smoke_test.dart"
)

foreach ($Test in $FocusedTests) {
  Invoke-GateStep "Regression: $Test" {
    flutter test $Test
  }
}

Invoke-GateStep "Deterministic mission/content quality audit" {
  flutter test test\mission_step8_balance_quality_audit_test.dart
}

Invoke-GateStep "Full Flutter regression suite" {
  flutter test
}

if ($BuildWindows) {
  Invoke-GateStep "Windows release build" {
    flutter build windows --release
  }
}

if ($BuildAndroid) {
  Invoke-GateStep "Android App Bundle release build" {
    flutter build appbundle --release
  }
}

$FlutterVersion = Get-CommandOutput { flutter --version }
$DartVersion = Get-CommandOutput { dart --version }
$CertifiedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
$DirtyLabel = if ($GitStatus -eq "") { "clean" } elseif ($GitStatus -eq "unavailable") { "unavailable" } else { "dirty" }

$CertificateDirectory = Join-Path (Get-Location) "build"
New-Item -ItemType Directory -Force -Path $CertificateDirectory | Out-Null
$CertificatePath = Join-Path $CertificateDirectory "phase13_14_release_certification.txt"

$Lines = @(
  "BrightQuest Kids - Phase 13+14 Release Certification",
  "Status: PASS",
  "Certified at: $CertifiedAt",
  "Git HEAD: $GitHead",
  "Git branch: $GitBranch",
  "Git working tree: $DirtyLabel",
  "Require clean git: $RequireCleanGit",
  "Windows release build selected: $BuildWindows",
  "Android App Bundle selected: $BuildAndroid",
  "",
  "Certified invariants:",
  "- Progress persistence schema remains v6.",
  "- Legacy progress keys v5, v3, and v2 remain readable fallbacks.",
  "- Legacy writes converge to current v6 and retire old keys.",
  "- LearnerStage additive migration defaults legacy profiles to School.",
  "- Persisted unsupported School classes normalize to Class 4.",
  "- Persisted profile-map key is authoritative profile identity.",
  "- Malformed entitlement-cache class identity is rejected.",
  "- Local entitlement cache never grants production access.",
  "- Game-session persistence remains independent schema v1.",
  "- Corrupt session state cannot erase authoritative progress.",
  "- Invalid/stale app sessions are discarded by controller restore guards.",
  "- Phase 1-12 representative regression gates passed.",
  "- Deterministic mission/content quality audit passed.",
  "- Full Flutter test suite passed.",
  "",
  "Flutter:",
  $FlutterVersion,
  "",
  "Dart:",
  $DartVersion
)

$Lines | Set-Content -Path $CertificatePath -Encoding UTF8

Write-Host ""
Write-Host "============================================================"
Write-Host "PHASE 13+14 RELEASE CERTIFICATION: PASS"
Write-Host "Certificate: $CertificatePath"
Write-Host "============================================================"
