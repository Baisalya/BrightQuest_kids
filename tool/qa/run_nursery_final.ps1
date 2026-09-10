$ErrorActionPreference = 'Stop'

Write-Host 'BrightQuest Nursery final release qualification' -ForegroundColor Cyan

flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$tests = @(
  'test/nursery_final_release_gate_test.dart',
  'test/nursery_emoji_content_migration_test.dart',
  'test/nursery_motion_feedback_polish_test.dart',
  'test/nursery_lesson_architecture_test.dart',
  'test/nursery_picture_first_games_test.dart',
  'test/nursery_study_guided_independent_flow_test.dart',
  'test/nursery_simple_game_flow_test.dart',
  'test/nursery_layout_test.dart',
  'test/phase_a_teaching_correctness_audit_test.dart',
  'test/phase_b_phonics_correctness_test.dart',
  'test/phase_c_count_quiz_integration_test.dart',
  'test/phase_c_math_world_correctness_test.dart',
  'test/phase_d_accessibility_polish_test.dart',
  'test/phase_d_release_candidate_test.dart'
)

foreach ($test in $tests) {
  Write-Host "Running $test" -ForegroundColor Yellow
  flutter test $test
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host 'Running full Flutter suite' -ForegroundColor Yellow
flutter test
exit $LASTEXITCODE
