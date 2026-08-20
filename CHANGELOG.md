## 0.6.0+26 — Phases 2–10 technical learning platform

- Added schema-v5 per-profile learning state with backward loading from the accepted Phase 1 `.v3` preference key and legacy v2 fallback; existing game/topic/level progress, profiles, rewards and parent controls remain intact.
- Added a resumable, non-ranking diagnostic engine that samples only scorable items and records correctness, hints, retries, response time, confidence and misconception evidence.
- Added evidence-based skill states, recommendations, independent/transfer mastery rules, delayed-review scheduling and deterministic 1/3/7/14/30-day Power Review queues.
- Added reusable teach → worked example → guided try → independent practice → transfer → exit/reteach/review lesson flows and accessible learning primitives for number lines, base-ten, fraction strips, ordering, evidence highlighting, diagram classification, predict-observe-explain, maps and code traces.
- Added 111 Class 3–5 competency learning blueprints, explicitly kept `needsReview`; they are technical draft coverage and do not represent teacher approval or CBSE/NCERT certification.
- Added three safe local multi-skill applied missions per major subject per class, with project/reflection evidence separated from secure mastery evidence.
- Added parent learning-evidence reports with competency states, evidence counts, misconceptions, next-review dates, weekly summaries and project evidence; PDF/print export remains disabled until privacy/layout review.
- Added English-first learning-language state, dyslexia-friendly spacing, reading-focus and captions/transcript support while keeping Hindi disabled until a reviewed translation pack exists.
- Added stable ₹299 one-time class product IDs, parent-only class-pack UI and fail-closed entitlement services. Local cached ownership cannot unlock production content; real Google Play/Microsoft Store verification remains an external integration gate.
- Added plain-language privacy/release/pilot/store/Windows-accessibility documentation and static release checks for AD_ID absence, free samples, review-gated paid eligibility, Windows narration isolation and the existing Windows semantics crash workaround.
- Preserved the crash-isolated Windows `System.Speech` narration implementation; did not restore `flutter_tts_plugin.dll` or Windows Flutter semantics.
- Added Phase 2–10 regression tests and learning/content/release validators.
- Refactored learning evidence, mastery, recommendation and review transitions out of the oversized controller into a dedicated `LearningProgressEngine`; secure skills now complete their review task instead of being rescheduled forever.
- Connected the 111 bundled competency blueprints to the runtime repository and lesson engine. Learning levels now choose content from their real class/game/difficulty boundary instead of comparing incompatible topic-ID systems and falling back to the first competency.
- Replaced the arithmetic generator's unbounded distractor loop with a bounded deterministic algorithm; all supported class/difficulty/seed combinations now finish with four valid choices.
- Centralised synchronous content/app fixtures for widget tests, removing the large-asset/fake-clock deadlock that previously froze the complete suite.
- Verified `flutter analyze`, all 105 Flutter tests, both content validators, static release-safety checks, Android and Windows release builds, and a 12-second hidden Windows startup smoke run. Teacher review, child pilots, signed store verification and real-device/native Windows soak qualification remain pending.

## 0.5.0+25 — Phase 1 scalable content packs

- Phase 1 QA hotfix: explicitly bundle the curriculum/schema/audit and all three class-pack JSON files so `rootBundle` repository loading works reliably in Flutter widget tests and packaged Android/Windows builds.
- Fixed the Phase 1 migration-parity test to use the existing `CurrentContentAuditSelector.key` contract and removed two analyzer-only unused imports.
- Replaced runtime hard-coded class question banks with a validated, bundled `ContentRepository` backed by separate Class 3, Class 4 and Class 5 JSON packs.
- Migrated all 189 currently reachable authored learning records into class packs while preserving existing game/topic/learning-level identities and schema-v4 save compatibility.
- Added content-pack schema validation for competency/outcome references, class boundaries, explanations, review metadata, distractors, choice integrity, generated-content rules, science fallbacks and solvable coding routes.
- Added deterministic arithmetic, fraction, grammar and map-direction generators plus command-line validation, duplicate reporting and curriculum-coverage tooling.
- Added development-only class-pack locking for entitlement UX testing without adding billing or child-facing purchase flows.
- Added Phase 1 regression tests for JSON packs, 189-record/88-selector migration parity, malformed content, deterministic generators, development locks, hard-coded-bank removal and legacy progress round-trips.
- Kept all migrated activities `needsReview` and all class packs commercially ineligible until genuine reviewer approval; the ₹299 one-time-per-class model is metadata only in this phase.
- Preserved the crash-isolated Windows `System.Speech` narration implementation and the existing Windows semantics safety workaround; no Windows TTS plugin or semantics restoration was introduced.

