# Phase 03 + 04 — Age/Class-Adaptive Learner Shell and Main Navigation

## Scope

This phase changes the child-facing application shell without changing curriculum data, persistence schemas, entitlement rules, game implementations, mastery logic, or Nursery lesson logic.

Verified curriculum support in the baseline is Class 3, Class 4 and Class 5. Nursery exists as a separate content/progress system. This phase therefore does **not** invent Class 1, Class 2 or Class 6 content and does not pretend that Nursery is a school-class value.

## Structural changes

### 1. Learner navigation is now role-focused

The previous shell exposed five equal destinations: Home, Worlds, Progress, Parents and Profile. Parent controls were therefore presented at the same hierarchy level as child learning.

The refactored shell exposes learner destinations through `LearnerShellDestination`:

- `Today` — current Home implementation; renamed at shell level to communicate the primary learning starting point.
- `Worlds` — curriculum/adventure world exploration.
- `Journey` — current Progress implementation; renamed at shell level to frame it as the learner's journey.
- `Me` — child profile/rewards/accessibility area.

Parent controls are deliberately absent from `LearnerShellDestination` and are opened through a separate `Grown-up area` utility action. The existing `ParentGateScreen` and four-digit PIN contract remain authoritative.

### 2. Class-dependent information density is explicit policy

`LearnerShellPolicy` is a pure-Dart policy boundary. It does not read or mutate persistence.

- Class 3: `Today`, `Worlds`, `Journey` are primary; `Me` is a utility destination.
- Classes 4 and 5: `Today`, `Worlds`, `Journey`, `Me` are primary.
- Any unsupported class value receives a defensive shell fallback only. The fallback is not curriculum enablement and does not claim support for that class.

This creates one place to evolve age/class presentation later, instead of scattering class checks through navigation widgets.

### 3. Parent controls are a guarded route, not a learner tab

`MainShell` no longer mounts `ParentGateScreen` as a shell page. `Grown-up area` pushes the existing gate as its own route. The gate shows a back affordance when it is running on a pushed route, which is important on Windows/free-form surfaces as well as Android.

The PIN verification, parent-session state, parent dashboard, profile management and healthy-play controls are unchanged.

### 4. Windows crash-isolation contract is preserved

The shell still mounts only the active learner destination. No `IndexedStack` was introduced. The existing `BrightLayoutHost`, root persistence boundary, text-scaling contract and menu-audio session behavior remain in place.

### 5. Compact and desktop navigation share the same policy

The bottom navigation and side navigation both consume the same `LearnerShellPolicy`. This prevents Android/Windows hierarchy drift.

- Compact surfaces reserve the large navigation area for primary learner destinations.
- Utility actions are visually separated from the primary learning choices.
- Desktop/tablet side navigation separates primary and utility destinations with a divider.
- Very-short side navigation is scrollable so role separation does not reintroduce a vertical overflow failure.

## Explicitly deferred to later approved phases

- Home/Today content simplification and removal of competing shortcuts: Phase 5 + 6.
- Worlds/Adventures duplicate entry-point consolidation: Phase 5 + 6.
- Unified mission/session result flow: Phase 7.
- Nursery becoming a first-class learner mode/landing experience: Phase 8.
- Child progress simplification versus parent analytics: Phase 9 + 10.
- Real Class 1, Class 2 and Class 6 support: only after reviewed curriculum/content exists.

These are intentional phase boundaries, not placeholders.
