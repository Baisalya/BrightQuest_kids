# Phase 11+12 QA

## Required baseline

Apply after the qualified Phase 9+10 state:

- `flutter analyze` — No issues found
- Phase 9+10 release gate — PASSED
- full suite — 449 passed, 2 skipped, no failures
- mission audit — 0 blockers, 0 high, 3 medium duplicate-content findings

## Apply

Extract `BrightQuest_Phase11_12_Modified_Files.zip` into the BrightQuest
repository root and replace matching full files.

Then run the release gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase11_12_release_gate.ps1
```

The gate first runs the UTF-8-safe in-place patcher for the eight large/existing
production files, then formats, analyzes, runs focused regressions and finally
runs the full test suite.

## Manual equivalent

```powershell
dart run .\tool\apply_phase11_12_hardening.dart
dart format lib test
flutter analyze

flutter test test\learner_capability_boundary_test.dart
flutter test test\learner_shell_policy_test.dart
flutter test test\bright_accessibility_layout_test.dart
flutter test test\phase11_12_accessibility_ui_test.dart
flutter test test\phase11_12_architecture_test.dart
flutter test test\adaptive_ui_architecture_test.dart

flutter test test\phase9_10_architecture_test.dart
flutter test test\child_progress_reward_ui_test.dart
flutter test test\parent_learning_report_separation_test.dart
flutter test test\cosmetic_equipment_ui_test.dart
flutter test test\learner_stage_persistence_test.dart
flutter test test\nursery_first_class_shell_test.dart
flutter test test\learning_session_continue_test.dart
flutter test test\game_session_resume_safety_test.dart
flutter test test\audio_experience_test.dart
flutter test test\step12_production_hardening_test.dart
flutter test test\widget_smoke_test.dart

flutter test
```

## Expected capability results

- available learner options are Nursery, Class 3, Class 4 and Class 5;
- Class 1, 2 and 6 are recognized but `notShipped`;
- Class 1/2/6 are absent from class selectors and class-pack loops;
- controller does not switch to Class 1/2/6;
- controller does not create a profile for Class 1/2/6;
- unsupported School class sessions are rejected during restore validation;
- purchase attempts for Class 1/2/6 fail before store access;
- no Class 1/2/6 content is generated.

## Expected accessibility results

- minimum interaction target policy is 48dp on every viewport class;
- Back has an explicit semantic label;
- compact/dense narration read/stop buttons are 48dp;
- large text causes hero/action layouts to stack earlier;
- adaptive grids reduce columns at large text;
- Home, Journey, Me, Nursery root and Rewards Room remain overflow-free in the
  targeted 2x/short-window tests.

## Runtime status of this artifact environment

Flutter/Dart are not installed here, so this package does not claim local
`flutter analyze` or runtime test PASS. The user's local gate is authoritative.
