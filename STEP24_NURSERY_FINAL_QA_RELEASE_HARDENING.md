# Step 24 / Nursery Step 10 — Final QA, Regression & Release Hardening

## Purpose

Step 10 closes the Nursery implementation sequence with regression/release hardening. It intentionally adds no new lesson content, interaction type, scoring rule, save field, dependency, backend, or child-facing feature.

The QAFix also removes one dead local variable in `nursery_lesson_screen.dart` reported by `flutter analyze`; this is analyzer-only cleanup and does not change child-facing or learning behavior.

## Changes

- Added `test/nursery_final_release_gate_test.dart` as a cross-step release contract.
- Added Windows/Linux final Nursery QA runners.
- Added `docs/NURSERY_FINAL_RELEASE_CHECKLIST.md`.
- Replaced the warning-producing `scrollUntilVisible` helper in `nursery_simple_game_flow_test.dart` with a deterministic bounded `ScrollPosition` advance. This also handles the Alphabet world's lazy-built Picture Book section without calling `ensureVisible` before the element exists; child-facing assertions are unchanged.
- QAFix: removed the unused local `controller = BrightQuestScope.of(context)` from `_buildTeachingPage`; no consumer or side effect depended on the local.

## Final release-gate coverage

The new final gate verifies:

- stable 4-domain / 32-skill / 132-activity / 26-letter topology;
- stable one-time ₹299 Nursery product contract while external paid eligibility remains fail-closed;
- unique skill/activity IDs and valid free-sample references;
- Study → Guided Play → Independent Game reachability for every skill;
- every authored response rule evaluates its own canonical correct response;
- every generated practice item is deterministic, semantic, and self-evaluable across 64 seeds per skill;
- 208 local PNG assets stay within file/dimension/aggregate budgets;
- Nursery presentation contains no periodic/repeating animation loops;
- motion keeps OS reduced-motion and Windows safety boundaries;
- image decoding remains bounded at 128×128.

## Baseline

Step 10 starts from Step 23 / Nursery Step 9 implementation, itself based on the user-qualified Step 8 QAFix baseline (`+412 ~2: All other tests passed`). Step 9 runtime qualification had not yet been supplied when Step 10 was requested, so the final local runner intentionally includes Step 9 motion tests plus the full suite.

## Qualification

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tool/qa/run_nursery_final.ps1
```

The archive-preparation environment does not contain Flutter/Dart, so successful local execution remains the runtime release gate.
