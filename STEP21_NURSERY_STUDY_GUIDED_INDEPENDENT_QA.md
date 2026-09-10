# Step 21 / Nursery Step 7 — Study → Guided Play → Independent Game QA

## Scope

This step changes Nursery lesson navigation/presentation only. It does not change authored Nursery content, activity IDs, response rules, evidence payloads, mastery logic, review generation, storage schema, packages, or backend behavior.

## Learning journey

Each Nursery skill now presents three explicit, non-locking stages:

1. **Study** — picture/sound explanation and worked example.
2. **Guided Play** — the authored `guided` activity with a visible support cue and normal Help access.
3. **Independent Game** — every remaining authored activity (`independent`, `transfer`, and optional non-mastery `practice`) remains reachable in authored order.

Recommendation is derived without a new save field:

- first visit with no evidence → Study;
- after Study, or when prior evidence exists but guided is incomplete → Guided Play;
- after guided completion → Independent Game.

Study visit state is session-only. Correct activity evidence remains the source of persisted learning progress.

## Structural boundaries

- `nursery_lesson_journey.dart` is a pure planner with no app scope or persistence access.
- `nursery_lesson_journey_board.dart` owns the three-step board UI.
- `nursery_lesson_stage_indicator.dart` provides the reusable Step 1/2/3 stage marker.
- `nursery_play_board.dart` is reduced to portal/game-label helpers and next-activity helpers.
- Teaching/activity presentation files render stage framing only; they do not record evidence.

## Static release checks performed

- Nursery pack: 32 skills / 132 activities unchanged.
- Phase counts unchanged: 32 guided, 64 independent, 32 transfer, 4 practice.
- Exactly one authored guided activity per skill.
- All authored activities remain represented exactly once by Guided + Independent journey grouping.
- `assets/content/nursery/pack_v1.json`: unchanged from Step 6 QA baseline.
- `assets/content/nursery/schema_v1.json`: unchanged.
- `nursery_response_evaluator.dart`: unchanged.
- `nursery_learning_models.dart`: unchanged.
- `nursery_practice_generator.dart`: unchanged.
- `game_controller.dart`: unchanged.
- `pubspec.yaml`: unchanged.
- `_submitActivity`, `_submitGenerated`, `_kindForPhase`: unchanged.
- 208/208 Nursery letter-picture asset references exist.
- New Step 7 journey presentation files contain no raw pictographic glyphs, periodic timers, repeating animations, direct persistence access, or evaluator access.

## Flutter qualification

The execution environment used to prepare this archive does not include Flutter/Dart SDK tooling. Run locally:

```powershell
flutter analyze
flutter test test/nursery_study_guided_independent_flow_test.dart
flutter test test/nursery_lesson_architecture_test.dart
flutter test test/nursery_picture_first_games_test.dart
flutter test test/nursery_simple_game_flow_test.dart
flutter test test/nursery_layout_test.dart
flutter test test/phase_a_feedback_alignment_test.dart
flutter test test/phase_c_count_quiz_integration_test.dart
flutter test
```
