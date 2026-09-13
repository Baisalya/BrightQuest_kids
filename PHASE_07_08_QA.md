# Phase 7+8 QA

## Required baseline

Apply this package only after the locally-qualified Phase 3+4 and Phase 5+6
changes.

The user's latest Phase 5+6 gate before this phase was:

- `flutter analyze` — **No issues found**
- `game_session_resume_safety_test.dart` — **24/24 passed**
- full suite — **433 passed, 2 skipped, no failures**
- mission balance audit — 0 blockers, 0 high, 3 medium duplicate-content
  findings

## Apply order

1. Extract `BrightQuest_Phase7_8_Modified_Files.zip` into the repository root
   and allow the included full files to replace their Phase 3–6 versions.
2. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\APPLY_PHASE_07_08.ps1
```

The script validates every expected old source block before writing any of its
six large-file changes.

## Format

```powershell
dart format `
  lib\app\brightquest_app.dart `
  lib\core\models\learner_stage.dart `
  lib\core\models\progress_models.dart `
  lib\core\session\learning_session_exit.dart `
  lib\core\state\game_controller.dart `
  lib\features\games\game_router.dart `
  lib\features\home\home_screen.dart `
  lib\features\nursery\nursery_home_screen.dart `
  lib\features\parent\parent_dashboard_screen.dart `
  lib\widgets\bright_widgets.dart `
  test\learner_stage_persistence_test.dart `
  test\nursery_first_class_shell_test.dart `
  test\learning_session_continue_test.dart `
  test\phase7_8_architecture_test.dart `
  test\phase5_6_home_worlds_architecture_test.dart
```

## Analyze and targeted tests

```powershell
flutter analyze

flutter test test\learner_stage_persistence_test.dart
flutter test test\nursery_first_class_shell_test.dart
flutter test test\learning_session_continue_test.dart
flutter test test\phase7_8_architecture_test.dart
flutter test test\phase5_6_home_worlds_architecture_test.dart

flutter test test\game_session_resume_safety_test.dart
flutter test test\nursery_calm_home_test.dart
flutter test test\nursery_simple_game_flow_test.dart
flutter test test\adaptive_ui_architecture_test.dart
flutter test test\widget_smoke_test.dart
```

## Full gate

```powershell
flutter test
```

## Expected invariants

- Existing legacy/default profiles boot in School mode.
- Nursery profiles boot directly into Nursery Learning Garden.
- Nursery root has no Today/Worlds/Journey/Me school navigation.
- Nursery root still reaches the existing Grown-up/PIN boundary.
- Switching Nursery → School restores the school shell without changing the
  preserved selected Class 3/4/5 value.
- School Home has no Nursery shortcut after Phase 8.
- A first-clear Learning World result has a primary Continue button.
- Continue returns the exact next level ID already determined by the reward
  presentation and the router validates it before launch.
- Replay remains available but secondary after a clear.
- Failed missions still offer Try Again.
- GameController reward/session persistence remains authoritative.

## Runtime status of this artifact environment

Flutter/Dart are not installed in the artifact environment, so this package
does **not** claim a local `flutter analyze` or `flutter test` pass. Static
artifact checks and PowerShell patch-contract checks are included; the commands
above are the authoritative local qualification gate.
