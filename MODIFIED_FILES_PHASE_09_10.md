# Modified files — Phase 9 + Phase 10

## Production

- `lib/features/progress/child_journey_presentation.dart` — NEW
  - qualitative child journey presentation boundary.
- `lib/features/progress/progress_screen.dart`
  - replaces analytical child Progress with motivational My Journey.
- `lib/features/profile/profile_screen.dart`
  - identity/comfort surface plus one Rewards doorway.
- `lib/features/games/rewards_room_screen.dart`
  - single detailed owner for looks, trophies and badges.
- `lib/features/parent/parent_learning_report_screen.dart`
  - stage-aware parent evidence with School-only adventure diagnostics.
- `lib/features/home/home_screen.dart`
  - removes the reward shortcut from learning Home.

## Tests

- `test/child_journey_presentation_test.dart` — NEW
- `test/child_progress_reward_ui_test.dart` — NEW
- `test/parent_learning_report_separation_test.dart` — NEW
- `test/phase9_10_architecture_test.dart` — NEW
- `test/adaptive_ui_architecture_test.dart`
  - migrates Journey title expectation from My Progress to My Journey.
- `test/phase5_6_home_worlds_architecture_test.dart`
  - Phase 10 supersedes the temporary Home reward shortcut contract.

## Intentionally not modified

- `lib/core/state/game_controller.dart`
- `lib/core/models/progress_models.dart`
- entitlement/store billing
- curriculum/content
- all eight game screens
- session persistence/router
- Nursery learning engines
- achievement catalog
- cosmetic catalog
