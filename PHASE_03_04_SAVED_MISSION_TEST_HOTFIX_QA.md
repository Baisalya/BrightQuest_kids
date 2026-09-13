# Phase 3+4 Saved Mission Test Hotfix

## Root cause

`test/saved_missions_responsive_ui_test.dart` used fixed `updatedAtIso` values from
2026-08-23. `GameController._discardInvalidSessionCheckpoints()` intentionally
drops resumable checkpoints older than 14 days. Running the suite on 2026-09-10
therefore discarded all three fixture sessions before the widgets were built.

This produced two downstream failures:
- `Recent saved mission` was absent.
- `saved_missions_in_game_math_market` was absent, causing `scrollUntilVisible`
  to throw `Bad state: No element`.

## Fix

Only the test fixture is changed:
- Saved checkpoints are generated relative to `DateTime.now().toUtc()`.
- Ordering remains deterministic: latest, older Math, older Story.
- `startedAtIso` is derived five minutes before each update.
- The fixture now asserts that all three sessions survive load and that the
  expected latest checkpoint sorts first.

Production session-retention behavior is unchanged.

## Run

```powershell
dart format test\saved_missions_responsive_ui_test.dart
flutter test test\saved_missions_responsive_ui_test.dart
flutter test
```

Expected targeted result: both saved-mission tests pass.
