# Step 13 — Adaptive Non-Repeat & Infinite Practice Engine

## Goal

Step 13 makes child-visible freshness one shared selection concern across Learning Worlds, Endless Practice, Class Skill Studio and restarted Discovery Checks without creating a second mastery system or changing authored correctness rules.

## What “infinite practice” means

BrightQuest can provide an unlimited sequence of practice **sessions**. It does **not** claim infinitely many unique curriculum facts, questions or teacher-authored examples.

When a valid content pool is large enough, recent visible questions are suppressed. When a finite authored pool is exhausted, the least-risk recent material returns as intentional review instead of pretending that recycled content is new.

## Shared freshness signature

`mission_content_signature.dart` provides one normalized prompt fingerprint and one structural archetype identity. The same visible wording is therefore recognized even if it is reachable through a different activity ID or practice surface.

The profile-owned `MissionExposureMemory` remains schema v1 and backward readable. New optional fields record:

- child-visible content fingerprint;
- topic ID;
- competency ID;
- difficulty.

Old v1 records load with those fields empty. No authoritative progress, reward, mastery, entitlement or save schema is replaced.

## Learning World and Endless Practice

The mission planner now prioritizes:

1. unseen visible prompt fingerprints;
2. unseen stable activity identity;
3. existing adaptive weak-skill / spaced-review demand;
4. topic and competency recency;
5. archetype and mechanic recency;
6. within-run balance and deterministic tie breaking.

Endless Practice uses persisted prompt fingerprints directly and retains the legacy activity-key reconstruction path for older exposure records.

## Class Skill Studio

A new `SkillStudioPracticePlanner` selects only activities that already belong to the selected class and competency. It does not infer cross-class curriculum mappings.

Each dedicated Class 3–5 competency currently has four authored Skill Studio response activities. Step 13 uses those four as one fresh set:

- guided try;
- independent practice;
- transfer;
- exit check.

The worked example remains teaching-only so a single set does not need to reuse one of the four response questions.

Only questions actually shown to the child are added to exposure memory. Reopening a partially viewed competency therefore suppresses what the child really saw, not every item that merely existed in the plan.

After all four authored response questions have been seen, the UI states that the fresh pool is exhausted and returns material as spaced review. The immediately previous question remains a hard boundary and the finite pool is deterministically reshuffled instead of replaying one identical round order forever.

Mastery eligibility remains authored data. Activities marked `masteryEligible: false` remain practice-only.

## Discovery Check

An in-progress Discovery Check resumes its persisted item list exactly, preserving crash/session continuity.

A new or restarted Discovery Check uses:

- recent diagnostic item IDs; and
- class-wide visible-content fingerprints

to select fresh scorable alternatives per competency where those alternatives exist. Diagnostic answers are then added to the same advisory exposure memory so later surfaces can avoid immediately showing the same visible wording.

## Class isolation

Exposure memory remains split by class. Class 3 history cannot suppress or reorder Class 4/5 content. Generated World content also remains governed by the existing class/tier-specific generator contracts and Step 8 cross-class/cross-tier quality gates.

## Persistence and migration safety

- `PlayerSnapshot` schema is unchanged.
- `MissionExposureMemory.schemaVersion` stays at 1.
- new record fields are optional and old records remain readable;
- no correct answer, scoring payload or authored content is duplicated into exposure memory;
- anti-repeat memory remains advisory and bounded;
- profile and class isolation remain authoritative.

## QA gates

Run:

```powershell
tool\\qa\\run_step13.ps1
```

or:

```bash
./tool/qa/run_step13.sh
```

The gate includes formatting, focused Step 13 regressions, persistent rotation, Endless Practice, Step 8 balance/content-quality contracts, Skill Studio regressions, full Flutter tests and static analysis.

## Explicit non-goals

Step 13 does not:

- manufacture unreviewed curriculum mappings between unrelated competencies;
- claim every Skill Studio competency has unlimited unique authored questions;
- change correctness, pass thresholds, rewards, entitlements or mastery rules;
- remove intentional delayed/spaced review;
- mark teacher, child-pilot, store, privacy or real-device qualification as complete.

A later content-expansion phase can add larger reviewed/generative competency banks. Step 13 provides the shared history and selection architecture those banks can safely plug into.
