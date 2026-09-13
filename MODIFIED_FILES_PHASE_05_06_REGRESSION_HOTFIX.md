# Modified Files — Phase 5+6 Regression Hotfix

- `lib/features/home/home_screen.dart`
  - removes the unused `bright_adaptive.dart` import.
- `test/game_session_resume_safety_test.dart`
  - modified by the included PowerShell patcher.
  - updates old Adventures-owned resume assertions to the Phase 5+6 ownership:
    Today/Home + LearningWorldScreen.
- `APPLY_PHASE_05_06_REGRESSION_HOTFIX.ps1`
  - fail-closed local patcher.
- `PHASE_05_06_REGRESSION_HOTFIX.patch`
  - readable unified diff.
- `docs/PHASE_05_06_REGRESSION_HOTFIX_QA.md`
  - root-cause and qualification notes.
