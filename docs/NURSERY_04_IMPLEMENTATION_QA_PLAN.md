# Nursery Upgrade — Implementation and QA Plan

## Existing architecture findings

Repository inspection found the following important boundaries:

- `ContentRepository` loads and validates exactly three integer `ContentPack`s for Classes 3, 4 and 5. Its validator rejects any other `classNumber` and enforces `c3_/c4_/c5_` IDs.
- `GameController` and `ChildProfileSnapshot.selectedClass` use integer 3–5 class selection. Existing `AttemptEvidence`, `ReviewTask`, diagnostics, missions and `ClassEntitlement` also carry integer class numbers.
- Current persistence is schema v5. `PlayerSnapshot.fromJson` already supports legacy single-child migration and v3/v2 storage fallback through the persistence layer.
- Current Class 3–5 content totals 63 authored/migrated activities and 37 learning blueprints per class. Runtime IDs and save keys are already stable.
- `LearningProgressEngine` separates independent, transfer and delayed-review evidence and does not need to be weakened for Nursery.
- `ActivityResponseEvaluator` is deliberately tied to current Class 3–5 `ContentActivity` rules/game payloads; expanding it with early-years-only rule shapes would increase regression risk.
- `BrightAudioService` already supplies Android TTS, installed voice selection, female-first choice, BGM/SFX/speech volume separation, prompt/choice reading, correct/wrong speech and BGM ducking.
- Windows audio is crash-isolated: MCI BGM/SFX + hidden-process `System.Speech`; the local Android-only `flutter_tts` fork prevents Windows DLL registration.
- `main.dart` disables Windows Flutter semantics by default and enables them only behind `BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY`.
- Existing widgets use responsive width breakpoints, large-text/high-contrast/reduced-motion state and active-page mounting to reduce Windows AXTree churn.
- Entitlements are fail closed for paid-eligible Classes: only current store/backend verification grants production access; persisted ownership is downgraded to cache-only.

These findings rule out representing Nursery as a fake integer class.

## Proposed architecture

Add a small parallel Nursery content adapter at the pack boundary while continuing to reuse shared product services:

```text
assets/content/nursery/
  nursery_schema_v1.json
  pack_v1.json

lib/core/nursery/
  nursery_models.dart
  nursery_content_repository.dart
  nursery_response_evaluator.dart
  nursery_practice_generator.dart
  nursery_progress_engine.dart

lib/features/nursery/
  nursery_home_screen.dart
  nursery_lesson_screen.dart
  nursery_interactions.dart
```

Nursery uses `packId: brightquest_nursery` and string skill IDs. Existing Classes 3–5 continue using `ContentRepository`, current curriculum IDs and integer evidence/entitlements unchanged.

Persistence is extended to schema v6 by adding `NurseryProgressState nurseryLearning` to each `ChildProfileSnapshot`. Old snapshots do not contain the field and decode to an empty Nursery state; no existing field is renamed, reinterpreted or deleted. The store key need not change because the JSON decoder is backward compatible.

Nursery commercial metadata is stored in its pack. `paidEligibility` is false. A stable `nurseryPackProductId` constant is added for future store mapping, but no production ownership is granted and no purchase action is enabled.

## Reusable components

Reused without replacement:

- `GameController` profile isolation/save queue and app-wide settings;
- `BrightAudioService` speech/SFX/BGM/voice selection and ducking;
- shared BrightQuest theme/design surfaces and responsive breakpoints;
- existing parent gate and class-pack parent surface;
- `main.dart` Windows semantics canary boundary;
- `third_party/flutter_tts_android` and Windows `System.Speech` backend;
- existing Android/Windows platform projects and dependencies.

New reusable Nursery components:

- response evaluator for choice/pair/sort/trace/memory interactions;
- deterministic generator with bounded early-math/pattern/letter families;
- progress engine that enforces independent + transfer + delayed review;
- one lesson screen that renders all Nursery skill flows from data;
- interaction widgets with touch/mouse and keyboard-accessible paths.