## Unreleased — ₹299 class-pack roadmap

- Implemented the Phase 0 curriculum/data contract with 37 draft competencies per class, class-specific boundaries, observable learning outcomes, official-reference metadata, mastery-evidence targets and explicit reviewer/revision states.
- Added exhaustive mapping/audit coverage for the currently reachable learning banks, a versioned content schema, duplicate/coverage tooling, and contract tests for IDs, class boundaries, invalid content and legacy save/level compatibility.
- Kept all Phase 0 curriculum and commercial review states non-approved: each class remains blocked from paid eligibility until a real qualified primary reviewer approves the boundaries, objectives and free/paid split.
- Added an implementation-ready roadmap covering curriculum mapping, diagnostic evidence, teach/practice/mastery flows, reviewed class content, spaced retention, deep missions, parent reporting, accessibility, one-time class entitlements, child safety and release qualification.
- Defined a coding-agent execution protocol and a commercial-completeness checklist so future implementation can proceed phase by phase without treating more quiz questions as sufficient learning depth.
- Consolidated current product, build, Windows safety and audio-origin documentation into `README.md`.
- Removed obsolete Phase 2–4.6 implementation snapshots, duplicated QA/audio notes and stale delivery manifests; version history remains in this changelog.

## 0.4.21+24 — Smart read and selectable voices

- Smart Read now speaks each game prompt together with its visible answer choices from the shared Read Aloud button.
- Correct feedback happily repeats the child's chosen answer; wrong feedback gently repeats the choice and provides the correct answer or retry guidance appropriate to that game.
- Added installed-voice discovery and a persistent narration voice selector on Android and Windows, with a recognized female English voice chosen first by default.
- Windows voice discovery and selection stay inside the crash-isolated `System.Speech` helper; Flutter still does not load `flutter_tts_plugin.dll` on Windows.
- Clarified the three independent parent controls as BGM music volume, game sound-effects volume, and speech-narration volume.
- Added female-first voice-selection, smart-read wiring, audio-control, and real Windows spoken-smoke regression coverage.

## 0.4.20+23 — Crash-isolated Windows narration

- Restored Windows guide narration through the installed `System.Speech` voices without registering the crashing `flutter_tts_plugin.dll`.
- Runs each spoken prompt in a hidden, isolated Windows PowerShell helper process, so a speech-engine failure cannot terminate Flutter.
- Preserves Windows narration enable/disable, volume, speed, automatic introductions, feedback, read-aloud, BGM ducking and cancellation controls. Pitch remains Android-only.
- Added UTF-16LE encoded-command and Base64 prompt transport so narration text is passed without shell interpolation.
- Added an automated backend availability regression and `tool/windows_speech_smoke.dart` for a real spoken QA phrase.
- The separate Flutter Windows accessibility semantics workaround remains in place; Android narration and semantics are unchanged.

## 0.4.19+22 — Windows native crash fix

- Reproduced the delayed Windows disconnect and traced its two access violations through Windows Event Viewer: first `flutter_tts_plugin.dll`, then `flutter_windows.dll` after repeated invalid AXTree updates.
- Replaced the cross-platform TTS registration with a local Android-only `flutter_tts` fork. Android keeps guide narration; Windows keeps MCI music/effects and no longer loads the crashing TTS DLL.
- Temporarily suppresses the Flutter semantics subtree only in the production Windows entry point to avoid the current engine accessibility-bridge crash. Android semantics and motion remain enabled.
- Made `BrightSurface` a real clipped Material surface, fixing the startup `ListTile`/decorated-background framework assertions.
- Added Windows startup/material and native-plugin regression coverage.
- Verified `flutter analyze`, all 57 Flutter tests, Android debug APK compilation, Windows release compilation, a native Windows soak run beyond the former crash interval, and live resizing from phone-sized through desktop-sized windows.

