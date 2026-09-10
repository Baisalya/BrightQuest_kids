# Modified files — Nursery Step 7

Production:

- `lib/features/nursery/nursery_lesson_journey.dart` — pure Study/Guided/Independent planner.
- `lib/features/nursery/nursery_lesson_journey_board.dart` — three-stage lesson board.
- `lib/features/nursery/nursery_lesson_stage_indicator.dart` — reusable stage marker.
- `lib/features/nursery/nursery_lesson_screen.dart` — session Study state and explicit Guided transition wiring.
- `lib/features/nursery/nursery_lesson_teaching.dart` — Step 1 framing and Guided Play continuation.
- `lib/features/nursery/nursery_lesson_activity.dart` — Step 2/3 framing and guided support cue.
- `lib/features/nursery/nursery_play_board.dart` — slimmed back to shared game/portal planning helpers.

Tests:

- `test/nursery_study_guided_independent_flow_test.dart` — journey mapping, recommendation, full 3-stage widget flow, persistence boundary.
- `test/nursery_simple_game_flow_test.dart` — validates the three-step board and scrolls to the intentionally lower Guided action.
- `test/phase_a_feedback_alignment_test.dart` — scroll-aware access to the secondary game picker.
- `test/phase_c_count_quiz_integration_test.dart` — scroll-aware access to the secondary game picker.

QA documentation:

- `STEP21_NURSERY_STUDY_GUIDED_INDEPENDENT_QA.md`
- `MODIFIED_FILES_STEP21_NURSERY_STUDY_GUIDED_INDEPENDENT.md`