## Content and persistence changes

### Content

- Add schema v1 for Nursery pack and validate it in `tool/content/validate_nursery_content.dart`.
- Add one `pack_v1.json` containing 32 skill definitions and at least 128 authored scorable core activities.
- All content remains `needsReview`; reviewer owner is `nursery_teacher_reviewer` with no fabricated approval.
- Add a four-skill free-sample boundary in metadata.
- Generated practice is never serialized as authored content and always records the source Nursery skill in evidence.

### Persistence migration

- Increment `PlayerSnapshot.schemaVersion` from 5 to 6.
- Add `nurseryLearning` to `ChildProfileSnapshot.toJson`.
- `fromJson` treats absent/malformed Nursery state as empty default, preserving all legacy properties.
- Do not change `selectedClass`, `learning`, game progress, level progress, rewards or entitlement cache.
- Nursery evidence IDs include active profile ID and timestamp/sequence so profiles remain isolated.
- Corrupted Nursery subtrees fail to empty Nursery state rather than invalidating the existing child profile.

## File-by-file change map

| File or module | Change | Reason | Dependencies | Tests |
| --- | --- | --- | --- | --- |
| `docs/NURSERY_01_PRODUCT_PLAN.md` | complete product boundary/gates | make commercial/educational scope explicit | repository audit | doc review |
| `docs/NURSERY_02_CONTENT_PLAN.md` | 32-skill/content rules | define authored/generated coverage | content contract | content validator |
| `docs/NURSERY_03_EXPERIENCE_PLAN.md` | interaction/motion/audio/accessibility rules | prevent quiz-only implementation | shared UI/audio | widget tests |
| `docs/NURSERY_04_IMPLEMENTATION_QA_PLAN.md` | architecture/migration/QA map | implementation source of truth | all findings | release report |
| `assets/content/nursery/nursery_schema_v1.json` | versioned Nursery schema | separate from integer class schema | none | validator tests/tool |
| `assets/content/nursery/pack_v1.json` | 32 skills + ≥128 authored scorable records | reviewable learning content | schema | coverage/evaluator/widget tests |
| `pubspec.yaml` | register Nursery JSON assets; patch version | bundle offline pack | Flutter asset loader | app smoke |
| `lib/core/nursery/nursery_models.dart` | pack/skill/activity/evidence/progress models | string-keyed Nursery domain | none | serialization/migration tests |
| `lib/core/nursery/nursery_content_repository.dart` | load/validate/query pack | keep Nursery separate from Class 3–5 validator | rootBundle callback | repository tests |
| `lib/core/nursery/nursery_response_evaluator.dart` | choice/pair/sort/trace/memory rules | single correctness interpreter | Nursery models | evaluator tests for every rule |
| `lib/core/nursery/nursery_practice_generator.dart` | deterministic bounded practice | safe variation | Nursery models | generator determinism/bounds tests |
| `lib/core/nursery/nursery_progress_engine.dart` | independent/transfer/review mastery | prevent passive/retry mastery | Nursery models | mastery/review tests |
| `lib/core/models/progress_models.dart` | add `nurseryLearning`, schema v6 | profile-isolated persistence | Nursery models | v5→v6 migration tests |
| `lib/core/state/game_controller.dart` | Nursery getters/evidence/review mutation | reuse save queue/profile ownership | progress engine | controller persistence tests |
| `lib/core/entitlements/entitlement_models.dart` | add stable Nursery product ID constant only | future commercial mapping | none | entitlement/readiness tests |
| `lib/features/nursery/nursery_home_screen.dart` | domain/skill hub + due review | discoverable Nursery pack | repository/controller | responsive smoke tests |
| `lib/features/nursery/nursery_lesson_screen.dart` | teach→guided→independent→transfer flow | real teaching experience | audio/evaluator/generator/progress | flow tests |
| `lib/features/nursery/nursery_interactions.dart` | pair/sort/trace/choice widgets | purposeful interactions | Flutter | evaluator/widget tests |
| `lib/features/home/home_screen.dart` | add Nursery Learning Garden entry | child can enter without changing class | Nursery home | home smoke |
| `lib/features/parent/class_pack_screen.dart` | show disabled Nursery ₹299 planned card + blockers | parent-only commercial transparency | Nursery metadata/product ID | widget test |
| `tool/content/validate_nursery_content.dart` | static schema/coverage/generator checks | CI/release gate | Nursery core | command run |
| `tool/release/readiness_report.dart` | verify Nursery safety markers/paid=false/asset registration | prevent accidental commercial claim | pack files | readiness run |
| `test/nursery_response_evaluator_test.dart` | every response rule | required correctness coverage | evaluator | Flutter test |
| `test/nursery_practice_generator_test.dart` | seeds/options/bounds/duplicates | required generator coverage | generator | Flutter test |
| `test/nursery_progress_migration_test.dart` | passive/retry mastery + v5 migration/profile isolation | save compatibility/mastery integrity | controller/models | Flutter test |
| `test/nursery_widget_test.dart` | compact/tablet/Windows free-form + reduced motion | responsive/accessibility regression | Nursery UI | Flutter test |

