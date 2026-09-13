# Modified Files — Phase 5 + Phase 6

## New

- `lib/features/home/home_primary_action.dart`
  - Pure recommendation priority boundary for the Today screen.
- `test/home_primary_action_test.dart`
  - Priority unit tests.
- `test/phase5_6_home_worlds_architecture_test.dart`
  - Static regression contract for Home/Worlds ownership.
- `docs/PHASE_05_06_HOME_WORLDS_CONSOLIDATION.md`
  - Architecture contract.
- `PHASE_05_06_QA.md`
  - Qualification and regression instructions.
- `MODIFIED_FILES_PHASE_05_06.md`
  - This manifest.

## Replaced / modified

- `lib/features/home/home_screen.dart`
  - Replaces the dense dashboard with one recommendation-first action, compact
    Journey, collapsed daily wins, Rewards Room utility and Nursery bridge.
- `lib/features/adventures/adventures_screen.dart`
  - Removes global saved-mission dashboard and Quick Play; becomes
    exploration-only Worlds.
- `test/adaptive_ui_architecture_test.dart`
  - Stops asserting removed Home hero copy; asserts the primary-action surface.
- `test/widget_smoke_test.dart`
  - Decouples game-router smoke coverage from the removed Home Quick Play grid.
- `test/widget_test.dart`
  - Updates root smoke contract to the new Home primary action.
- `test/visual_fidelity_test.dart`
  - Updates Home visual identity assertion without changing scene coverage.
- `test/saved_missions_responsive_ui_test.dart`
  - Verifies latest resume ownership on Today and per-game saved mission
    ownership inside Worlds.

## Production files intentionally untouched

- `lib/core/state/game_controller.dart`
- `lib/core/persistence/**`
- `lib/core/session/**`
- `lib/features/games/game_router.dart`
- Nursery engine/screens
- entitlement and Parent PIN logic
