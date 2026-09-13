# Phase 11 + Phase 12 — Nursery→Class 6 capability boundary + responsive/accessibility hardening

## Phase goal

BrightQuest's learner age/class span must be explicit without pretending that
content exists where it does not.

This build recognizes the product span:

```text
Nursery → Class 1 → Class 2 → Class 3 → Class 4 → Class 5 → Class 6
```

but only exposes learner experiences that actually ship in this build:

```text
AVAILABLE
- Nursery
- Class 3
- Class 4
- Class 5

NOT SHIPPED / NOT EXPOSED
- Class 1
- Class 2
- Class 6
```

Phase 11 codifies that difference as architecture rather than scattered numeric
checks. Phase 12 strengthens layouts for Android large text, phone landscape,
Windows free-form/short windows and minimum interaction targets.

---

## Phase 11 — learner capability boundary

### Central registry

`LearnerCapabilityBoundary` is the single product-capability registry.

It separates:

- `recognizedLearnerSpan`
- `availableLearnerOptions`
- `supportedSchoolClasses`
- `unavailableSchoolClasses`

Class 1, Class 2 and Class 6 exist only as `notShipped` capability records.
They do not receive curriculum, shell navigation, purchases or profile creation.

### Fail-closed School shell

The former unsupported-class fallback learner shell is removed.

`LearnerShellPolicy.forClass()` now requires a supported School class. An
unsupported class does not silently receive Today / Worlds / Journey / Me.

### Controller boundary

The controller keeps the current persistence model but tightens API edges:

- `setClass(1/2/6)` is ignored;
- `createProfile(... classNumber: 1/2/6)` fails closed with an empty ID;
- unsupported entitlement-cache records are ignored;
- resumable sessions carrying an unsupported class are discarded during
  checkpoint validation.

Existing legacy snapshot normalization remains intact, so old/corrupt integer
class values still resolve back inside the already-supported 3–5 persistence
range rather than creating new curriculum state.

### Parent and commercial surfaces

The Parent Dashboard class selectors and Class Packs screen now consume
`LearnerCapabilityBoundary.supportedSchoolClasses`.

The entitlement purchase service rejects unsupported School classes before it
touches the store gateway.

Development pack-lock parsing also uses the same supported-class predicate.

### What Phase 11 does not do

It does not:
- add Class 1 content;
- add Class 2 content;
- add Class 6 content;
- invent product IDs for those classes;
- migrate Nursery into a fake numeric class;
- alter Class 3/4/5 curriculum IDs or progress;
- alter Phase 8 learner-stage persistence.

---

## Phase 12 — responsive/accessibility hardening

### 48dp interactive minimum

`BrightLayoutMetrics.minimumTapTarget` is now 48dp on every viewport class.

Known custom controls below that boundary are hardened:

- shared header Back action: 44 → 48dp;
- side utility navigation: minimum 48dp;
- bottom utility navigation: 40×48 → 48×48dp;
- bottom primary navigation: explicit minimum 48dp;
- compact/dense learning narration read/stop controls: 34/compact → 48dp.

The Back action also receives an explicit `Semantics` button label and Tooltip.

### Large-text-aware layout decisions

Width alone is no longer the only stacking signal.

`brightShouldStackForReadability()` stacks selected hero/action layouts when:
- the available width is below their normal compact breakpoint; or
- effective text is at least 1.35x.

Applied to:
- shared BrightHeader;
- Today primary action;
- Journey hero;
- My Space hero;
- My rewards doorway;
- Rewards Room hero;
- cosmetic action rows.

### Large-text-aware grids

`BrightAdaptiveGrid` now increases its effective minimum tile width as text
scales toward BrightQuest's tested 2x accessibility ceiling. This causes fewer
columns before card text becomes cramped.

At 1x text, existing grid sizing is unchanged.

### Reward celebration rows

Rewards Room expansion rows no longer use a separate trailing count pill that
can compete with long text at 2x scaling. Counts are incorporated into the
wrapping subtitle.

---

## Preserved invariants

This phase intentionally preserves:

- Nursery first-class stage from Phase 8;
- Class 3/4/5 progress and content IDs;
- Phase 7 exact Continue-to-next flow;
- Phase 9 child-vs-parent analytics separation;
- Phase 10 single reward owner;
- XP/stars/coins and achievement logic;
- Parent PIN and entitlement verification;
- 14-day session retention;
- Windows semantics crash-isolation boundary;
- system text scale precedence and current 2x tested cap;
- reduced-motion, captions and reading-focus behavior;
- no new package dependencies.