## Implementation phases

| Step | Deliverable | Verification | Dependencies | Status |
| --- | --- | --- | --- | --- |
| 1 | complete four plans from repository audit | file review | none | Complete |
| 2 | Nursery schema/models/static pack | JSON + validator | step 1 | Implement in this change |
| 3 | evaluator + deterministic generator | focused unit tests | step 2 | Implement in this change |
| 4 | Nursery progress engine + schema-v6 migration | migration/mastery tests | step 2 | Implement in this change |
| 5 | Nursery hub/interactions/lesson flow | widget and flow tests | steps 2–4 | Implement in this change |
| 6 | audio/motion/accessibility integration | audio invariants + widget checks | step 5 | Implement in this change |
| 7 | parent commercial/readiness integration | paid=false/readiness checks | step 2 | Implement in this change |
| 8 | format/analyze/full tests/content tools | zero automated failures | steps 2–7 | Run where toolchain exists |
| 9 | Android release AAB | `flutter build appbundle --release` | step 8 + Android SDK | External environment gate |
| 10 | safe-default Windows release | `flutter build windows --release` without canary | step 8 + Windows host | Windows environment gate |
| 11 | semantics canary build/smoke | canary build + bounded startup; no production-default change | step 10 | Windows real-device gate |
| 12 | teacher/pilot/store/device sign-off | recorded real evidence | all above | External gate |

## Automated test matrix

Mandatory automated checks:

- Nursery schema parses and rejects wrong pack ID/version/missing skill/activity references.
- Exactly 32 skill IDs are unique and every skill has guided, 2 independent and transfer mastery-capable activities.
- Every authored option list has one answer and unique choices.
- Pair/sort rules reject incomplete/incorrect mappings.
- Trace rule accepts only ordered complete checkpoints and remains non-mastery.
- Every deterministic generator family is reproducible for at least 100 seeds/tier combinations.
- Generated counting ≤10; number recognition/sequence ≤20; addition total ≤10; no negative values; options unique.
- Passive objective/explanation/worked-example events cannot create evidence.
- Guided successes do not satisfy independent mastery count.
- Hint/retry success does not increment independent count.
- Two clean independent + one clean transfer create `masteredNow`, not `secure`.
- Delayed independent review is required before `secure`.
- v5 snapshot with no Nursery field loads as schema v6 with empty Nursery state and unchanged Class 3–5 values.
- Two child profiles keep Nursery progress isolated.
- Home/Nursery screens render without overflow at 360×640, tablet and large Windows sizes.
- Reduced motion removes finite transition movement but leaves content/answer controls usable.
- Existing full Class 3–5 test suite remains part of the gate.

