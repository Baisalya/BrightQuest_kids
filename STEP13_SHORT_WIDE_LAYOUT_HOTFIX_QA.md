# Step 13 Short-Wide Layout Hotfix QA

Date: 2026-08-23

## User-reported validation

- `dart format lib test tool`: completed locally; 227 files scanned, 51 formatted.
- `flutter analyze`: **No issues found**.
- Full `flutter test`: 2 widget failures remained:
  1. `learning_audio_accessibility_test.dart` — interactive caption response answer center at `dy=771.2` exceeded the 760px test viewport.
  2. `phase_e_skill_studio_ui_test.dart` — the same answer was off-screen, so the tap missed and expected positive feedback never appeared.
- Step 8 balance audit reported only 3 MEDIUM deduplication findings with `blockers=0 high=0`; those were not test failures.

## Root cause

Step 13 added the Skill Studio fresh/spaced-practice banner above the lesson session controls. On a 900x760 interactive viewport the full two-line banner consumed enough vertical space to push the first response control below the root render surface. Both failures shared this geometry regression.

## Production fix

`lib/features/learning/lesson_flow_screen.dart`

- Short-wide interactive lessons now use 12px vertical page padding instead of 20px while retaining 20px horizontal padding.
- `_SkillStudioFreshPracticeBanner` now supports a compact mode.
- In short-wide interactive mode the banner renders as a one-line 18px-icon status strip rather than the full explanation card.
- The complete `selectionReason` remains exposed through `Semantics`, so the compact visual treatment does not remove accessibility meaning.
- Full-height/mobile/desktop lesson layouts continue to render the original detailed banner.

## Safety boundaries

- No curriculum content changed.
- No answer/evaluation/mastery rules changed.
- No mission exposure history or save schema changed.
- No test expectation was weakened.
- No forced `ensureVisible()` or test-only scrolling workaround was introduced.

## Local verification requested

```powershell
dart format lib test tool
flutter analyze
flutter test test/learning_audio_accessibility_test.dart --plain-name "Step 11 visible narration UI interactive captions do not push short-wide response controls off-screen"
flutter test test/phase_e_skill_studio_ui_test.dart --plain-name "practice-only constructed response never records mastery evidence"
flutter test
```
