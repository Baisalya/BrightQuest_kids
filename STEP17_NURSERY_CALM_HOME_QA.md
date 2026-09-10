# Step 17 / Nursery Step 3 — Calm Home QA

## Scope

Step 3 restructures only the Nursery landing experience and its presentation planning boundary. It keeps the existing Nursery content pack, skill/activity IDs, evidence, mastery, review scheduling, save format, TTS service and Class 3–5 experiences unchanged.

## Home invariants

- The landing screen exposes one dominant recommended play action.
- Recommendation priority is due review, then most-recently played non-secure skill, then a new skill, then replay after all skills are secure.
- Exactly four Nursery world destinations remain visible on the landing screen.
- The due-review queue is not rendered as many separate home buttons.
- The A–Z picture book is removed from the landing screen and remains available inside ABC & Sounds.
- World progress is derived from existing Nursery mastery and is not separately persisted.
- Home remains vertically scrollable and uses no fixed-height content stacks.

## Regression commands

Run on the qualified Flutter environment:

```powershell
flutter analyze
flutter test
```

Focused checks:

```powershell
flutter test test/nursery_calm_home_test.dart
flutter test test/nursery_layout_test.dart
flutter test test/nursery_simple_game_flow_test.dart
flutter test test/phase_d_accessibility_polish_test.dart
flutter test test/step12_production_hardening_test.dart
```

## Release note

This workspace cannot execute Flutter/Dart, so no analyzer/test pass is claimed by this artifact. The previous Step 2 responsive baseline was user-verified with analyzer clean and the full test suite passing; Step 3 must be re-qualified with the commands above.
