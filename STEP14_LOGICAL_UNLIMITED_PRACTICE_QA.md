# BrightQuest Kids — Step 14 Logical Unlimited Practice QA

## Baseline

Implemented on top of `BrightQuest_Kids_Step13_ShortWide_Layout_Hotfix_Full.zip` supplied by the user. Step 13 short-wide layout behavior, shared anti-repeat memory, Endless Practice, rewards/progress, save schemas and Windows narration safety are retained.

## Product rule

BrightQuest now follows one explicit practice rule:

- if a skill can be parameterised from an already-authored rule without inventing facts, provide rolling generated practice;
- if an existing audited World-game generator produces content for the exact requested competency, Skill Studio may reuse that generated content;
- if a skill is language-, EVS-, social- or knowledge-heavy and safe generation is not established, do not fabricate new questions. Rotate the reviewed/authored pool and return older items only as spaced review;
- Discovery Check remains a short diagnostic, not an endless game. Completed checks can be run again with recent-item and visible-prompt suppression when alternatives exist.

## Dedicated Skill Studio generated Maths coverage

The following 16 Skill Studio-only Maths competencies now have deterministic parameterised practice:

### Class 3

- `c3_math_place_value_999`
- `c3_math_money_bills`
- `c3_math_measurement`
- `c3_math_time_calendar`
- `c3_math_shapes_patterns_data`

### Class 4

- `c4_math_place_value_10000`
- `c4_math_measure_perimeter`
- `c4_math_time_money`
- `c4_math_geometry_symmetry`
- `c4_math_data_patterns`

### Class 5

- `c5_math_large_numbers_100000`
- `c5_math_estimation`
- `c5_math_factors_multiples`
- `c5_math_geometry_angles_symmetry`
- `c5_math_measure_conversion_volume`
- `c5_math_data`

Generated items are deterministic, rehydratable by ID, class/competency scoped, use the existing `ContentActivity` / response-evaluator boundary, and remain `needsReview`.

## Anti-repeat behavior

- Direct Skill Studio still shows four response activities per set.
- Fresh visible fingerprints are selected ahead of recent wording.
- When a finite pool is exhausted, the entire previous four-response set is protected as the immediate no-repeat boundary when alternatives exist.
- Generated-safe competencies receive a rolling candidate window, allowing continued practice with new values/contexts rather than replaying the same four authored items.
- Shared class-wide visible-content history still prevents accidental duplicate wording across World games, Endless Practice, Skill Studio and Discovery surfaces.

## Discovery Check

- Each check remains capped at 12 questions.
- An unfinished check resumes the exact persisted item list.
- A restarted/completed re-check builds a new recent-aware 12-item list when alternatives exist.
- The completed screen now exposes `Check my skills again` and explains that re-checks stay short and rotate recently used questions.
- Diagnostic evidence remains class-specific and continues to feed the existing learning evidence engine.

## Persistence / release boundaries

- No PlayerSnapshot schema bump.
- No MissionExposureMemory schema bump.
- No GameSessionCheckpoint or MissionRunPlan schema changes.
- No curriculum JSON was changed.
- No generated language/EVS facts were introduced.
- No reward, star, coin or unlock policy changed.
- No Windows narration or accessibility crash-isolation files were changed.

## Automated gate

Run from the project root on a Flutter-enabled machine:

```powershell
.\tool\qa\run_step14.ps1
```

The gate executes:

1. `flutter analyze`
2. Step 14 generated-practice + Discovery tests
3. Step 13 adaptive non-repeat regression
4. Skill Studio UI regression
5. Endless Practice regression
6. Step 9 production regression
7. Step 8 focused balance/content regression
8. Step 8 128-seed scale audit
9. complete `flutter test`

Expected final marker:

```text
STEP 14 LOGICAL UNLIMITED PRACTICE RELEASE GATE: PASS
```

## Truthful wording

“Unlimited practice” means the child may continue taking practice sessions without a fixed completion cap. It does **not** mean every knowledge-heavy skill has infinitely many unique reviewed questions. Safe generated Maths/game-backed skills extend the visible bank; finite skills use intentional spaced review.