## 0.4.17+20 — Windows audio shim header hotfix

- Fixed the local `audioplayers_windows` no-op shim to expose Flutter's expected public header at `windows/include/audioplayers_windows/audioplayers_windows_plugin.h`.
- Exported both `AudioplayersWindowsPluginRegisterWithRegistrar` and the C-API compatibility alias so Flutter 3.41 generated registrants can link the shim.
- Kept Windows playback on BrightQuest's event-channel-free MCI backend and Android on the normal audioplayers backend.
- No learning, progression, persistence, voice, BGM or SFX content changes.

## 0.4.16+19

- Replaced the crashing `audioplayers_windows 4.3.1` runtime path with a BrightQuest Windows MCI backend that uses no Flutter event channels.
- Added a local no-op `audioplayers_windows` federated shim so Android keeps `audioplayers 6.7.1` while Windows does not load the old native event-channel plugin.
- Preserved bundled BGM/SFX, voice ducking, TTS, parent audio controls, and all learning/progression logic.
- Added bootstrap validation that the local Windows audio shim is the resolved Windows implementation.
- Added a regression test proving the Windows event-channel backend is bypassed.

## 0.4.15+18
- Restore `audioplayers 6.7.1` so Flutter 3.41.9 can resolve dependencies.
- Keep the BrightQuest audio experience unchanged.
- Patch generated Windows CMake before build with `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` for Visual Studio 18 / MSVC 14.51 compatibility.
- Keep Windows CMake minimum/policy at 3.15 for current audioplayers Windows requirements.
- Remove the incompatible v0.4.14 bootstrap requirement for audioplayers 6.8.1 / Windows backend 4.4.x.

# Changelog

## 0.4.14+17

- Fixed Windows builds on Visual Studio 18 / MSVC 14.51 by pinning `audioplayers` 6.8.1, which includes the upstream Visual Studio 18 compatibility fix.
- Bootstrap now runs `flutter pub upgrade --unlock-transitive audioplayers` so stale lockfiles cannot keep the pre-fix Windows backend.
- Bootstrap verifies that `audioplayers_windows` resolved to the 4.4.x line before analyze/test.
- Kept the required Windows CMake 3.15/CMP0091 hardening and added Microsoft's experimental-coroutine suppression macro only as a defensive fallback for stale plugin caches.
- No learning, scoring, persistence, curriculum, progression, parent-control, voice, BGM, or SFX behavior changed.

## 0.4.13+16 — Phase 4.6 child-friendly audio experience

- Added 10 bundled offline BGM loops: menu plus all nine adventures.
- Added nine bundled sound effects for taps, correct/wrong answers, hints, coins, stars, unlocks, level starts and mission completion.
- Added gentle dynamic guide narration using device TTS, automatic adventure introductions and optional praise/encouragement.
- Added reward-aware completion narration, star/unlock chimes, guide-tone controls and automatic BGM ducking under speech.
- Added a Read Aloud control to every game for the current question/mission prompt.
- Added spoken hints to Math Market, Story Builder and Map Quest.
- Added locked-parent controls for music, voice, auto narration, voice feedback, effects, volume and guide speed.
- Added app-lifecycle music pause/resume and menu/game soundtrack switching.
- Added Windows bootstrap CMake 3.15 compatibility hardening for audioplayers 6.8.x.
- Added Android 11+ TTS service-discovery manifest patching during bootstrap.
- Added audio asset/catalog regression tests.
- Learning curriculum, scoring, progress schema, rewards and persistence logic remain unchanged.

## 0.4.12+15 - Phase 4.5C motion/runtime hotfix

