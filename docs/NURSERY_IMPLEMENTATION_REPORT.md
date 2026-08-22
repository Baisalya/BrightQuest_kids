# Nursery Implementation Report

## Source status

This source tree contains the BrightQuest Nursery implementation as a separate `brightquest_nursery` pack. Nursery is not inserted into the legacy integer Class 3–5 selection/entitlement namespace. Existing Windows TTS plugin registration, crash-isolated `System.Speech` narration files, Windows runner files and `lib/main.dart` semantics safety path are unchanged from the supplied baseline.

## Implemented Nursery surface

- 32 Nursery skills and 132 authored activities across alphabet/phonics, early maths, My World and thinking/observation.
- Guided → independent → transfer → delayed-review evidence flow; passive teaching/discovery does not establish mastery.
- Dedicated Nursery response evaluator, deterministic generated review/practice and profile-scoped Nursery evidence/mastery/review persistence.
- Additive save-schema v6 migration while legacy `selectedClass` remains 3–5 only.
- Touch/mouse tracing with broad guide checkpoints; tracing is non-mastery and makes no handwriting-correctness claim.
- Existing narration service reused for instructions, answer choices and feedback; no unsafe Windows `flutter_tts` registration was restored.
- Responsive Nursery hub/lesson UI for compact, tablet and desktop/free-form layouts.

## Expanded A–Z discovery

- 26 uppercase/lowercase letter records.
- Multiple authored discovery examples per letter, 208 examples total.
- 208 bundled local PNG picture cards under `assets/nursery/letter_cards/` plus Unicode/text fallbacks.
- Example flow includes `A: Apple → Ant → Aeroplane`, `B: Ball → Banana → Bird`, `C: Cat → Car → Cup`.
- Nursery lesson worked examples expose **Hear it**, **Another word** and **Next letter** controls.
- The hub Letter Garden cycles to another picture word on repeated taps.
- Beginning-sound generation only uses examples explicitly marked `beginningSoundEligible`; exceptional spellings can be explored without being mis-scored as simple beginning-sound evidence.
- Letter/word switches and correct-answer celebrations use finite one-shot implicit/tween animation. Reduced Motion uses zero-duration/static behavior. No repeating Nursery animation controller/timer was added.

## Commercial safety

Nursery remains `paidEligibility: false`. The planned one-time price remains ₹299, but source metadata does not claim teacher approval, child-pilot completion, billing configuration or device qualification.

## Verification performed in this environment

Passed static checks:

- Nursery JSON parses successfully.
- 26 A–Z records are present in order.
- 208 discovery examples/assets are declared and every referenced PNG exists.
- all declared discovery asset paths are unique.
- all `beginningSoundEligible` examples begin with the recorded letter; X has no simple beginning-sound-eligible example.
- 32 skills and 132 activities remain present.
- `paidEligibility` and every external release gate remain false.
- Nursery letter-card directory is registered in `pubspec.yaml`.
- changed Dart files passed delimiter-balance sanity checks.

## Verification unavailable here

The current execution environment does not contain Flutter or Dart executables, so the following are **not claimed as passed**:

- `dart format` using the official formatter;
- `flutter analyze`;
- complete `flutter test`;
- Android release AAB build;
- safe-default Windows release build;
- Windows semantics-canary build/startup smoke;
- real Android phone/tablet and Windows free-form interaction qualification.

The repository contains tests/tools for the new Nursery evaluator, generators, save migration, content integrity, assets and responsive discovery UI, but they still need to be executed in a Flutter-equipped environment.

## External gates still pending

- qualified teacher/content review;
- supervised child pilots;
- production Google Play / Microsoft Store billing configuration and verification;
- Android real-device qualification;
- Windows real-device/free-form qualification;
- Windows Narrator + resize + sleep/resume semantics-canary qualification;
- final store/release review.

## Global game-board UX expansion

A global Nursery play-board shell now replaces the previous sequential teaching/activity page chain. This applies to Letters & Sounds, Early Maths, My World, and Think & Notice rather than only alphabet lessons. Children choose animated mini-game portals, return to the board after completing a game, and can independently choose another activity. Domain and interaction mappings provide reusable game identities (`Number Hunt`, `Math Mission`, `Picture Hunt`, `World Quest`, `Puzzle Pop`, `Brain Boost`, `Match Magic`, `Sort Safari`, `Trace Trail`) without hardcoding separate screens for every skill.

