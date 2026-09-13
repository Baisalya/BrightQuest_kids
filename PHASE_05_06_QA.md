# Phase 5+6 QA

## Source baseline

Apply this overlay **after**:
1. Phase 3+4 learner-shell overlay.
2. Phase 3+4 saved-mission timestamp test hotfix.

The previously reported local gate for that baseline was:
- `flutter analyze`: no issues found.
- saved-mission targeted test: 2/2 passed.
- full suite: 426 passed, 2 skipped, no failures.

## Structural checks performed in this deliverable

- Home has one `home_primary_action`.
- Home old competing sections are absent.
- Home primary policy is pure and separately unit-tested.
- Daily reward claiming remains reachable.
- Nursery compatibility access remains reachable.
- Rewards Room remains reachable after the global game grid is removed.
- Worlds has no global Quick Play.
- Worlds has no global saved-mission dashboard.
- Saved sessions remain represented in their owning world/game.
- No production controller, persistence, session, entitlement, or router file is
  modified.

## Local qualification

Run:

```powershell
dart format lib\features\home\home_screen.dart `
  lib\features\home\home_primary_action.dart `
  lib\features\adventures\adventures_screen.dart `
  test\home_primary_action_test.dart `
  test\phase5_6_home_worlds_architecture_test.dart `
  test\adaptive_ui_architecture_test.dart `
  test\widget_smoke_test.dart `
  test\widget_test.dart `
  test\visual_fidelity_test.dart `
  test\saved_missions_responsive_ui_test.dart

flutter analyze

flutter test test\home_primary_action_test.dart
flutter test test\phase5_6_home_worlds_architecture_test.dart
flutter test test\saved_missions_responsive_ui_test.dart
flutter test test\adaptive_ui_architecture_test.dart
flutter test test\widget_smoke_test.dart
flutter test
```

## Runtime status in this environment

Flutter/Dart are not installed in the artifact environment, so no local
`flutter analyze` or `flutter test` PASS is claimed here. The supplied files
have been static-reviewed and delimiter/architecture checked.