- Fixed BrightReveal with overshooting curves such as easeOutBack producing opacity values above 1.0.
- Opacity is now clamped to Flutter's valid 0.0-1.0 range while transform overshoot remains intact.
- Fixed compact BrightHeader choosing layout from global MediaQuery width instead of its actual available constraints.
- Added regression coverage for overshooting reveal curves.
- No curriculum, scoring, persistence, progression, rewards, or parent-control logic changed.

## 0.4.11+14 — Phase 4.5C visual polish & motion
- Added a shared finite-animation layer for reveal, press/hover depth, glossy glints, animated progress, value pops and one-shot celebration particles.
- Upgraded Home adventure/world cards, Learning World roadmap, shared game HUD/progress/feedback, Math Market, Science Lab and Rewards Room with motion that stays responsive across Android, Android free-form and Windows.
- Added one-shot mission-completion star/confetti feedback and animated unlock/progress presentation.
- Reduced-motion and system disable-animations settings bypass decorative motion.
- Added regression coverage proving motion settles and does not leave scheduled frames running.
- No curriculum, scoring, reward calculation, persistence, profile isolation, parent controls or unlock rules changed.

## 0.4.10+13
- Hardened the final compact Android/free-form Home path against intrinsic-width RenderFlex overflow.
- Compact header logo/stats can wrap instead of forcing one horizontal line.
- Compact wooden adventure sign is width-bound and uses bounded two-line text.
- Continue Adventure switches to a stacked scene/details layout when its real inner width is below 300 px.
- Streak counter uses Wrap so large values/text scaling cannot force a horizontal overflow.
- Learning/progression/controller/persistence behavior is unchanged.

## 0.4.9+12 — Phase 4.5B compact-layout/test hotfix

- Fixed compact 360–390 px Home overflow by using a dedicated very-compact header composition and a stacked hero sign/mascot layout.
- Capped the BrightQuest logo's intrinsic width so it scales down inside narrow rows instead of contributing oversized minimum width.
- Added stable `adventure_card_<gameId>` keys so smoke tests open the intended Quick Play game regardless of visual text ordering.
- Added stable Math Market guide and daily-limit break keys and removed brittle text-only route assertions.
- Preserved the Phase 4 curriculum, scoring, progression, persistence, rewards, profiles, parent controls and session-limit logic.

## 0.4.8+11 — Phase 4.5B visual fidelity pass

- Added native Flutter illustration primitives for the BrightQuest wordmark, lion mascot, scenic sky/hills/castle background, wooden signs, sparkles and nine game-specific illustrated scenes.
- Rebuilt Home hero closer to the concept references with the lion guide, wooden “Choose Your Adventure!” sign, Continue Adventure card, streak card and illustrated subject/game cards.
- Rebuilt Quick Play / All Adventures cards into image-led game tiles with illustrated top scenes, colored title/progress bands and stronger hover/touch depth.
- Reworked Learning World hero cards to use game artwork instead of emoji-only decoration while preserving the Practice → Challenge → Mastery roadmap.
- Upgraded the shared game HUD/plaque, mission progress strip, feedback surfaces and completion celebration so every game inherits the same visual identity.
- Deepened Math Market visual fidelity with a scenic market backdrop, wooden-framed chalkboard, custom lion guide, multicolor answer buttons and a wood-sign market shelf.
- Deepened Science Lab with illustrated lab scenes, a scientist lion, richer experiment result panel and image-like quiz answer tiles.
- Deepened Story Builder with an illustrated scene card and mascot-led reading panel.
- Added illustrated fidelity banners to Fraction Pizza, Grammar Puzzle, Map Quest, Coding Maze and Recycling Challenge.
- Added visual-fidelity widget smoke tests for compact Android, large Windows and all nine illustrated game scenes.
- Phase 4 curriculum, scoring, progression, save schema, rewards, profiles, parent controls and session limits remain unchanged.

## 0.4.7+10 — Phase 4.5 layout/test hotfix