The change is presentation/navigation only with respect to evidence integrity: authored activity IDs, response evaluators, mastery eligibility, delayed review scheduling, persistence, entitlement boundaries, and Classes 3–5 remain unchanged. Matching/sorting now auto-submit on the final placement, reducing form-style confirmation clicks. Motion remains finite and has reduced-motion fallbacks.

## Phase B — Letters & Sounds correctness hardening

Phase B keeps all 208 A–Z discovery cards but limits simple letter-sound / beginning-sound evidence to 157 independently curated examples. Irregular or advanced relationships stay visible for vocabulary and letter discovery without being allowed to count as simple phonics mastery. The exclusions explicitly cover alternate/irregular vowel onsets, Q/U patterns, X patterns, `SH`, and initial consonant clusters.

A new independent `NurseryPhonicsAudit` cross-checks JSON eligibility flags against a separate QA reference, audits generated sound practice over deterministic seeds, prevents Q/X from entering simple onset mastery, and fails if advanced words are narrated as simple first-sound evidence. Alphabet play-board names are now skill-specific instead of labelling every transfer activity as a sound quest. The same pass replaces 13 obvious picture-word mismatches with dedicated local illustrations (including Igloo, Vacuum, Ukulele, Vulture and Yak) and safe text fallbacks.


The Phase B Windows gate is `tool/qa/run_phase_b.ps1`, which first re-runs the verified fail-fast Phase A baseline and then runs the focused phonics simulator, Phase B unit/widget regressions and `flutter analyze`. Automated success does not replace qualified teacher review, child pilots or real-device audio/accessibility qualification.

## Phase C — Math & My World correctness hardening

Phase C adds an independent Math/My World reference and `NurseryMathWorldAudit`. It checks all Nursery Math and My World skills, all 28 authored My World answers, generated counting/arithmetic correctness, generated picture→word mappings, stable speech equivalents for visual tokens, and deterministic non-repetition windows across every Nursery skill.

The generated-practice engine now cycles through bounded pools for number recognition, counting, number↔quantity, missing numbers, comparison, addition, colours, shapes, My World vocabulary, routines and thinking review. A profile-aware `NurseryReviewSeedPlanner` advances from the last generated review seed instead of deriving every review from the calendar, preventing accidental replay collisions while preserving deterministic generation and existing evidence rules.

Math/My World audio now normalizes visual symbols before TTS so `🍎🍎`, `🔴`, `▲`, `🐱` and similar screen content have stable spoken equivalents on Android/Windows. My World wording was tightened where a child could otherwise learn an imprecise rule, including the 2D door-face example, an end-of-each-leg feet clue, farm-animal clue, a concrete get-dressed morning routine and adult-supervised road crossing. Counting visuals are spoken item-by-item rather than converted to the numeric answer, preventing TTS from solving a counting task for the child.

The Phase C Windows gate is `tool/qa/run_phase_c.ps1`. It re-runs verified Phase B (and therefore Phase A), runs the focused Phase C simulator, Count/Quiz integration tests, the full Flutter suite and static analysis. External teacher, child-pilot, billing and device gates remain pending by design.

## Phase D — Polish & Release Candidate implementation

Phase D adds a final fail-fast technical release-candidate gate on top of the verified Phase A–C learning-correctness baseline. The new static audit reviews authored locale/narration completeness, fail-closed external release state, finite Nursery motion, A–Z source-art budgets and offline/no-analytics dependency boundaries. The A–Z Letter Garden now requests 128×128 decode-cache thumbnails for its 512×512 source cards so 26 simultaneously reachable cards do not require full-size image decodes. New widget QA stresses representative Alphabet, Math, My World and Thinking screens at compact phone, tablet and Windows/free-form sizes with maximum supported text scale, high contrast, dyslexia-friendly spacing and reduced motion. The Windows Phase-D runner also builds the Android release AAB and the normal crash-isolated Windows release candidate after all tests/analyzer gates pass.

This implementation does not mark commercial eligibility or any human/device gate as complete. Qualified teacher review, supervised child pilot evidence, production purchase verification, privacy/store review, Android real-device qualification and native Windows/Narrator soak remain pending until independently recorded.
