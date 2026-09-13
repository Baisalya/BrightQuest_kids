$ErrorActionPreference = "Stop"

Write-Host "Phase 9+10: formatting changed files..."
dart format `
  lib\features\progress\child_journey_presentation.dart `
  lib\features\progress\progress_screen.dart `
  lib\features\profile\profile_screen.dart `
  lib\features\games\rewards_room_screen.dart `
  lib\features\parent\parent_learning_report_screen.dart `
  lib\features\home\home_screen.dart `
  test\child_journey_presentation_test.dart `
  test\child_progress_reward_ui_test.dart `
  test\parent_learning_report_separation_test.dart `
  test\phase9_10_architecture_test.dart `
  test\adaptive_ui_architecture_test.dart `
  test\phase5_6_home_worlds_architecture_test.dart
if ($LASTEXITCODE -ne 0) { throw "dart format failed." }

Write-Host ""
Write-Host "Phase 9+10: flutter analyze..."
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed." }

$Tests = @(
  "test\child_journey_presentation_test.dart",
  "test\child_progress_reward_ui_test.dart",
  "test\parent_learning_report_separation_test.dart",
  "test\phase9_10_architecture_test.dart",
  "test\adaptive_ui_architecture_test.dart",
  "test\phase5_6_home_worlds_architecture_test.dart",
  "test\cosmetic_equipment_ui_test.dart",
  "test\learner_stage_persistence_test.dart",
  "test\nursery_first_class_shell_test.dart",
  "test\learning_session_continue_test.dart",
  "test\game_session_resume_safety_test.dart",
  "test\audio_experience_test.dart"
)

foreach ($Test in $Tests) {
  Write-Host ""
  Write-Host "Running $Test ..."
  flutter test $Test
  if ($LASTEXITCODE -ne 0) { throw "Targeted/regression test failed: $Test" }
}

Write-Host ""
Write-Host "Phase 9+10: full flutter test..."
flutter test
if ($LASTEXITCODE -ne 0) { throw "Full flutter test failed." }

Write-Host ""
Write-Host "Phase 9+10 release gate PASSED."
