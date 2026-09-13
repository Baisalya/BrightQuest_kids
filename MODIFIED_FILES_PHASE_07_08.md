# Modified Files — Phase 7 + Phase 8

## New full files

- `lib/core/models/learner_stage.dart`
- `lib/core/session/learning_session_exit.dart`
- `test/learner_stage_persistence_test.dart`
- `test/nursery_first_class_shell_test.dart`
- `test/learning_session_continue_test.dart`
- `test/phase7_8_architecture_test.dart`
- `docs/PHASE_07_08_UNIFIED_SESSION_NURSERY_STAGE.md`
- `PHASE_07_08_QA.md`
- `README_PHASE_07_08.md`
- `APPLY_PHASE_07_08.ps1`

## Full replacement files included

- `lib/app/brightquest_app.dart`
  - stage-aware root shell; Nursery becomes a root learner mode.
- `lib/features/home/home_screen.dart`
  - removes the temporary Nursery shortcut from School Home.
- `test/phase5_6_home_worlds_architecture_test.dart`
  - Phase 8 supersedes the temporary Nursery-bridge assertion.

## Existing large files patched in-place by APPLY_PHASE_07_08.ps1

- `lib/core/models/progress_models.dart`
  - persisted `ChildProfileSnapshot.learnerStage`, legacy School fallback.
- `lib/core/state/game_controller.dart`
  - learner-stage getter/mutation/profile creation/switch/reset preservation.
- `lib/features/nursery/nursery_home_screen.dart`
  - root mode and protected grown-up utility.
- `lib/features/parent/parent_dashboard_screen.dart`
  - explicit Nursery/School stage selection, Nursery profile creation, and suppression of School-only analytics while Nursery is active.
- `lib/widgets/bright_widgets.dart`
  - stage-aware header; shared Continue/Replay result hierarchy.
- `lib/features/games/game_router.dart`
  - consumes typed result exit and safely opens the exact next level.

## Intentionally untouched

- all eight main game-screen implementations
- curriculum/content packs and IDs
- school/Nursery correctness engines
- entitlement service/model
- Parent PIN implementation
- session-store schema and 14-day retention policy
- Nursery authored content
