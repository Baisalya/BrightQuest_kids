# BrightQuest Kids — Step 13 Adaptive Non-Repeat QA

## Baseline

Implemented on top of `BrightQuest_Kids_Saved_Missions_Responsive_UI_Runtime_Fix_Full.zip`, the newest complete BrightQuest project artifact available for this task. Existing Endless Practice, Saved Missions, responsive UI, progress, rewards, parent controls, crash-isolated Windows narration and save/session behavior were retained.

## Implemented

- Shared normalized child-visible content fingerprints.
- Optional topic/competency/difficulty metadata in schema-v1 mission exposure records.
- Class-wide fingerprint history while retaining class isolation.
- World mission selection now prioritizes visible-content freshness before stable ID freshness.
- Existing adaptive weak-skill/spaced-review priority remains active after hard freshness signals.
- Topic and competency recency are soft diversity inputs.
- Endless Practice merges/preserves new freshness metadata and keeps legacy activity-key reconstruction for old records.
- Skill Studio adaptive planner selects only the requested class + competency.
- Skill Studio uses four distinct authored response items for guided/independent/transfer/exit and keeps worked example teaching-only.
- Only Skill Studio questions actually shown are recorded as exposure.
- `Practice another fresh set` continues in the same competency; exhausted finite pools become clearly labelled spaced review rather than being called new content.
- New/restarted Discovery Checks rotate recent diagnostic IDs/visible prompts when alternatives exist; an in-progress diagnostic still resumes the exact persisted list.
- Diagnostic items are added to the shared advisory exposure memory after use.

## Persistence / safety decisions

- `PlayerSnapshot` schema unchanged.
- `MissionExposureMemory.schemaVersion` remains `1`.
- Old v1 exposure records load with new optional fields empty.
- No answer payload, correct answer, reward or mastery score is copied into anti-repeat memory.
- Anti-repeat memory remains bounded and profile-owned; class 3/4/5 histories remain isolated.
- `masteryEligible: false` remains authoritative.

## Static QA completed in this environment

PASS:

- delimiter / lightweight lexical balance on all changed Dart files;
- merge-conflict marker scan;
- `git diff --no-index --check` whitespace validation;
- Class 3/4/5 Skill Studio content invariants: 48 dedicated items per class, 12 competencies per class, 4 authored response items per competency;
- all first 12 diagnostic competency groups in Classes 3/4/5 have more than one scorable authored alternative;
- schema-v1 marker retained;
- source contracts for diagnostic recent history, direct Skill Studio worked-example non-reuse and class-wide exposure history;
- no bundled curriculum/content JSON was modified by Step 13.

## Flutter verification status

The execution container used to prepare this artifact does not contain Flutter or Dart executables, so this report does **not** claim that Flutter analysis/tests passed here.

Run locally from the project root:

```powershell
dart format lib test tool
flutter analyze
flutter test test/step13_adaptive_non_repeat_engine_test.dart
flutter test test/mission_run_step5_persistent_rotation_test.dart test/endless_practice_phase_test.dart
flutter test test/phase_e_skill_studio_ui_test.dart test/phase_e_curriculum_hardening_test.dart
flutter test test/mission_run_step8_balance_quality_test.dart test/mission_step8_balance_quality_audit_test.dart
flutter test
```

Or run:

```powershell
.\tool\qa\run_step13.ps1
```

## Truthful product wording

The code supports unlimited **practice sessions** with bounded recent-content suppression and intentional spaced reuse. Step 13 does not claim infinitely many unique authored Skill Studio questions. Each current Class 3–5 Skill Studio competency has four dedicated authored response questions; expanding that reviewed/generative bank is a separate content-expansion phase.
