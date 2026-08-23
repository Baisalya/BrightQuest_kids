# BrightQuest adaptive UI architecture

This refactor keeps curriculum, persistence, learning evidence, entitlements, parent controls and native audio safety separate from presentation. UI decisions are derived from the usable Flutter surface, not from the operating-system name, so an Android free-form window and a similarly sized Windows window receive the same safe composition rules.

## Viewport classes

`BrightLayoutMetrics` is created by `BrightLayoutHost` above the app routes.

- phone: width below 600 — floating bottom navigation and single-column-first composition;
- tablet: 600–899 — compact navigation rail and touch-oriented multi-column layouts;
- free-form: 900–1279 — denser rail plus wider learning/game compositions;
- desktop: 1280+ — expanded adventure sidebar and wide desktop composition.

Height is tracked independently. Surfaces below 700 logical pixels are marked short so navigation and game banners reduce vertical chrome instead of relying on width alone.

## Shared presentation primitives

- `BrightResponsive` centralises content width and breakpoint-aware composition.
- `BrightAdaptiveGrid` lays out cards from a minimum useful card width rather than fixed device names.
- `BrightSurface`, `BrightPageBackground`, `BrightSectionTitle` and `BrightPill` provide the visual hierarchy used across Home, Worlds, Progress, Profile and Nursery.
- `GameScaffold` owns the common learning-game stage, read-aloud control and responsive game identity banner.
- `MainShell` keeps tab pages mounted in an `IndexedStack`, so resizing or changing navigation mode does not recreate the active tab state.

## Interaction rules

Mouse hover is supplemental; every action remains an `InkWell`, button or other keyboard/touch-capable Material control. Existing `BrightPressableScale`, `BrightReveal` and `BrightAnimatedProgress` continue to respect reduced-motion settings and the Windows geometry-motion safety path.

## QA sizes

The adaptive regression test covers 360×640, 600×700, 700×800, 900×700, 1024×768, 1280×600, 1440×900 and 1920×1080. Existing Nursery and general responsive tests remain in place.

Windows native TTS registration and Windows Flutter semantics are intentionally untouched by this UI refactor.
