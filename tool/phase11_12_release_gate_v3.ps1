$ErrorActionPreference = "Stop"

Write-Host "Phase 11+12 v3: verifying already-applied source state..."
dart run .\tool\verify_phase11_12_applied.dart
if ($LASTEXITCODE -ne 0) {
  throw "Phase 11+12 semantic source verification failed."
}

Write-Host ""
Write-Host "Phase 11+12 v3: formatting qualified files..."
dart format `
  lib\core\capabilities\learner_capability_boundary.dart `
  lib\app\learner_shell_policy.dart `
  lib\widgets\bright_adaptive.dart `
  lib\app\brightquest_app.dart `
  lib\features\home\home_screen.dart `
  lib\features\progress\progress_screen.dart `
  lib\features\profile\profile_screen.dart `
  lib\features\games\rewards_room_screen.dart `
  lib\core\state\game_controller.dart `
  lib\core\models\progress_models.dart `
  lib\features\parent\parent_dashboard_screen.dart `
  lib\features\parent\class_pack_screen.dart `
  lib\core\entitlements\entitlement_service.dart `
  lib\core\content\content_repository.dart `
  lib\widgets\bright_widgets.dart `
  lib\widgets\bright_design_system.dart `
  lib\widgets\learning_accessibility_widgets.dart `
  test\learner_capability_boundary_test.dart `
  test\learner_shell_policy_test.dart `
  test\bright_accessibility_layout_test.dart `
  test\phase11_12_accessibility_ui_test.dart `
  test\phase11_12_architecture_test.dart `
  test\adaptive_ui_architecture_test.dart
if ($LASTEXITCODE -ne 0) { throw "dart format failed." }

Write-Host ""
Write-Host "Phase 11+12 v3: flutter analyze..."
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed." }

$Tests = @(
  "test\learner_capability_boundary_test.dart",
  "test\learner_shell_policy_test.dart",
  "test\bright_accessibility_layout_test.dart",
  "test\phase11_12_accessibility_ui_test.dart",
  "test\phase11_12_architecture_test.dart",
  "test\adaptive_ui_architecture_test.dart",
  "test\phase9_10_architecture_test.dart",
  "test\child_progress_reward_ui_test.dart",
  "test\parent_learning_report_separation_test.dart",
  "test\cosmetic_equipment_ui_test.dart",
  "test\learner_stage_persistence_test.dart",
  "test\nursery_first_class_shell_test.dart",
  "test\learning_session_continue_test.dart",
  "test\game_session_resume_safety_test.dart",
  "test\audio_experience_test.dart",
  "test\step12_production_hardening_test.dart",
  "test\widget_smoke_test.dart"
)

foreach ($Test in $Tests) {
  Write-Host ""
  Write-Host "Running $Test ..."
  flutter test $Test
  if ($LASTEXITCODE -ne 0) {
    throw "Targeted/regression test failed: $Test"
  }
}

Write-Host ""
Write-Host "Phase 11+12 v3: full flutter test..."
flutter test
if ($LASTEXITCODE -ne 0) { throw "Full flutter test failed." }

Write-Host ""
Write-Host "Phase 11+12 release gate v3 PASSED."
