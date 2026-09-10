# Modified files — Nursery Step 9

Motion foundation:

- `lib/features/nursery/nursery_motion.dart` — shared finite motion policy/reaction/reveal boundary with reduced-motion and Windows geometry safety.
- `lib/features/nursery/nursery_asset_reaction.dart` — applies OS reduced-motion and Windows-safe opacity behavior to picture reactions.

Lesson feedback and activity presentation:

- `lib/features/nursery/nursery_lesson_feedback.dart` — finite success/retry/hint reactions and calm celebration.
- `lib/features/nursery/nursery_lesson_activity.dart` — shared motion reveal for the game scene and accessibility-aware feedback wiring.
- `lib/features/nursery/nursery_lesson_review.dart` — Memory Game follows resolved motion preference and shared feedback/cheer UI.
- `lib/features/nursery/nursery_lesson_screen.dart` — combines app reduced-motion with OS `disableAnimations` before passing motion state to stages.
- `lib/features/nursery/nursery_lesson_teaching.dart` — OS/Windows-safe teaching swaps and worked-example motion.

Game interaction polish:

- `lib/features/nursery/nursery_game_value.dart` — answer cards use the central finite reveal policy.
- `lib/features/nursery/nursery_game_chrome.dart` — match/sort selection cards use finite selection/completion reactions.
- `lib/features/nursery/nursery_trace_game.dart` — tracing progress receives a small one-shot progress/success reaction.
- `lib/features/nursery/nursery_lesson_journey_board.dart` — recommended journey card uses the shared reveal policy.
- `lib/features/nursery/nursery_world_screen.dart` — ABC picture-book swaps respect OS reduced-motion.

Tests and QA documentation:

- `test/nursery_motion_feedback_polish_test.dart` — finite-settle, OS reduced-motion, explicit reduced-motion and no-loop release gates.
- `test/nursery_lesson_architecture_test.dart` — keeps the new motion layer presentation-only and loop-free.
- `STEP23_NURSERY_MOTION_FEEDBACK_QA.md`
- `MODIFIED_FILES_STEP23_NURSERY_MOTION_FEEDBACK_POLISH.md`

Cumulative Step 9 diff relative to the QA-passed Step 8 QAFix baseline: **16 files**.
