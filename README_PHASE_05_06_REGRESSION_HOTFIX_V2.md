# Phase 5+6 Regression Hotfix v2

This replaces the previous PowerShell patcher.

## Why v1 failed

PowerShell variable names are case-insensitive. `$home` therefore collided with
the built-in read-only `$HOME` variable and stopped execution before the Step 10
test file could be patched.

## v2 fix

- Uses `$HomeText` and `$TestText` instead of `$home`.
- Removes the already-reported unused `bright_adaptive.dart` import if present.
- Migrates the old Step 10 static source assertion from:
  `AdventuresScreen owns resume/discard`
  to:
  `Today/Home owns latest resume + LearningWorldScreen owns per-game resume/discard`.
- Fails closed if neither the old nor new block can be found.

## Run from repository root

```powershell
powershell -ExecutionPolicy Bypass -File .\APPLY_PHASE_05_06_REGRESSION_HOTFIX_V2.ps1
dart format lib\features\home\home_screen.dart test\game_session_resume_safety_test.dart
flutter analyze
flutter test test\game_session_resume_safety_test.dart
flutter test
```