## Android device matrix

Automated widget sizes are not a substitute for these real-device checks:

- 360×640 compact phone, portrait and landscape where supported;
- common 7–10 inch tablet size;
- Android free-form/resizable window sizes including narrow and medium widths;
- touch target, tracing drag, tap sorting, pair matching, read-aloud, speaker interruption;
- large text/high contrast/reduced motion;
- TalkBack labels/focus/order on Android;
- offline cold start, low-memory resume, sleep/resume;
- release AAB installation through a suitable test track.

## Windows free-form and accessibility matrix

Safe-default release:

- build without `BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY`;
- confirm `flutter_tts_plugin.dll` is not registered/bundled by project config;
- repeated narration uses `System.Speech` child process and BGM ducking recovers;
- mouse choices/matching/sorting/tracing work;
- keyboard can complete all mastery-required interactions;
- resize repeatedly from small free-form through desktop width;
- minimize/restore and sleep/resume soak.

Separate semantics canary:

- build/run with `--dart-define=BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY=true`;
- enable Narrator and navigate Home → Nursery → several activities;
- resize/minimize/restore while Narrator is active;
- exercise narration during/after resize and after sleep/resume;
- record OS/Flutter versions and native crash result;
- do not enable semantics in production based only on a bounded startup smoke test.

## Child pilot and teacher-review matrix

Teacher review must cover all 32 skills, every authored response rule, all phonics/word-picture examples, body/routine wording, generated-practice constraints and four free samples.

Supervised Nursery pilot should observe at least five children before commercial completion, recording only necessary usability/learning notes: instruction comprehension, target size, tracing motor difficulty, accidental taps, guessing, narration pace, wrong-answer reaction, whether transfer questions are genuinely new, and whether delayed review is understandable.

No reviewer/pilot cell may be marked passed without real evidence.

## Billing and release gates

Nursery release remains blocked while any of these is true:

- pack `paidEligibility` is false;
- any claimed skill/activity is not approved by a named qualified reviewer;
- child pilot is incomplete;
- `brightquest_nursery` product does not exist/configure as a permanent one-time purchase in the target store;
- pending/cancel/refund/revoke/restore/reinstall verification is incomplete;
- Android release qualification is incomplete;
- Windows safe-default native qualification is incomplete;
- Windows semantics has not separately passed canary criteria if anyone proposes enabling it.

The current implementation intentionally does not invent or bypass these gates.

## Risks and rollback plan

- **Risk: class-model regression.** Mitigation: Nursery never enters integer `selectedClass`, Class content validators or `ClassEntitlement`; old IDs remain untouched. Rollback removes only Nursery field/UI/assets while v6 decoder can continue ignoring absent data.
- **Risk: save corruption.** Mitigation: additive `nurseryLearning` field, default-empty decoder, unchanged existing keys. Corrupted Nursery subtree falls back without deleting Class 3–5 state.
- **Risk: mastery inflation.** Mitigation: progress engine ignores passive/guided/tracing-completion for independent threshold; retries/hints cannot count as independent.
- **Risk: generator impossible/duplicate answers.** Mitigation: finite catalogs/direct formulas/no retry loops plus seed sweep tests.
- **Risk: sensory/performance issues.** Mitigation: finite implicit motion only, reduced-motion static path, no repeating animations/timers.
- **Risk: Windows native crash.** Mitigation: no TTS plugin/semantics restoration; current isolation boundary untouched.
- **Risk: commercial overclaim.** Mitigation: all content stays `needsReview`, `paidEligibility=false`, parent UI says blocked, readiness tool fails any accidental paid-ready state without approval evidence.

## Definition of done

The coding portion is done when the Nursery pack is fully reachable in development, all 32 skills have real interactive teach/practice/transfer/review flows, deterministic practice is bounded, profile-isolated progress migrates safely, audio/accessibility safeguards are preserved, the parent commercial boundary is fail closed, and every requested automated check passes in a Flutter-capable environment.

