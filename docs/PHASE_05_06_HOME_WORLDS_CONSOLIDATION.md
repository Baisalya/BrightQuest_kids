# Phase 5 + Phase 6 — Home simplification + Worlds/Adventures consolidation

## Goal

Reduce BrightQuest from a dashboard of competing learning entry points to a
clear learning-game hierarchy:

1. **Today** decides the best next learning action.
2. **Worlds** is for deliberate subject exploration.
3. **Journey / Me** remain the shell-owned progress/profile destinations from
   Phase 3+4.
4. Parent controls remain outside learner navigation behind the existing gate.

## Home ownership

Home now has exactly one visually dominant learning action. The action is chosen
by a pure policy boundary in `home_primary_action.dart`:

1. Resume the latest exact saved session.
2. Continue an in-progress starting check, or offer a starting check to a new
   class with no class evidence/progress.
3. Surface due spaced review.
4. Start the next recommended curriculum level.
5. Offer an applied mission after the core path is complete and before applied
   mission evidence exists.
6. Fall back to a short free-practice game.

The Home widget does not expose separate grids for Worlds, Quick Play, Skill
Studio, Discovery Check, Power Review, or Applied Missions.

## Secondary Home content

Two lower-priority areas preserve existing functionality without competing with
the primary action:

- **Your journey** — compact class progress, stars, today's study minutes, plus
  a small Rewards Room utility.
- **Today's wins** — collapsed optional daily challenges so explicit reward
  claiming remains available without becoming the Home hero.

Nursery remains reachable through a compact compatibility bridge until the
dedicated Nursery first-class profile work in Phase 7+8.

## Worlds ownership

`AdventuresScreen` is now exploration-only:

- one small class/world-map context card;
- one grid of learning worlds;
- per-world progress and a small saved indicator.

Removed from the Worlds landing page:

- global recent-saved-mission panel;
- all-saved-missions overlay;
- global Quick Play game grid;
- duplicate class-path hero.

Paused sessions are not deleted. The latest save is surfaced by Today, and all
saved sessions remain grouped in the owning game zone inside
`LearningWorldScreen`.

## Preserved boundaries

No changes are made to:

- `GameController` persistence/schema;
- game session retention/resume rules;
- `game_router.dart`;
- learning/mastery engines;
- content packs or curriculum IDs;
- entitlement behavior;
- Parent PIN logic;
- daily time-limit enforcement;
- Nursery lesson/world implementation;
- Windows semantics crash-isolation;
- Android/Windows adaptive shell policy.

## Deliberately deferred

- Nursery as a first-class persisted learner stage: Phase 7+8.
- Unified lesson/game/result continuation: Phase 7+8.
- Child progress vs parent analytics and reward-layer redesign: Phase 9+10.
- Classes 1, 2 and 6 remain architecture-ready but are not exposed because
  authored packs are absent.