- Fixed Math Market wide-layout `BoxConstraints forces an infinite height` by removing `CrossAxisAlignment.stretch` from a `Row` hosted inside a vertically unbounded `ListView`.
- Updated the root-widget smoke test to assert the stable Home semantics label instead of requiring a visible side-rail text label at medium widths.
- Added an explicit 800×600 Math Market regression test covering the reported Windows/widget-test constraint path.
- Fixed compact Home overflows by using a single Quick Play column below 420px, moving Home stats to a second header row, and stacking section-title trailing widgets on narrow widths.
- No curriculum, scoring, rewards, persistence, profiles, parent limits, or unlock logic changed.

## 0.4.6+9 — Phase 4.5 compile hotfix

- Fixed shell navigation items being scoped inside `_MainShellState` while sibling navigation widgets referenced them directly.
- Moved the shared shell item list to library scope and kept the same Home / Worlds / Progress / Parents / Profile navigation behavior.
- Fixed `BrightWorldPalette` to import `SubjectWorld` from `game_models.dart`, where the enum is actually declared.
- Removed stale unused imports reported by `flutter analyze`.
- No curriculum, scoring, persistence, rewards, parent controls, learning-path, or game logic changed.

## 0.4.5+8 — Phase 4.5 BrightQuest Visual Experience Overhaul

- Added a shared kids-first BrightQuest design system with responsive breakpoints, surfaces, pills, mascot bubbles, world palettes and decorative page backgrounds.
- Rebuilt the main shell for Android phone, tablet/free-form widths and Windows with a width-driven floating bottom navigation / branded side navigation.
- Rebuilt Home around the generated BrightQuest visual direction: adventure hero, mascot guidance, continue mission, daily goals, world cards and richer Quick Play tiles.
- Rebuilt Learning Worlds into illustrated subject cards and a node-based Practice → Challenge → Mastery learning road.
- Reworked shared game presentation: colorful HUD, compact responsive header, themed game banner, progress strip, encouraging feedback and celebration-style mission summary.
- Rebuilt Math Market as the reference production game UI with a chalkboard question area, market panel, basket progress and responsive two-panel desktop/tablet composition.
- Rebuilt Progress and Profile screens with the same BrightQuest visual system while keeping parent-managed controls separate.
- Reworked Parent PIN gate with a calmer adult visual mode.
- Rebuilt Rewards Room as a visual treasure/achievement/trophy/cosmetic space.
- Updated smoke tests to use stable navigation semantics and added phone/tablet/desktop overflow regression coverage.
- Preserved Phase 4 curriculum, scoring, rewards, achievements, persistence, child-profile isolation, parent limits and unlock logic.

## 0.4.2+7 - Phase 4 responsive QA hotfix

- Fixed Learning World card vertical RenderFlex overflow at compact/test viewports.
- Fixed AdventureCard adaptive badge horizontal overflow by making the badge area flexibly bounded.
- Added a stable Math Market hint-button key and made the smoke test scroll before asserting off-screen controls.
- Added compact-viewport widget regression coverage for Home card layout.
- No curriculum, scoring, reward, progression, save-schema, or parent-control behavior changed.

## 0.4.1+6 — Phase 4 QA hotfix

- Removed the unused HomeScreen progress-model import reported by `flutter analyze`.
- Reworked Phase 4 widget smoke tests to scroll lazy slivers before asserting/tapping content below the fold.
- Removed the brittle dependency on the first Math Market question text; the smoke test now validates stable game-screen semantics instead.
- Hardened `bootstrap_windows.ps1` so every Flutter command checks its native exit code and the script cannot print a false QA-success message after analyzer/test failures.
- Preserved all Phase 4 curriculum, progression, persistence, reward and gameplay logic.

## 0.4.0+5 — Phase 4 Learning Worlds

