# Phase 9 + Phase 10 — Child progress, parent analytics and reward separation

## Goal

Phase 9+10 gives each surface one clear job:

```text
Today   -> What should I do next?
Worlds  -> What can I explore?
Journey -> How far have I travelled?
Me      -> Who am I + comfort + where are my rewards?
Rewards -> What have I earned / what look do I want?
Parents -> What does the learning evidence actually show?
```

This is a presentation and ownership refactor. Reward balances, achievement
unlock rules, learning evidence, mastery calculations and persistence stay
authoritative in the existing controller/engines.

## Phase 9 — child progress simplification

### Journey replaces analytical Progress

The child-facing screen is now `My Journey`.

It keeps:
- class journey progress;
- quests explored;
- stars collected;
- per-world progress;
- qualitative states such as `Getting started`, `Growing strong`,
  `Almost there`, and `World complete`.

It removes from child-facing Journey:
- accuracy percentages;
- mastery percentages;
- correct/attempt counts;
- hint counts;
- adaptive difficulty numbers;
- weakest-topic analysis;
- `Adventure mastery` terminology.

Those signals remain useful, but they are adult interpretation data rather than
child navigation data.

### Parent analytics owns diagnostics

`ParentLearningReportScreen` now has separate School and Nursery reports.

School parents get:
- weekly learning summary;
- per-adventure mastery;
- accuracy;
- attempts/correct answers;
- hints;
- current adaptive challenge level;
- low-evidence/focus topics;
- competency evidence;
- long-term confidence/reason;
- review dates;
- applied-mission evidence.

Nursery parents get only Nursery evidence:
- activity evidence count;
- review-ready count;
- domain/skill mastery states;
- clean independent and transfer evidence;
- review dates.

The preserved School class underneath a Nursery profile is not presented as
Nursery analytics.

## Phase 10 — reward layer simplification

### Me becomes identity + preferences + one reward doorway

`My Space` keeps:
- child identity/avatar;
- simple quest progress;
- accessibility/comfort controls;
- a single `My rewards` card.

It no longer duplicates:
- a full achievement grid;
- a cosmetics-owned section;
- streak and XP metric chips.

### Rewards Room becomes the single detailed reward owner

The Rewards Room now contains:
- `My loadout`;
- `Choose a look`;
- `Celebrations`.

`Celebrations` collapses:
- World trophies;
- Achievement badges.

The cosmetic economy is unchanged:
- ownership remains per child;
- equipped look remains per game;
- buying uses authoritative catalog pricing;
- equip/unequip remains free;
- cosmetics never alter answers, stars or learning progress.

The Rewards Room no longer repeats class-path progress. That belongs to Journey.

### Home stays learning-focused

The small Rewards Room shortcut is removed from Home. Reward browsing now starts
from `Me -> My rewards`, keeping Today focused on the next learning action.

## Preserved invariants

This phase does not modify:
- `GameController` reward/economy logic;
- `ChildProfileSnapshot` persistence;
- XP/star/coin award rules;
- achievement unlock rules;
- cosmetic catalog IDs/prices;
- entitlement logic;
- Parent PIN;
- game-session checkpoint/resume;
- Phase 7 Continue-to-next flow;
- Nursery stage persistence/evidence;
- curriculum IDs or content.
