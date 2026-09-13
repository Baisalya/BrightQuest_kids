# Phase 7+8 Repair v3

Use this when `brightquest_app.dart` already references `learnerStage` and
`NurseryHomeScreen(rootMode: ...)`, but `GameController`,
`ChildProfileSnapshot`, and `NurseryHomeScreen` still expose their old APIs.

That state means the Phase 7+8 overlay was copied, but the in-place production
patch did not complete.

## Apply

Extract this ZIP into the BrightQuest repository root, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\APPLY_AND_VERIFY_PHASE_07_08_V3.ps1
```

The wrapper:

1. runs the UTF-8-safe Dart patcher;
2. verifies eight required source contracts physically exist;
3. formats the affected files;
4. runs `flutter analyze`;
5. fails immediately if any required contract is still absent.

After it reports success, run:

```powershell
flutter test test\learner_stage_persistence_test.dart
flutter test test\nursery_first_class_shell_test.dart
flutter test test\learning_session_continue_test.dart
flutter test test\phase7_8_architecture_test.dart
flutter test
```

Do not use the original `APPLY_PHASE_07_08.ps1`.