- Added schema-v4 per-level progress with Phase 2 and Phase 3 migration compatibility.
- Added 24 Learning World levels per class / 72 levels across Classes 3–5.
- Added Practice → Challenge → Mastery track locking and 1–3 star grading.
- Added separate curriculum-level launches while preserving adaptive Quick Play.
- Added first-clear rewards, replay star improvement and duplicate-reward protection.
- Added persistent one-time achievement milestones and achievement coin rewards.
- Added Learning Worlds roadmap UI, next-level recommendation and per-world completion.
- Integrated learning-path progress into Home, Progress, Profile, Parents and Rewards.
- Expanded class/difficulty content across all eight learning games.
- Added separate Class 3/4/5 Coding Maze banks and validated all 18 maze routes.
- Corrected retry scoring in Fraction Pizza, Story Builder, Grammar Puzzle and Coding Maze so repeated attempts cannot create artificial perfect mastery scores.
- Added stronger completion feedback with reduced-motion support.
- Added Phase 4 regression tests for progression, locking, migration, profile isolation, stars, achievements and coding-route validity.

## 0.3.0+4 — Phase 3 learning product

- Migrated the save model from one child to versioned multi-child profiles with Phase 2 compatibility migration.
- Added per-topic progress and 3-tier adaptive difficulty with stable per-run difficulty capture.
- Expanded Class 3–5 content banks across all current learning games.
- Added typed Class 3–5 curriculum catalog and learning-path UI.
- Added daily learning quests with one-time local-day rewards.
- Added parent PIN gate, child profile creation/switch/delete, weak-area summary, per-child class management and per-child reset.
- Added foreground learning-game time tracking and parent-controlled daily time-limit enforcement both at launch and during active sessions; non-learning screens do not consume the limit.
- Removed class switching from the child Home header.
- Added responsive NavigationRail shell for wide Windows/free-form layouts.
- Added text scaling, high contrast, reduced motion and haptic comfort settings.
- Added lightweight answer sound/haptic feedback.
- Added v3 shared-preferences key with v2 fallback/migration path.
- Expanded controller, curriculum, gameplay and widget regression tests.

## 0.2.1+3 — Phase 2 compile/QA hotfix

- Replaced every invalid `FontWeight.black` reference with the supported `FontWeight.w900` constant.
- Added a project-owned `test/widget_test.dart` that boots `BrightQuestApp` with `GameController`.
- Hardened Windows/Linux bootstrap scripts so a stale Flutter-generated `MyApp` counter test is removed without touching BrightQuest tests.
- Added regression scans for the reported invalid font-weight and generated-test failure patterns.
- Preserved all Phase 2 gameplay/persistence behavior; this patch is compile/bootstrap hardening only.

## 0.2.0+2 — Phase 2 game logic

- Added versioned local persistence through a storage abstraction and `SharedPreferencesAsync` device store.
- Added per-game attempts, correct answers, mastery, mastery stars, completed runs, best score and hint counters.
- Added ordered persistence queue for rapid state changes.
- Added one-time first-clear bonuses and smaller replay rewards.
- Added persistent cosmetic reward ownership.
- Added persisted class selection and parent preferences.
- Rebuilt Math Market as a finite class-aware mission run.
- Added mathematical equivalent-fraction validation to Fraction Pizza.
- Added virtual reaction logic and quiz run to Science Lab.
- Added finite sentence-building missions to Story Builder.
- Added finite grammar missions and retry flow.
- Added multi-question geography run to Map Quest.
- Replaced Coding Maze string matching with grid/direction/obstacle simulation.
- Rebuilt Recycling Challenge as a finite scoring run.
- Fixed invalid Phase 1 `Container(minHeight: ...)` usage.
- Added expanded controller, gameplay and widget smoke tests.

## 0.4.18+21 — Windows accessibility/startup stability hotfix

- Stabilized `BrightReveal` semantics so fade-in opacity never removes/re-adds child semantics during animation.
- On Windows, transform/scale motion is suppressed while non-geometric polish (progress, glints, particles) remains available; Android keeps the complete motion experience.
- Simplified navigation, logo, and adventure-card semantics into explicit stable boundaries without duplicate descendant semantics.
- Deferred optional audio/TTS initialization until after the first frame; Windows TTS configuration is lazy until first speech.
- No curriculum, scoring, progression, persistence, or game-content changes.
