$ErrorActionPreference = "Stop"

$RepoRoot = (Get-Location).Path
$Patcher = Join-Path $RepoRoot "tool\apply_phase_07_08_utf8.dart"

if (-not (Test-Path $Patcher)) {
    throw "Missing tool\apply_phase_07_08_utf8.dart. Extract this hotfix ZIP into the BrightQuest repository root first."
}

Write-Host "Applying Phase 7+8 UTF-8 repair..."
dart run $Patcher
if ($LASTEXITCODE -ne 0) {
    throw "Phase 7+8 Dart patcher failed with exit code $LASTEXITCODE."
}

$Checks = @(
    @{
        Path = "lib\core\models\progress_models.dart"
        Pattern = "LearnerStage learnerStage;"
        Label = "ChildProfileSnapshot learnerStage field"
    },
    @{
        Path = "lib\core\models\progress_models.dart"
        Pattern = "'learnerStage': learnerStage.name"
        Label = "learnerStage serialization"
    },
    @{
        Path = "lib\core\models\progress_models.dart"
        Pattern = "learnerStageFromStorage(json['learnerStage'])"
        Label = "legacy-safe learnerStage restore"
    },
    @{
        Path = "lib\core\state\game_controller.dart"
        Pattern = "LearnerStage get learnerStage"
        Label = "GameController learnerStage getter"
    },
    @{
        Path = "lib\core\state\game_controller.dart"
        Pattern = "void setLearnerStage(LearnerStage value)"
        Label = "GameController setLearnerStage"
    },
    @{
        Path = "lib\core\state\game_controller.dart"
        Pattern = "LearnerStage learnerStage = LearnerStage.school"
        Label = "createProfile learnerStage parameter"
    },
    @{
        Path = "lib\features\nursery\nursery_home_screen.dart"
        Pattern = "this.rootMode = false"
        Label = "Nursery rootMode parameter"
    },
    @{
        Path = "lib\features\nursery\nursery_home_screen.dart"
        Pattern = "this.onOpenGrownUpArea"
        Label = "Nursery grown-up callback"
    }
)

foreach ($Check in $Checks) {
    $Path = Join-Path $RepoRoot $Check.Path
    if (-not (Test-Path $Path)) {
        throw "Missing file during verification: $($Check.Path)"
    }

    $Text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    if (-not $Text.Contains($Check.Pattern)) {
        throw "VERIFY FAILED: $($Check.Label) is still missing from $($Check.Path)"
    }

    Write-Host "PASS: $($Check.Label)"
}

Write-Host ""
Write-Host "Formatting changed sources..."
dart format `
  lib\app\brightquest_app.dart `
  lib\core\models\learner_stage.dart `
  lib\core\models\progress_models.dart `
  lib\core\session\learning_session_exit.dart `
  lib\core\state\game_controller.dart `
  lib\features\games\game_router.dart `
  lib\features\nursery\nursery_home_screen.dart `
  lib\features\parent\parent_dashboard_screen.dart `
  lib\widgets\bright_widgets.dart `
  test\learner_stage_persistence_test.dart `
  test\nursery_first_class_shell_test.dart `
  test\learning_session_continue_test.dart `
  test\phase7_8_architecture_test.dart

if ($LASTEXITCODE -ne 0) {
    throw "dart format failed."
}

Write-Host ""
Write-Host "Running flutter analyze..."
flutter analyze
if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze failed."
}

Write-Host ""
Write-Host "Phase 7+8 repair applied and analyzer verification passed."
