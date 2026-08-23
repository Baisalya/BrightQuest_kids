## Unreleased — Nursery learning pack implementation

- Step 12 adds a root lifecycle persistence boundary that flushes authoritative progress and independent resumable mission slots on background/hidden/detached states, memory pressure and root disposal, including non-game screens.
- System accessibility text scaling is now preserved instead of being replaced by the in-app text-size setting; the larger requested scale is respected up to the Step 12 tested 2x layout ceiling.
- Very-short Android free-form/Windows surfaces prioritize the five navigation destinations and suppress only decorative/profile sidebar chrome below 460 logical pixels of height.
- Desktop/Windows audio now treats the Flutter hidden lifecycle state as background, pausing music and narration while retaining the existing crash-isolated System.Speech/MCI boundary.
- Added Step 12 production-hardening tests, a deterministic static readiness audit, PowerShell/shell QA runners and a cross-device qualification document; commercial release remains fail-closed on teacher/pilot/store/privacy/real-device evidence.
- Nursery child UX is simplified around one obvious Play Now path: skill screens now show Play Now, Learn First and a collapsed More games chooser instead of presenting every authored phase as a separate adventure portal.
- Nursery teaching is reduced to one picture-first Look & listen page, correct answers continue directly to Next Game, and child-facing mastery/phase/tracing disclaimers were removed while all authored evidence, scoring and parent-report safeguards remain unchanged.
- Nursery home now uses large picture-led skill cards, simple three-star progress cues and a collapsed ABC Picture Book so the child is not confronted with the entire A–Z catalog and adult-oriented learning terminology at once.
- Simplified Nursery choice, match, sort and trace interaction copy while keeping the same authored activities, evaluator, mastery eligibility, review engine, narration and accessibility semantics.
- Added regression coverage for recommended-game selection, skip-completed Next Game behavior, the single-primary-action skill board and removal of adult-facing tracing copy from the child hub.
- Step 10.1 upgrades resumable sessions from one profile-wide slot to independent profile + class + game + learning-mission slots, so pausing one game no longer blocks starting or resuming another.
- Quick Play keeps one independent slot per game/class, while Learning World missions are keyed by their existing level id; two missions using the same game can therefore pause and resume independently without slot collisions.
- Learning Worlds now list every saved mission for the current class with per-session Resume/Discard actions; completing, restarting or discarding one session mutates only that exact slot.
- Class switching now hides other-class checkpoints instead of deleting them, profile deletion/reset still removes only that profile’s sessions, and the v1 session-store decoder transparently canonicalizes legacy profile-keyed checkpoints without changing PlayerSnapshot schema v6.
- Answer/evidence, paid-hint and completion idempotency now bind to the exact foreground/mission slot, preserving Step 10 crash-safety guarantees when several games are paused at once.
- Added multi-slot regression coverage for different games, multiple missions using the same game, class isolation, local discard and legacy session-key migration.
- Step 11 adds a presentation-only LearningAudioDirector + LearningNarrationCue contract so authored lesson/activity/game text drives narration and visible transcripts without changing correctness, evidence, mastery, rewards or curriculum data.
- Learning World lesson steps now use the existing automatic-narration preference and expose a shared visible transcript, manual Read aloud and Stop narration surface; interactive cues read only the authored prompt/narration and authored choices.
- GameScaffold now exposes the same compact narration transcript/manual-read surface for all eight main games while keeping game-question narration manual so it cannot race the existing automatic game introduction.
- The existing captions preference now has a concrete Class 3–5 runtime effect, and Reading Focus now keeps the current transcript visible, strengthens the current teaching-text focus surface and increases reading spacing even when captions are off.
- Expanded the visible-audio transcript catalog to cover game introductions, lesson narration, prompt narration and voice feedback in addition to existing BGM/SFX cues.
- Preserved the Android-only flutter_tts fork, crash-isolated Windows System.Speech child-process backend, Windows MCI audio backend, fail-closed Windows semantics default and active-page-only shell; no Windows TTS plugin/semantics restoration was introduced.
- Added Step 11 regression coverage for authored narration selection, auto-narration gating, captions/Reading Focus behavior, compact GameScaffold layout, Class 3–5 narration completeness and Windows crash-isolation markers.
- Step 10 adds a separate schema-v1 resumable game-session store (`brightquest.active_game_sessions.v1`) while keeping the authoritative PlayerSnapshot at schema v6 with no save migration or curriculum-state duplication.
- Learning World lesson position, shown hints and completed interactive steps now resume safely; finishing the lesson checkpoints the transition to the real game so an interruption between lesson and game does not lose the mission.
- All eight main games now checkpoint their current item, score and interaction state, restore that state on resume, and preserve completed result screens until the child exits or explicitly restarts.
- Quick Play resumes the checkpointed difficulty/content bank even if adaptive recommendations change after already-recorded answers, preventing a resumed cursor from landing in a different question set.
- Paid hints use a pending/committed transaction marker plus in-flight coalescing so interruption or rapid double-tap cannot charge the same saved hint twice.
- Mission completion now uses a completing → authoritative progress flush → result transaction with in-flight coalescing; after a crash between progress commit and result persistence the result is reconstructed without awarding coins, XP, stars, attempts or achievements twice.
- Answer attempts now also keep pending/committed session transaction markers in addition to evidence IDs, with in-flight coalescing so rapid double-tap and crash resume stay idempotent even when an activity has no learning-evidence mapping; authoritative progress is flushed before the marker can commit.
- Answer attempts and lesson mastery evidence now use session-scoped idempotency IDs with progress-first flush ordering, so a crash after authoritative progress is saved but before the UI checkpoint is saved cannot double-score the same response on resume.
- Learning Worlds surface profile-isolated saved-mission Resume/Discard actions; stale, malformed/incomplete-transaction, unknown-game and mismatched-level checkpoints fail closed and are removed from the separate session store.
- Game and lesson lifecycle boundaries now flush queued progress/session writes when the app leaves the resumed state, reducing loss from Android backgrounding, Windows close/suspend and free-form window lifecycle changes.
- Added Step 10 regression coverage for session round-trips, PlayerSnapshot-v6 isolation, profile/class safety, double-tap coalescing, hint double-charge prevention, reward double-award recovery, stale/corrupt checkpoint rejection and all-eight-game participation.
- Step 9 adds a read-only AdaptiveDifficultyEngine that derives support posture from existing per-level and per-game progress without persisting a second difficulty state or changing authored level difficulty, pass ratios, correctness, rewards or unlock rules.
- Practice now keeps the full See it → Try with help → Try yourself → Apply loop, can add faster rescue for a struggling learner, and trims explanation/pre-attempt help when existing evidence shows strong readiness.
- Challenge now uses a compressed mission session with less pre-attempt support; a struggling learner may regain one coached warm-up while the Challenge target remains difficulty 2 and the final checkpoint stays independent.
- Mastery now uses a short objective → proof session with authored difficulty-3 work and no hint/rescue path; clean independent transfer evidence remains governed by the existing MasteryEngine.
- Learning World lesson activity selection is now fail-closed at the level's authored difficulty cap and cannot silently pull Class 3–5 Skill Studio difficulty-4/5 content into Practice, Challenge or Mastery.
- Paid main-game hints remain available in Quick Play and Practice but are removed from Learning World Challenge/Mastery runs; existing GameController hint costs and reward/evidence formulas are unchanged.
- Added Step 9 regression coverage for support/readiness policy, compressed Challenge/Mastery sessions, exact target-tier activity selection across all 72 Class 3–5 learning levels, and main-game hint eligibility.
- Step 8 adds a presentation-only GameFeelDirector that converts already-authoritative feedback, mission-session phases and reward moments into finite mascot/motion cues without changing correctness, mastery, rewards or persistence.
- Leo now has focused, thinking, encouraging, celebrating and heroic visual states; boss/world clears use a heroic crown treatment while wrong attempts use gentle thinking/encouragement instead of a failure pose.
- Contextual feedback now reacts through a reusable Leo moment surface, teaching stages carry phase-aware mascot reactions, gameplay scenes receive a one-shot ambient glint, and themed answer tiles gain touch/hover press feedback.
- Added BrightMomentReaction as a finite reduced-motion-aware motion primitive: Android may use small transform reactions, while Windows keeps semantics geometry fixed and uses non-geometric opacity-only feedback.
- Mission reward moments now coordinate mascot mood, burst density, trophy reaction and unlock/world-clear reveals from the existing AdventureRewardMoment; no reward amounts or unlock decisions moved into the presentation layer.
- Added deterministic Step 8 game-feel policy tests plus finite/reduced-motion widget coverage; no repeating animation loop or new dependency was introduced.
- Step 7 adds a presentation-only adventure reward engine that interprets existing MissionReward, level progress and world mission metadata without granting or mutating coins, XP, stars, unlocks or persistence.
- Learning-path results now distinguish retry, first clear, star upgrade, boss/zone clear and whole-world completion moments, with world-specific trophy copy and the actual next mission shown only on a genuine first-clear unlock.
- Mission completion now presents earned coins, XP and star gains as a child-facing loot moment, surfaces achievements, celebrates boss clears and world trophies, and keeps replay rewards separate from new unlock messaging.
- Learning Worlds now expose a compact reward trail for quests, conquered zones and collected stars, plus per-zone star/completion progress, zone-clear badges and a three-star replay goal for already-cleared missions.
- Added deterministic Step 7 reward-loop tests for first clear, boss/zone completion, final world completion, failed runs, replay star upgrades and read-only zone/world progress derivation.
- Step 6 adds a deterministic contextual hint + feedback engine that separates correctness from coaching: ActivityResponseEvaluator still scores responses while ContextualFeedbackEngine chooses world-aware success/retry copy, misconception strategy cues and staged support.
- Incorrect attempts no longer auto-append the authored explanation/correct answer; first misses receive process coaching, repeated misses escalate to authored clues, and only explicit clue/power-up actions expose existing hint/reteach text.
- Solo, transfer and checkpoint activities still start without clues, but after a miss they may request the activity's authored hints without changing the existing hint-level/mastery evidence semantics.
- Added world-specific feedback identity and mechanic-aware correction cues for decision, construction, sorting, navigation and simulation activities without inventing curriculum facts or adding dependencies.
- Added Step 6 regression coverage across all bundled Class 3–5 activities, including answer-leak prevention, misconception-aware arithmetic coaching, escalation behavior and independent-mode hint gating.
- Step 5 adds a mission-session layer that groups the existing authored lesson flow into four child-facing phases: See it → Try with help → Try yourself → Apply in game.
- Reteach and delayed review remain authored in LessonEngine but are no longer forced as unconditional pages after a successful mission; reteach is exposed as an optional in-game power-up after a miss and review is surfaced as future-review guidance.
- Guided play now carries authored Leo clues inside the game stage, while solo/transfer/checkpoint play keeps independent evidence semantics and can request the existing reteach strategy only after an unsuccessful attempt.
- Replaced generic teaching cards with mission teaching stages and worked-move walkthroughs derived only from existing blueprint/activity prompt, answer and explanation data; no curriculum facts or schemas are inferred.
- Added deterministic mission-session tests across all 111 Class 3–5 competency flows while keeping ActivityResponseEvaluator, mastery evidence, rewards, saves, entitlements and Windows narration/semantics safety unchanged.
- Step 4 adds a presentation-only world mission catalog that turns the existing Practice → Challenge → Mastery levels into distinct fictional zones, quests and boss/mastery encounters without changing curriculum IDs or save state.
- Rebuilt each Learning World as grouped world zones with current-quest highlighting, world-native route names, locked/cleared state, replayable stage cards and visually distinct boss missions.
- Lesson flows now carry a world mission ribbon, mission briefing, staged quest progress and world-specific launch action while retaining the existing LessonEngine teaching sequence and evidence rules.
- Learning-path game runs now keep their world/zone/mission identity inside the shared GameScaffold and show world-specific completion/unlock copy in MissionSummaryCard; Quick Play remains unchanged.
- Added deterministic world-mission catalog tests across all 72 existing learning levels; no curriculum schema, correctness evaluator, mastery, rewards, persistence, entitlement or Windows narration/semantics contract was changed.
- Step 3 split the learning-game renderer into a mechanic registry plus independent mini-game widgets, so new activity types can be added without growing another monolithic response widget.
- Added explicit gameplay-mechanic and world-presentation contracts: decision, construction, sorting, navigation and simulation stay independent from Maths/Story/Science/Green/Map/Robot visual identity.
- Replaced generic choice cards with world-native market stalls, story trails, lab samples, eco paths, explorer markers and robot modules while preserving the exact authored answer values.
- Upgraded fraction work to an interactive pizza wheel, recycling to drag-to-bin play, experiments to drag-to-flask mixing, and retained direct manipulation for story ordering, grammar sorting and robot route programming.
- Kept ActivityResponseEvaluator, evidence/mastery ownership, rewards, persistence, content schemas, Windows narration isolation and crash-safety boundaries unchanged.
- Added Step 3 resolver/registry regression coverage for mechanic capability and world-specific choice presentation.
- Added a reusable learning-game presentation architecture that resolves authored `ContentActivity` records into safe interactive game families without changing correctness, evidence, reward or persistence ownership.
- Replaced the monolithic lesson response widget with a resolver + game renderer + adaptive game-stage boundary, including themed mission choices, visual fraction building, story ordering, grammar sorting, robot-route preview, experiment mixing and recycling-bin play.
- Rich renderers opt in only when existing structured payload fields are present; unsupported authored rules fail closed instead of inferring facts from prompt text.
- Added resolver regression coverage across all bundled Class 3–5 activities, including the previously unrendered case-sensitive text rule.
- Refactored the presentation layer around viewport-derived adaptive metrics so Android phones, tablets/free-form windows, compact Windows windows and large Windows desktops compose differently without OS-specific UI branching.
- Rebuilt the main shell with a floating phone navigation dock, compact adaptive rail and expanded desktop adventure sidebar; the selected page remains stable across resizing without keeping off-screen pages alive in an `IndexedStack`.
- Added reusable adaptive grids, richer themed surfaces, responsive page backgrounds and kid-focused visual hierarchy tokens without adding third-party UI dependencies.
- Redesigned Home, Learning Worlds, Progress, Profile achievement layout, Nursery hub and the shared game scaffold with more visual quest/path cues, stronger mascot/reward presence and mouse/touch-friendly interaction states.
- Added adaptive-layout regression coverage for 360×640 through 1920×1080 surfaces, including short-height Windows/free-form scenarios and resize-state preservation.
- Curriculum, persistence, mastery, entitlements, parent controls, save migrations, Windows narration isolation and the Windows semantics safety path remain unchanged by this UI-only architecture refactor.
- Added a separate backward-compatible `brightquest_nursery` learning pack without forcing Nursery into the integer Class 3–5 model.
- Added 32 Nursery skills, 132 authored activities, deterministic generated review, Nursery evidence/mastery/review state, parent reporting and additive save-schema v6 migration.
- Added A–Z uppercase/lowercase learning with 208 bundled picture-word discovery cards (eight examples per letter), replayable narration, another-word/next-letter exploration and sound-practice eligibility guards.
- Added early maths 0–20, counting, quantity matching, sequences, comparison and bounded object-first addition, plus colours, shapes, patterns, matching/sorting, familiar knowledge, observation and listening activities.
- Added touch/mouse tracing as non-mastery guide-path practice; no handwriting-correctness claim is made.
- Phase B Letters & Sounds separates the 208-card discovery library from a stricter 157-example simple-phonics evidence pool; irregular vowels, Q/X patterns, SH, and initial consonant clusters remain discoverable but cannot silently enter simple phonics mastery.
- Added an independent Phase B phonics reference/auditor, deterministic 157-example generator-coverage checks, skill-accurate alphabet game portal labels, and phone/tablet/Windows alphabet UI regressions.
- Replaced 13 misleading generic emoji picture cards (including Igloo, Vacuum, Ukulele, Vulture and Yak) with dedicated bundled illustrations and safe text fallbacks.
- Added finite reduced-motion-aware teaching/feedback animations and static fallbacks; no repeating Nursery animation loop was introduced.
- Preserved the crash-isolated Windows `System.Speech` narration backend and fail-closed Windows semantics default.
- Nursery remains `paidEligibility: false`; teacher review, supervised child pilots, production billing and Android/Windows real-device qualification remain external gates.
- This source snapshot has not been re-versioned or marked released because Flutter/Dart build verification is still required in a Flutter-equipped environment.

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
