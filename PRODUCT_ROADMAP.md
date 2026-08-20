# BrightQuest Kids — ₹299 Per-Class Product Roadmap

- Status: approved implementation sequence
- Current application: `0.6.0+26`
- Targets: Android phone/tablet/free-form and Windows desktop
- Commercial model: one-time purchase of ₹299 for each class pack

## 1. Product promise

BrightQuest must not be a collection of colourful quizzes. A paid class pack must help a child learn a concept, practise it in different contexts, remember it later, and give a parent understandable evidence of progress.

Each purchased class pack should eventually include:

- curriculum-mapped Maths, English and integrated EVS/Science/Social learning;
- computational-thinking activities as a bonus learning world;
- an initial diagnostic that does not punish the child;
- short teaching cards and worked examples before difficult practice;
- manipulatives, simulations, stories and applied problems—not only multiple choice;
- adaptive guided practice based on observed misconceptions;
- mastery checks containing unseen questions;
- spaced review after 1, 3, 7, 14 and 30 days;
- a parent skill report that explains what the child can do and what to practise next;
- complete offline learning after the pack is installed;
- no advertisements, social feed, chat, manipulative streak pressure or child-facing purchase prompts.

The ₹299 is a permanent class entitlement, not a recurring subscription. The parent area owns all purchase and restore actions.

## 2. Educational foundation

The curriculum system must be mapped to official learning outcomes but must not claim CBSE/NCERT certification unless a qualified reviewer and the relevant authority support that claim.

Use these primary references when building the curriculum matrix:

- [National Curriculum Framework for School Education 2023](https://www.education.gov.in/sites/upload_files/mhrd/files/ncf_2023.pdf): competencies should be observable and learning outcomes should be granular milestones leading to them.
- [NCERT Learning Outcomes at the Elementary Stage](https://www.ncert.nic.in/pdf/publication/otherpublications/tilops101.pdf): source outcomes for primary Mathematics, Languages and EVS.
- [CBSE Competency-Based Education](https://cbseacademic.nic.in/cbe/index.html): learning should demonstrate application, real-world problem solving and proficiency rather than rote recall.
- [CBSE SAFAL](https://cbseacademic.nic.in/safal/index.html): Grades 3 and 5 assessment should cover core concepts, application and higher-order thinking and produce diagnostic information.
- [CBSE Computational Thinking and AI](https://cbseacademic.nic.in/ct-ai.html): use the current Grades 3–5 framework when expanding Robot City.

Every content record must carry its source mapping, author/reviewer status and revision number. “Aligned” is an internal mapping statement; it is not a certification badge.

## 3. Current baseline and gaps

The existing application already has strong foundations:

- local child profiles, save migration and parent PIN;
- Class 3, 4 and 5 selection;
- eight curriculum topics and 24 Practice/Challenge/Mastery levels per class;
- adaptive Quick Play, mastery, rewards, time limits and progress views;
- responsive Android/free-form/Windows UI;
- offline BGM/SFX and crash-isolated Windows narration;
- 60 automated tests and working Android/Windows builds.

The gaps preventing a ₹299 learning-value claim are:

- only eight broad curriculum topics per class;
- most banks contain roughly 6–12 fixed activities per game/class;
- limited direct teaching or worked examples before assessment;
- heavy dependence on choice chips, sorting and fixed-answer interactions;
- progress stores attempts and correctness but not misconception, independence, response time, confidence, review due date or evidence source;
- the same three-stage shell is generated for every topic even when the pedagogy should differ;
- no diagnostic placement, spaced-repetition queue or unseen transfer check;
- no human-review workflow or automated content linter;
- no class-pack entitlement, billing or purchase restoration;
- Windows Flutter accessibility semantics remain disabled because of a native engine crash.

## 4. Required learning loop

Every substantive skill must follow this state sequence:

```text
Discover → Explain → Guided Try → Independent Practice → Mastery Check
     ↑              misconception feedback             ↓
     └──────────── targeted reteach ←────────────── not mastered
                                                        ↓
                                      spaced review and transfer task
```

A level is not “mastered” because the child eventually found the answer after unlimited retries. Mastery requires:

1. at least two independent correct responses;
2. one unseen or differently worded transfer item;
3. no hint on the final mastery evidence;
4. a confidence score above the skill threshold;
5. successful later review before “secure” mastery is shown.

Suggested evidence states:

- `notStarted`;
- `introduced`;
- `practising`;
- `masteredNow`;
- `reviewDue`;
- `secure`;
- `needsSupport`.

## 5. Content target for each ₹299 pack

These are release targets, not current counts:

- 30–40 clearly defined core competencies per class;
- 36–48 learning units per class across all worlds;
- 5–8 meaningful encounters per competency;
- at least 1,000 generated item variations per class, backed by reviewed templates;
- at least 150 human-written contexts, explanations, passages, experiment scenarios and map/story prompts per class;
- 20+ hours of non-repetitive core learning and review;
- a free sample containing one complete unit from each major subject before purchase;
- all purchased core content usable offline.

Variation must come from controlled item templates and parameter constraints. Randomly changing numbers without checking difficulty, wording and distractors does not count as new learning content.

## 6. Target architecture

Move curriculum data out of one large Dart file and into versioned, validated class packs.

```text
assets/content/
  shared/
    schema.json
    vocabulary.json
  class_3/
    pack.json
    maths/*.json
    english/*.json
    evs/*.json
    coding/*.json
  class_4/
  class_5/

lib/core/learning/
  content_repository.dart
  diagnostic_engine.dart
  lesson_engine.dart
  evidence_engine.dart
  mastery_engine.dart
  review_scheduler.dart
  recommendation_engine.dart

lib/core/entitlements/
  entitlement_models.dart
  entitlement_service.dart
  store_billing_gateway.dart

tool/content/
  validate_content.dart
  coverage_report.dart
  duplicate_detector.dart
```

Core models to add:

- `ClassPack` and `PackVersion`;
- `LearningOutcome` and `Competency`;
- `LessonUnit` and `LearningObjective`;
- `ActivityDefinition` and `QuestionTemplate`;
- `Distractor` with misconception mapping;
- `AttemptEvidence`;
- `SkillMastery`;
- `ReviewTask`;
- `ClassEntitlement`.

Every activity definition must include:

- stable ID and class;
- subject, unit, competency and learning-outcome IDs;
- activity type and difficulty band;
- prompt, correct-response rule and explanation;
- distractors mapped to likely misconceptions;
- hint ladder;
- narration text or safe narration source;
- locale/language metadata;
- author, reviewer, review status and revision;
- deterministic seed rules where generation is used.

## 7. Implementation phases

### Phase 0 — Product and curriculum contract

Goal: establish what each class pack teaches before adding more screens.

Work:

- build a class-by-class curriculum spreadsheet or JSON matrix from the official references;
- identify 30–40 core competencies for each of Classes 3, 4 and 5;
- map current games and activities to those competencies;
- mark every gap, duplicate and out-of-class item;
- define reading-level, vocabulary and number-range rules per class;
- define mastery thresholds and the evidence rubric;
- recruit a qualified primary teacher/content reviewer and record review ownership;
- approve the free sample and paid-pack boundaries.

Deliverables:

- `assets/content/curriculum_map.json`;
- content schema v1;
- reviewer checklist;
- automated coverage report showing mapped, missing and unreviewed competencies.

Exit gate:

- 100% of current content has a competency mapping or is explicitly marked for removal;
- no paid-pack claim is made for unreviewed content;
- class boundaries and learning objectives are approved.

Implementation status (2026-08-20):

- **Technical Phase 0 implementation complete:** `curriculum_map.json` contains 37 draft competencies for each class; every currently reachable class/game/topic selector is mapped; content schema v1, reviewer metadata/states, current-content audit, coverage validator/report and Phase 0 tests are implemented.
- **Backward compatibility preserved:** existing game/content banks, curriculum-topic IDs, 72 learning-level IDs, schema-v4 progress/profiles/rewards/parent-control saves, and Windows narration/semantics safety paths are unchanged by Phase 0.
- **Commercial review remains blocked:** all new curriculum material is `needsReview`, class/free-sample boundaries are `pendingHumanReview`, and `paidEligibility` is `false` for every class pack.
- **Human review is still pending:** a real qualified primary teacher/content reviewer has not yet been recorded as approving the Class 3–5 boundaries/objectives. The project owner explicitly authorised technical Phase 1 foundation work on 2026-08-20; that authorisation does not convert curriculum review status to approved or unlock paid eligibility.

### Phase 1 — Scalable content-pack foundation

Goal: make content expandable and testable without editing game UI code.

Work:

- implement `ContentRepository` with bundled JSON loading and schema validation;
- migrate existing question banks from `game_content.dart` into class-pack assets;
- keep existing stable IDs so current progress can migrate;
- build deterministic generators for arithmetic, fractions, grammar and map directions;
- build the content validator, duplicate detector and coverage report;
- reject missing explanations, invalid distractors, duplicate IDs and impossible generated questions during CI;
- add development-only pack locking so entitlements can be tested before billing exists.

Tests:

- every JSON pack parses;
- every referenced competency exists;
- every generated item has one valid solution;
- distractors are unique and never equal the answer;
- deterministic seeds reproduce the same activity;
- old progress IDs migrate safely.

Exit gate:

- the application runs entirely from the new repository;
- no game depends on a hard-coded class question bank;
- content validation is part of the normal test gate.

Implementation status (2026-08-20):

- **Technical Phase 1 implementation complete:** all 189 current authored learning records are stored in separate Class 3/4/5 packs and loaded through `ContentRepository`; `game_content.dart` now contains models only and all eight learning-game screens resolve content through the repository.
- **Validation foundation implemented:** schema/reference/class-boundary checks, explanation/distractor rules, coding-route solvability, deterministic arithmetic/fraction/grammar/map generators, duplicate reporting, coverage reporting and a standalone content-validation command are present.
- **Compatibility preserved:** existing curriculum-topic IDs, all 72 learning-level IDs and schema-v4 progress/profile/reward/parent-control data remain unchanged; no save migration is required for this content-storage refactor.
- **Development entitlement simulation only:** class-pack locks can be enabled with debug dart-defines; no billing SDK, child purchase prompt or production entitlement state was added in Phase 1.
- **Commercial review remains blocked:** migrated content remains `needsReview` and all packs retain `paidEligibility: false` pending genuine reviewer approval.
- **Runtime QA gate must be recorded from a Flutter-capable environment:** `dart format`, `flutter analyze`, `flutter test` and the content tools are required before Phase 1 is marked fully passed.

### Phase 2 — Diagnostic and evidence engine

Goal: discover what a child knows and why an answer was wrong.

Work:

- add a friendly 10–15 minute first-run diagnostic per class;
- sample prerequisite, on-grade and stretch items without showing a harsh score;
- record `AttemptEvidence` with competency, item, correctness, hint use, retries, response time and misconception ID;
- initialise each skill as support/ready/strong from multiple pieces of evidence;
- update recommendations after each session;
- keep all evidence local and profile-isolated;
- add save schema migration and corruption fallback.

Rules:

- one answer must never label a child weak;
- response time is supporting evidence, not a standalone ability judgement;
- hints reduce independence evidence but never remove earned learning progress;
- the diagnostic can be paused and resumed.

Exit gate:

- two children with different diagnostic answers receive different starting recommendations;
- parents can see “ready”, “learning” and “needs support” without ranking children;
- migration and profile-isolation tests pass.


Implementation status (2026-08-20):

- **Technical engine implemented:** resumable class diagnostic, profile-isolated `AttemptEvidence`, misconception/hint/retry/response-time/confidence evidence, multi-evidence diagnostic bands, recommendations and schema-v5 learning state are present.
- **Backward migration protected:** v5 storage reads the accepted Phase 1 `.v3` preference key before legacy `.v2`, while older profile/root snapshots migrate through `PlayerSnapshot.fromJson`.
- **No one-answer weakness label:** support classification requires multiple evidence items; response time is stored only as supporting evidence.
- **Runtime gate pending Codex/Flutter QA:** analyzer, full Flutter tests and device persistence tests still need to run in a Flutter-capable environment.
### Phase 3 — Teach, practise, explain and master

Goal: turn each game from a quiz into a learning experience.

Work:

- add a reusable lesson flow: objective, short explanation, worked example, guided try, independent practice and exit ticket;
- add two-level hints: conceptual cue first, worked step second;
- make wrong-answer narration explain the misconception instead of only revealing the result;
- require unseen transfer items for mastery;
- add targeted reteach cards after repeated errors;
- provide “Show me why” after every result;
- let children replay explanations without losing progress;
- keep sessions in 5–12 minute chunks.

New interaction primitives:

- number line and base-ten blocks;
- fraction strips/pizza comparison;
- drag-to-order sentence and paragraph events;
- highlight evidence in a reading passage;
- label/classify diagrams;
- predict-observe-explain science simulation;
- map path/direction tracing;
- coding trace and debugging panels.

Exit gate:

- each launchable paid unit contains teaching and assessment;
- at least 40% of mastery evidence is not standard multiple choice;
- wrong answers always produce actionable feedback;
- a child cannot achieve secure mastery by repeated guessing.


Implementation status (2026-08-20):

- **Technical lesson engine implemented:** objective, explanation, worked example, guided try, independent practice, transfer, exit, reteach and review steps are generated per competency with two-level hints and “Show me why” support.
- **Gameplay evidence wired:** existing games now record competency/item evidence, hint/retry independence and misconception metadata without changing legacy progress IDs.
- **Accessible interaction primitives added:** number line, base-ten, fraction strip, keyboard-operable ordering, evidence highlighting, diagram classification, predict-observe-explain, map path and coding trace primitives are available for reviewed content.
- **Commercial exit gate not claimed:** current curriculum/content remains `needsReview`; paid eligibility is false, and the non-MCQ/mastery-quality target must be verified after reviewed class content is authored.
### Phase 4A — Class 3 complete pack

Goal: produce the first commercially complete vertical slice.

Priority content:

- Maths: place value, addition/subtraction strategies, multiplication/division foundations, measurement, time, money, shapes, patterns, data and basic fractions;
- English: reading comprehension, sentence meaning, vocabulary in context, nouns/pronouns/verbs/adjectives, tense foundations, punctuation and short composition;
- EVS: family/community, food/water/shelter, plants/animals, materials, travel/directions, safety, waste and local environment;
- Coding: sequences, events, patterns, simple loops and debugging.

Work:

- author reviewed contexts, explanations, distractors and hints;
- add voice-safe text for children who use narration;
- run the content linter and teacher review on every unit;
- conduct five-child supervised usability sessions before calling the pack complete.

Exit gate:

- all Class 3 target competencies have teach/practice/master/review coverage;
- no blocking reading or interaction issue at 360×640;
- teacher reviewer signs off the release matrix;
- unseen pre/post pilot items show a positive learning trend; no public efficacy claim is made from a tiny pilot.


Implementation status (2026-08-20):

- **Technical Class 3 coverage scaffold implemented:** all 37 Class 3 competencies have structured teach/guided/independent/transfer/review blueprints and remain linked to the existing stable content repository.
- **Not commercially complete:** blueprints are technical drafts, not teacher-reviewed authored lessons. Five-child usability sessions, reviewer sign-off, full 20+ hour/content-volume targets and pre/post pilot evidence remain pending.
### Phase 4B — Class 4 complete pack

Goal: apply the proven Class 3 system to Class 4 without copying content upward.

Priority content:

- larger-number operations and multi-step problems;
- factors/multiples foundations, fractions, geometry, perimeter, measurement and data;
- reading inference, paragraph order, grammar in context, vocabulary and guided writing;
- matter, force, living systems, resources, India/map skills and evidence-based EVS reasoning;
- algorithms, loops, condition-like reasoning and debugging.

Exit gate:

- independent coverage and reviewer sign-off for Class 4;
- no Class 3 item is reused unless deliberately marked as prerequisite review;
- diagnostic correctly routes prerequisite gaps to support lessons.


Implementation status (2026-08-20):

- **Technical Class 4 coverage scaffold implemented:** all 37 Class 4 competencies have separate class-bound teach/guided/independent/transfer/review blueprints; cross-class content boundaries remain validated.
- **Not commercially complete:** independent teacher review, full authored content-volume targets, prerequisite-routing validation on real children and release sign-off remain pending.
### Phase 4C — Class 5 complete pack

Goal: deliver the deepest pack and prepare children for the middle-stage transition.

Priority content:

- operations, fractions/decimals, factors/multiples, geometry, measurement, data and multi-step application;
- deeper comprehension, evidence, vocabulary, grammar, paragraph and short composition;
- human body, plants, materials/changes, simple machines, environment, India/geography and inquiry skills;
- efficient algorithms, repeats, decomposition, debugging and introductory AI concepts from the current CBSE framework.

Exit gate:

- independent coverage and reviewer sign-off for Class 5;
- mastery checks include application and higher-order items similar in intent—not copied content—to SAFAL-style competency assessment;
- transition-readiness report identifies prerequisite gaps without exam coaching language.


Implementation status (2026-08-20):

- **Technical Class 5 coverage scaffold implemented:** all 37 Class 5 competencies have separate teach/guided/independent/transfer/review blueprints and application-oriented mission support.
- **Not commercially complete:** reviewed higher-order item authoring, transition-readiness content review, pilot evidence and reviewer sign-off remain pending. No SAFAL/CBSE/NCERT certification claim is made.
### Phase 5 — Spaced review and durable mastery

Goal: help the child remember after the game session.

Work:

- add `ReviewScheduler` with 1/3/7/14/30-day intervals;
- shorten or lengthen intervals using evidence quality;
- create a daily mixed “Power Review” of 5–10 items;
- interleave subjects and old/new skills;
- mark mastery as `reviewDue` when retention evidence is missing;
- add gentle catch-up after missed days; never punish broken streaks;
- provide offline reminders only through a parent-approved setting.

Exit gate:

- review queues survive restarts and profile switching;
- due-item ordering is deterministic and bounded;
- a skill becomes `secure` only after delayed success;
- clock/date edge cases have automated tests.


Implementation status (2026-08-20):

- **Technical review engine implemented:** deterministic 1/3/7/14/30-day scheduling, bounded due queues, restart/profile persistence through schema v5, Power Review UI and delayed-evidence secure mastery are present.
- **No streak punishment:** missed review remains a due task rather than removing progress or rewards. Parent-controlled notification delivery remains a platform/release integration task.
### Phase 6 — Deeper game missions and projects

Goal: make knowledge usable beyond isolated questions.

Add multi-skill missions such as:

- plan a market budget and calculate change;
- design equal pizza portions and compare two sharing plans;
- investigate a science claim using predict-observe-explain;
- read a short story, infer motives and rebuild the event sequence;
- navigate an India map using scale/direction clues;
- audit household waste and propose a better sorting plan;
- debug a robot program and explain the correction.

Rules:

- each mission combines two or more competencies;
- scoring separates correctness, strategy, independence and explanation;
- the mission gives a worked reflection after completion;
- projects use only safe local input—no public uploads or child chat.

Exit gate:

- every major subject has at least three multi-skill missions per class;
- project evidence appears in the parent report;
- missions work offline and across all supported window sizes.


Implementation status (2026-08-20):

- **Technical mission catalog implemented:** each of the six major subject groupings receives three local multi-competency missions per class, with correctness/strategy/independence/explanation reflection dimensions.
- **Safety boundary implemented:** mission input is local-only; child reflections are persisted as unverified project evidence and cannot independently create secure mastery.
- **Content/reviewer gate pending:** these mission briefs are draft scaffolds requiring authored interactions, teacher review and responsive real-device QA before commercial completion.
### Phase 7 — Parent learning evidence

Goal: make the ₹299 value visible without turning the app into surveillance.

Work:

- add a competency grid by subject and unit;
- show evidence counts, current state, last practice and next review;
- explain common misconceptions in plain parent language;
- provide a weekly summary: learned, retained, needs support and suggested five-minute activity;
- distinguish activity time from demonstrated learning;
- add local PDF/print export only after layout and privacy review;
- never compare siblings or publish leaderboards.

Exit gate:

- every recommendation links to evidence and an available activity;
- parent reports avoid misleading averages from tiny samples;
- exported reports contain no hidden identifiers or purchase tokens.


Implementation status (2026-08-20):

- **Technical parent evidence report implemented:** competency state, evidence count, last practice, next review, plain-language misconception notes, weekly learning summary and project evidence are available behind the existing parent gate.
- **Privacy-conservative export:** PDF/print export is deliberately disabled until layout/privacy review; no sibling ranking or leaderboard was added.
### Phase 8 — Language, accessibility and inclusive learning

Goal: let more children learn independently.

Work:

- keep English first, then add Hindi UI/narration/content only through reviewed translations;
- store text and narration separately from game logic;
- add dyslexia-friendly spacing and reading focus options without claiming medical treatment;
- complete keyboard/focus navigation and screen-reader labels on Android;
- track the Flutter Windows semantics crash and restore semantics only after an engine/plugin soak proves stability;
- keep the isolated Windows narration backend even when semantics returns;
- add captions/transcripts for every meaningful audio cue;
- test large text, high contrast, reduced motion and colour-independent feedback.

Exit gate:

- accessibility checks are automated where Flutter supports them;
- every learning action is possible without relying only on colour, sound or drag;
- language packs cannot mix answers across locales;
- Windows accessibility restoration passes native soak testing before release.


Implementation status (2026-08-20):

- **English-first accessibility foundation implemented:** captions/transcripts, dyslexia-friendly spacing, reading-focus preference, large-text/high-contrast/reduced-motion compatibility hooks and keyboard-friendly alternatives for new primitives are present.
- **Hindi remains blocked pending reviewed translations:** locale state does not allow a mixed or unreviewed Hindi pack.
- **Windows safety preserved:** Flutter Windows semantics remains disabled because of the known native crash path, and crash-isolated Windows narration remains in place. Native soak is mandatory before semantics restoration.
### Phase 9 — ₹299 class entitlements and store billing

Goal: sell permanent class packs safely and restore ownership reliably.

Product IDs:

- `brightquest_class_3`;
- `brightquest_class_4`;
- `brightquest_class_5`.

Android implementation:

- use Google Play one-time **non-consumable** products for permanent class access;
- fetch store-localised product details instead of hard-coding the displayed currency/price;
- handle pending, purchased, cancelled, refunded and restored states;
- acknowledge completed purchases;
- prefer backend purchase verification before granting durable entitlement;
- provide Restore Purchases in the parent area;
- never place purchase buttons in the child flow.

Google Play requires its billing system for Play-distributed digital content, and its current one-time-product model supports permanent non-consumable access: [payments policy](https://support.google.com/googleplay/android-developer/answer/9858738), [one-time products](https://developer.android.com/google/play/billing/one-time-products), and [purchase lifecycle](https://developer.android.com/google/play/billing/lifecycle/one-time).

Windows implementation:

- use Microsoft Store durable add-ons if distributed through the Store;
- restore durable ownership from `Windows.Services.Store`;
- keep product IDs mapped to the same internal `ClassEntitlement` values;
- use a signed licence mechanism only for non-Store distribution.

Microsoft documents durable add-ons as persistent purchases: [Windows in-app purchases and trials](https://learn.microsoft.com/en-us/windows/uwp/monetize/in-app-purchases-and-trials).

Important cross-platform rule:

- an Android store purchase does not automatically prove Windows ownership;
- true Android↔Windows entitlement sharing requires a parent account and secure backend purchase verification;
- until that backend exists, clearly state that ownership restores through the store where it was purchased.

Exit gate:

- purchase, pending, cancellation, refund/revocation and restore tests pass;
- reinstall restores the purchased class;
- no local preference edit can unlock a production pack;
- parent gate protects every transaction;
- free sample remains playable without purchase.


Implementation status (2026-08-20):

- **Entitlement contract and parent UX implemented:** stable Class 3/4/5 product IDs, permanent-class entitlement models, purchase/restore gateway abstraction, pending/owned/revoked states, free-sample boundaries and parent-only class-pack controls are present.
- **Fail-closed production security:** local persisted ownership is downgraded to cache-only and cannot unlock production content; only current store/backend verification can grant access.
- **Production billing integration remains pending:** no Google Play/Microsoft Store entitlement is fabricated. Real product configuration, purchase acknowledgement/backend verification, refund/revocation and reinstall/restore testing require store credentials and closed-track/native integration.
### Phase 10 — Child safety, release quality and evidence pilot

Goal: release a trustworthy children’s product, not only a technically working build.

Work:

- remain ad-free and avoid `AD_ID`;
- publish a plain-language privacy policy and accurate Play Data Safety answers;
- collect no child name, voice, location, contacts or advertising identifier unless a later feature has a reviewed necessity and consent design;
- review all SDKs against current Google Play Families requirements;
- run content, accessibility, billing, offline, migration and native-crash QA;
- test low-memory Android devices, free-form resizing, sleep/resume and corrupted saves;
- conduct a supervised pilot with consent and unseen pre/post items;
- use results to improve the product, not to make unsupported learning claims.

Current Google Play policy requires child-targeted apps to follow Families requirements and accurately declare audience, data safety and content: [Families policy](https://support.google.com/googleplay/android-developer/answer/17190352) and [target audience settings](https://support.google.com/googleplay/android-developer/answer/9867159).

Exit gate:

- `flutter analyze` is clean;
- all unit/widget/content/migration/billing tests pass;
- Android release app bundle and Windows release build pass;
- real-device Android and native Windows soak tests pass;
- store listing, screenshots, privacy policy, support email and reviewer instructions are ready;
- content reviewer signs the release pack;
- no “improves marks” or “board certified” claim is published without sufficient evidence.


Implementation status (2026-08-20):

- **Technical release-safety foundation implemented:** no-AD_ID checks, privacy policy draft, Families/data-safety checklist, content/pilot protocol, store-billing integration notes, Windows accessibility-safety notes and a static readiness command are present.
- **External release gates remain pending:** qualified reviewer sign-off, privacy/store review, supervised child usability/pilot evidence, Android release bundle, Windows release build, real-device Android QA and native Windows soak are not claimed as passed.
- **Phase 10 cannot be truthfully closed by code alone:** these external gates must be completed before any class becomes commercially ready at ₹299.
## 8. Product metrics

Measure these locally first. Add remote analytics only after a separate child-privacy review.

Learning metrics:

- diagnostic-to-mastery change on unseen items;
- first-attempt and independent correctness;
- misconception recovery;
- 7-day and 30-day retention;
- transfer-task success;
- skills needing support versus secure skills.

Experience metrics:

- lesson completion without repeated random guessing;
- hint usefulness;
- child-initiated replay of explanations;
- session length and healthy stopping;
- crashes, hangs and save failures.

Commercial metrics belong only in the parent/store context:

- free-unit completion;
- parent paywall view;
- purchase completion and restore success;
- refund/support reasons.

Internal success targets can guide development, but they must not become public efficacy claims until measured with an appropriate study.

## 9. Release order

Recommended sequence:

1. finish Phases 0–3 as the shared learning engine;
2. complete and pilot Class 3 (Phase 4A);
3. add spaced review and parent evidence (Phases 5 and 7) before charging;
4. integrate billing in a closed test track;
5. release Class 3 at ₹299;
6. complete Class 4 and Class 5 using the proven pipeline;
7. add deep projects, languages and Windows accessibility restoration continuously, without weakening release gates.

Do not sell all three classes merely because three class buttons exist. A class becomes purchasable only when its coverage matrix, reviewer sign-off, content tests and real-device QA pass.

## 10. Coding-agent execution protocol

Any ChatGPT/Codex coding session implementing this roadmap must:

1. read `README.md`, this roadmap, `CHANGELOG.md`, `pubspec.yaml`, the relevant models/services, and all tests touching the phase;
2. audit the existing implementation before changing schemas or UI;
3. implement one numbered phase or a clearly bounded slice at a time;
4. preserve Android, Android free-form and Windows behaviour;
5. add backward-compatible save migration before changing persisted models;
6. keep content IDs stable or provide an explicit migration map;
7. add tests for learning rules, content integrity, accessibility and responsive layout;
8. run `dart format`, `flutter analyze`, `flutter test`, Android build and Windows build in proportion to the change;
9. update the roadmap checklist and `CHANGELOG.md` only after gates pass;
10. never invent curriculum certification, teacher approval, payment verification or learning-study results.

Human approval is mandatory for:

- curriculum mapping and content correctness;
- child-safety/privacy policy;
- pricing and store configuration;
- teacher-review sign-off;
- public learning claims.

Code generation can accelerate the system and item templates, but it does not replace educational review.

## 11. Definition of a commercially complete class pack

A class pack is ready for ₹299 only when all boxes are true:

- [ ] curriculum coverage matrix is complete;
- [ ] every competency has teach, guided, independent, mastery and review content;
- [ ] explanations and misconceptions are reviewed;
- [ ] content targets and non-MCQ interaction target are met;
- [ ] diagnostic and adaptive recommendations work;
- [ ] spaced review and secure mastery work;
- [ ] parent evidence is understandable and accurate;
- [ ] free sample and paid boundary work offline;
- [ ] purchase and restore are production verified;
- [ ] Android/free-form/Windows QA passes;
- [ ] accessibility and child-safety review passes;
- [ ] qualified reviewer signs off the pack;
- [ ] store listing makes no unsupported claim.
