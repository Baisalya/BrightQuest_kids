# Phase 7 + Phase 8 — Unified learning-session flow + Nursery first-class mode

## Phase goal

Phase 7+8 removes two remaining learner-flow breaks:

1. A school Learning World mission currently ends at a result card whose only
   strong action is Replay/Try Again, even when the next mission has just been
   unlocked.
2. Nursery is a polished learning experience but is still reached as a
   transitional shortcut instead of being the active learner's real root mode.

The refactor makes both flows explicit without changing curriculum IDs,
correctness rules, reward authority, entitlement boundaries, or the existing
safe checkpoint engine.

---

## Phase 7 — unified school learning session

Target:

```text
Today / World
   ↓
Teach
   ↓
Guided / independent learning
   ↓
Main game
   ↓
Result + reward
   ↓
CONTINUE
   ↓
Exact next unlocked mission
```

### Shared result contract

A new `LearningSessionExit` object is the typed route result between the shared
mission result surface and `game_router.dart`.

It carries either:

- `continueNext` plus the exact next `LearningLevel.id`; or
- `backToWorld`.

The result card never guesses a level. It uses the exact `nextMissionPlan`
already produced by `AdventureRewardEngine`.

### Result action hierarchy

For a cleared curriculum mission:

1. **Continue** is the primary button when an exact next mission was unlocked.
2. **Back to World(s)** is the primary button when there is no exact next
   mission.
3. Replay remains available as a secondary outlined action.

For a failed mission:

- **Try Again** remains the primary action.

Quick Play / Endless Practice results remain generic and do not inherit the
curriculum Continue contract.

### Router safety

`game_router.dart` validates the returned next-level ID before opening it:

- the ID must still resolve through `learningLevelById`;
- it must belong to the active selected class;
- it must be unlocked by the authoritative `GameController`.

The current result checkpoint is still discarded only after the game route
closes, preserving the existing safe-completion lifecycle.

No individual game screen receives custom next-level logic. All eight main games
inherit the shared result behavior automatically.

---

## Phase 8 — Nursery as a first-class learner stage

### Explicit persisted stage

Each `ChildProfileSnapshot` now stores:

```text
learnerStage = nursery | school
```

Nursery is **not** encoded as Class 0, Class -1, or another fake class value.

`selectedClass` remains valid 3–5 data even on a Nursery profile. It is simply
the preserved school class that will be used if the parent later changes that
profile back to School mode.

### Backward compatibility

`learnerStage` is an additive optional profile field.

Profiles saved before Phase 8 have no such field and deterministically restore
as `LearnerStage.school`, so existing Class 3/4/5 users retain their previous
experience and progress.

The PlayerSnapshot schema number is intentionally not changed in this phase:
the new field is additive and has a safe default. Full migration/release
certification remains Phase 13+14 work.

### Root shell ownership

`MainShell` now branches on the active profile's persisted learner stage:

- **Nursery** → `NurseryHomeScreen` is the actual root learner experience.
- **School** → existing Today / Worlds / Journey / Me shell.

The temporary Nursery shortcut is removed from School Home.

Nursery root mode:

- has no fake school navigation;
- has no back button to an unrelated School Home;
- preserves the calm one-primary-action Nursery design;
- exposes one `Grown-up area` utility that still routes through the existing
  Parent PIN gate.

### Parent configuration

The Parent Dashboard now separates:

- **Learning stage:** Nursery / School
- **School class:** Class 3 / 4 / 5, only when School is active.

New child profiles can be created directly as Nursery profiles. Profile chips
show `Nursery` rather than a misleading `C3` label for Nursery learners.

When a Nursery profile is active, the Parent Dashboard also suppresses the
preserved School adventure map, School focus areas/class-pack section and
School daily challenges. It shows Nursery evidence/review counts instead, so
the underlying remembered School class never leaks into the Nursery-facing
parent summary.

### Profile/session preservation

Changing a learner stage does not delete school sessions or Nursery evidence.

- School session foreground selection is cleared when the stage changes so a
  hidden school route cannot remain active in Nursery.
- Saved school checkpoints remain persisted and can be resumed after switching
  back to School.
- Nursery review state is refreshed when entering Nursery or switching child
  profiles.
- Reset progress preserves the selected learner stage while resetting the
  active child's learning data, matching the existing reset semantics.

---

## Explicit non-goals

This phase does **not**:

- invent Class 1, Class 2, or Class 6 curriculum packs;
- change current Class 3/4/5 curriculum IDs;
- merge Nursery data into school mastery structures;
- alter game correctness rules, pass ratios, XP, stars, coins, or achievements;
- weaken 14-day session retention;
- change entitlement or Parent PIN security;
- redesign child/parent analytics (Phase 9+10);
- expose technical schema or adaptive-engine labels to Nursery learners.