Commercial readiness is a separate definition: teacher approval, supervised child pilot, production billing configuration and real Android/Windows qualification must all be recorded. This repository change must not claim those external gates are complete.

## Multi-example alphabet QA delta

Additional implementation/QA requirements for the expanded A–Z experience:

- `NurseryLetterAssociation` parses a backward-compatible `examples[]` list while retaining primary `word/picture/soundCue` getters for existing generator/UI callers.
- Every bundled letter now validates to at least eight examples and at least 200 unique `assets/nursery/letter_cards/` paths.
- `tool/content/validate_nursery_content.dart` must fail if a declared picture-card file is absent or duplicated.
- Word-picture review must deterministically vary across authored examples; beginning-sound review must only use explicitly eligible examples.
- Widget QA must reach the alphabet worked-example page at compact phone width and verify the multi-example discovery controls/finite animation render without overflow.
- Asset decoding must have a static text/pictogram fallback, and reduced motion must reduce the card switch/celebration transition to zero duration.

## Global play-board regression coverage

The Nursery UX regression suite must now assert that normal skill entry lands on `Choose your adventure` rather than a sequential `Next` page, that the discovery zone opens via selectable `Mission / Magic clue / Show me` cards, and that maths, My World, thinking, alphabet, matching, sorting and tracing receive the expected reusable game-portal identities. Phone, tablet and Windows free-form sizes must remain overflow-free. Reduced-motion checks must verify that portal/answer entrance animation is suppressed while all content remains usable. Matching and sorting must be checked for automatic final-placement submission so no separate form-style confirmation is required.

## Phase B automated gate — Letters & Sounds

Phase B must preserve the green Phase A baseline and additionally pass:

```powershell
dart format lib test tool
flutter analyze
flutter test
.\tool\qa\run_phase_b.ps1
```

The focused Phase B gate verifies the independently curated 157-example simple-phonics pool against the 208-card discovery catalog, deterministic sound/beginning-sound generation, tricky/advanced exclusions, skill-accurate game portal labels, accessible picture semantics, and overflow-free Alphabet boards at compact phone, tablet and Windows/free-form sizes. Q/X, alternate vowels, SH and initial consonant clusters must not re-enter simple Nursery phonics mastery without a deliberate reviewed policy change and corresponding QA-reference revision.

## Phase C automated gate — Math & My World

Phase C must preserve the verified Phase A + Phase B baseline and additionally pass:

```powershell
dart format lib test tool
flutter analyze
flutter test
.\tool\qa\run_phase_c.ps1
```

The focused Phase C gate independently checks early-number bounds, visible-object counts, number↔quantity pairs, missing-number sequences, more/less and same/different comparisons, addition totals capped at 10, all authored My World answers, generated picture→word mappings, visual/text/audio synchronization, profile-aware review seed advancement and non-repetition windows across all 32 Nursery skills. Count and My World quiz widget integration must show and score the same answer, with the explanation tied to the current activity rather than a generic worked example.

## Phase D automated gate — Polish & Release Candidate

Phase D must preserve the verified Phase A + Phase B + Phase C baseline and additionally pass:

```powershell
dart format lib test tool
.\tool\qa\run_phase_d.ps1
```

The default Phase D gate performs the final technical regression sweep,
localization consistency review, accessibility stress checks at the supported
1.3 text scale/high-contrast/reduced-motion settings, source/runtime
performance-budget checks, the full Flutter suite and analyzer. The Phase D
runner has no artifact-build switches. Android AAB and Windows generation use
separate packaging commands. A green automated Phase D is QA evidence only.
Teacher/content sign-off, supervised
child pilot evidence, production billing/store verification, privacy/store
review, real Android device qualification and native Windows
crash/Narrator/accessibility soak remain external gates and may not be inferred
from automated success.
