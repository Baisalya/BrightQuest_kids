# Phase 5+6 Regression Hotfix

## Local results that triggered this hotfix

The focused Phase 5+6 suites passed. The remaining issues were:

1. `flutter analyze` reported one unused import in
   `lib/features/home/home_screen.dart`.
2. The full suite failed in `game_session_resume_safety_test.dart` because the
   Step 10 static source contract still required `AdventuresScreen` itself to
   call `resumeGameSession` and `discardGameSession`.

That ownership is intentionally obsolete after Phase 5+6.

## Correct ownership

- Today/Home surfaces and resumes the latest saved session.
- Learning Worlds landing is exploration-only and only shows saved-state hints.
- LearningWorldScreen owns per-game resume/discard controls.
- game_router.dart continues to own the actual resume and safe-completion logic.

## Apply

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\APPLY_PHASE_05_06_REGRESSION_HOTFIX.ps1
```

The PowerShell patcher is fail-closed: if the expected old Step 10 block is not
present, it refuses to modify an unknown test state.

## Qualify

```powershell
dart format lib\features\home\home_screen.dart test\game_session_resume_safety_test.dart
flutter analyze
flutter test test\game_session_resume_safety_test.dart
flutter test
```

No GameController, session retention, persistence, game router, entitlement,
Nursery, or Parent PIN production behavior is changed.
