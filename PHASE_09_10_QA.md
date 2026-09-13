# Phase 9+10 QA

## Baseline

Apply only after the qualified Phase 7+8 state:

- `flutter analyze` — No issues found
- full `flutter test` — 442 passed, 2 skipped, no failures
- mission content audit — 0 blockers, 0 high, 3 medium duplicate-content findings

## Apply

Extract `BrightQuest_Phase9_10_Modified_Files.zip` into the repository root and
replace matching files.

## Format and analyze

```powershell
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

flutter analyze
```

## Phase 9+10 targeted tests

```powershell
flutter test test\child_journey_presentation_test.dart
flutter test test\child_progress_reward_ui_test.dart
flutter test test\parent_learning_report_separation_test.dart
flutter test test\phase9_10_architecture_test.dart
```

## Regression tests

```powershell
flutter test test\adaptive_ui_architecture_test.dart
flutter test test\phase5_6_home_worlds_architecture_test.dart
flutter test test\cosmetic_equipment_ui_test.dart
flutter test test\learner_stage_persistence_test.dart
flutter test test\nursery_first_class_shell_test.dart
flutter test test\learning_session_continue_test.dart
flutter test test\game_session_resume_safety_test.dart
flutter test test\audio_experience_test.dart
```

## Full gate

```powershell
flutter test
```

## Expected behavior

- Journey shows child-friendly quest/world growth only.
- Journey never shows accuracy, mastery, hints, adaptive-level numbers or weak
  topic analysis.
- Me contains one clear `My rewards` doorway rather than duplicated reward
  catalogs.
- Rewards Room still buys/equips/unequips the same persisted cosmetics.
- Rewards Room still exposes world trophies and achievement badges, now under
  collapsed Celebrations.
- Home no longer opens Rewards directly.
- School Parent Learning Evidence owns adventure mastery/accuracy/hints/adaptive
  diagnostics.
- Nursery Parent Learning Evidence contains Nursery evidence only.
- Phase 7+8 Nursery root and Continue-next flow remain intact.

## Runtime status

Flutter/Dart are not available in the artifact environment. No runtime PASS is
claimed here. The user's local commands above are the authoritative gate.
