# Endless Practice

Endless Practice is a post-progression practice mode for the eight generated Learning World game families in Classes 3, 4 and 5.

## Product contract

- The canonical curriculum remains three levels per game: Practice, Challenge and Mastery.
- Endless Practice unlocks only after all three canonical levels for that game are complete.
- Each Endless Practice round contains exactly 10 independent game missions and no separate Training allocation.
- Finishing an Endless Practice round never unlocks curriculum levels and never awards curriculum stars or a first-clear bonus.
- A passing practice round keeps the same small repeat reward used by ordinary replay practice.
- Interrupted rounds resume the exact persisted mission plan. A completed round is replaced by a fresh round when the child explicitly starts Endless Practice again.
- Completed rounds feed the existing bounded per-class anti-repeat memory and adaptive selection evidence.

## Variety model

Endless Practice uses deterministic generated content only. It opens a larger seed space than the 12 generated variants used by the canonical 72-level release audit. The original 12-variant bank remains unchanged for the normal progression and its Step 8 quality gate.

Math and Coding can provide very large procedural variation. Fraction, Grammar, Story, Science, Map and Recycling use bounded curriculum-safe concept structures with deterministic parameter/context rotation. "Endless" therefore means unlimited practice rounds, not a promise of infinitely many unique educational concepts. Recent visible missions are suppressed whenever enough fresh valid alternatives exist.

## Release gate

Run on Windows:

```powershell
.\tool\qa\run_endless_practice.ps1
```

The gate runs static analysis, Endless Practice tests, Step 9 production regression, Step 8 quality regression and 128-seed audit, then the full Flutter test suite. Real Android/Windows lifecycle, audio, resize and store qualification remain manual release requirements.
