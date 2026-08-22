# BrightQuest Teaching Correctness QA — Phase A

## Purpose

Phase A adds a deterministic correctness framework that tests learning content as teaching material, not only as UI or code. It is designed to catch cases where an activity can technically score an answer but still teach a child something wrong, show a mismatched explanation, accept a distractor, generate impossible choices, or attach practice to the wrong skill.

This framework does **not** replace qualified teacher review or supervised child pilots. It provides repeatable automated evidence that makes those reviews safer and more focused.

## Added framework

### `lib/core/qa/teaching_correctness_audit.dart`

The shared audit engine checks:

- authored Nursery answers are accepted by the evaluator;
- authored distractors / known-wrong responses are rejected;
- choice IDs and labels are unique and contain the scored answer;
- the learner-facing explanation identifies the answer that was actually scored;
- prompt-derived facts such as `SUN -> S`, next-number sequences, missing-number sequences, and simple numeral addition are recomputed independently rather than trusted from authored metadata;
- phonics-eligible discovery words actually begin with the associated letter;
- generated Nursery practice is deterministic for a skill + seed;
- generated choices are unique and include the answer;
- generated distractors are rejected;
- generated practice remains linked to the requested skill;
- generated beginning-sound, word-picture, number-recognition, missing-number and addition items are independently checked;
- Classes 3–5 authored activities accept their stored correct response and reject authored distractors;
- Classes 3–5 authored arithmetic is independently recomputed (including comma-formatted numbers and multiplication-before-add/subtract items);
- authored fraction slice counts are recomputed from numerator/denominator/total slices;
- authored story word order, grammar-part scoring, recycling payloads, science/map answer payloads, and experiment reaction IDs are checked for scoring/content drift;
- coding-maze authored content is solved by a bounded deterministic search so the evaluator can be checked against an actually reachable solution;
- Classes 3–5 deterministic arithmetic, fractions, grammar and map-direction generators are recomputed independently.

A finding has one of four severities: `blocker`, `high`, `medium`, or `low`. `blocker` and `high` findings make the command exit as a release-blocking failure.

## Content contract validation

`tool/qa/validate_content_contracts.dart` loads the complete repository content contract and therefore exercises the existing Classes 3–5 schema/curriculum validators. It also checks the Nursery schema metadata against the actual expanded pack.

The current Nursery v1 contract requires:

- 26 A–Z associations;
- at least 8 authored discovery examples for each letter;
- at least 200 unique local Nursery picture-card assets in total;
- every referenced asset to exist;
- no duplicate picture-card asset path.

The Nursery schema metadata was updated to match the actual 208-card pack, and the runtime Nursery validator now enforces the same 200-card minimum instead of the old 78-card threshold.

## Simulation commands

### Full Phase A on Windows

```powershell
.\tool\qa\run_phase_a.ps1
```

### Individual commands

```powershell
dart run tool/qa/validate_content_contracts.dart
dart run tool/qa/simulate_nursery_letters.dart --seeds 256
dart run tool/qa/simulate_nursery_numbers.dart --seeds 256
dart run tool/qa/phase_a_teaching_audit.dart --seeds 128
flutter test test/phase_a_teaching_correctness_audit_test.dart test/phase_a_feedback_alignment_test.dart
```

The seed counts are deliberately bounded and deterministic. They can be increased for deeper CI sweeps, for example:

```powershell
dart run tool/qa/phase_a_teaching_audit.dart --seeds 1000
```

The tools reject seed counts outside `1..5000` so an accidental command cannot create an unbounded simulation.

## Regression proof tests

`test/phase_a_teaching_correctness_audit_test.dart` includes negative-control tests proving that the framework itself detects errors. It deliberately creates temporary in-memory broken activities such as:

- a `SUN` first-letter question incorrectly scored as `C`;
- `1 + 1` incorrectly scored as `3`;
- a Class 5 `1,250 - 675` activity deliberately rescored as `576`.

Those temporary fixtures are never written into production content; the test passes only when the auditor flags them.

## Phase A release gate

Phase A is considered automated-green only when all of the following pass:

```powershell
dart format lib test tool
flutter analyze
flutter test
dart run tool/qa/validate_content_contracts.dart
dart run tool/qa/simulate_nursery_letters.dart --seeds 256
dart run tool/qa/simulate_nursery_numbers.dart --seeds 256
dart run tool/qa/phase_a_teaching_audit.dart --seeds 128
```


Automated green status does **not** mean teacher approval, child-pilot approval, store readiness, or device certification.
