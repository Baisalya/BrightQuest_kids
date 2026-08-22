# Nursery Upgrade — Product Plan

## Product objective

Add a technically complete, offline-first Nursery pack that teaches foundational literacy, numeracy and everyday knowledge through short interactive lesson loops rather than reusing the Classes 3–5 quiz/adventure shell. Nursery is a separate pack identity (`brightquest_nursery`) and must not be represented as Class 2, Class 0 or any other integer `classNumber` value.

The pack must preserve every existing Class 3/4/5 route, stable activity/level ID, profile, reward, parent-control, entitlement and Windows crash-safety behavior. Nursery is permitted to be fully accessible for development/review while its content contract says `paidEligibility: false`; once that flag becomes true, production access must fail closed until a real store/backend verification adapter exists for the Nursery product ID.

## Learner age and prerequisites

- Intended stage: Nursery / early-years learners, approximately ages 3–5. This is an internal product boundary, not a school-board certification claim.
- No reading fluency assumed. Every meaningful instruction has visible text and can be narrated through `BrightAudioService`.
- Interaction assumes a child can tap/click a large target, listen to a short instruction and make a simple selection. Drag-only actions always have a non-drag learning alternative; tracing itself is touch/mouse-first and is not used as sole mastery evidence.
- Number progression starts at 0–5, then 0–10, then 0–20. Addition is limited to visually represented sums with totals at or below 10 in authored Nursery v1 content and generated practice.
- English is the only authored Nursery locale in this implementation. No Hindi content is enabled until reviewed translations exist.

## Parent and teacher needs

Parents need a clear distinction between exposure and demonstrated learning. Nursery progress therefore records evidence only from scorable guided/independent/transfer/review interactions; watching an explanation, animation or tracing guide never creates mastery by itself.

Qualified reviewers need stable, inspectable content. Every Nursery skill and activity therefore carries an ID, objective/domain link, review state, revision, author, reviewer owner, narration text, hint/guidance, correct-response rule and whether the activity is allowed to contribute mastery evidence.

The parent area must describe Nursery as a planned permanent ₹299 one-time pack, but buying remains disabled while review, child pilot, store configuration and device qualification gates are incomplete.

## Included scope

Nursery v1 contains **32 explicit skills** in three learning groups:

- **Alphabet & phonics — 10 skills:** uppercase A–Z recognition; lowercase a–z recognition; uppercase/lowercase matching; A-for-Apple word-picture associations; letter-sound awareness; listen-and-select; beginning-sound matching; letter visual discrimination; uppercase tracing practice; lowercase tracing practice.
- **Early mathematics — 11 skills:** numbers 0–5; numbers 6–10; numbers 11–20; counting 0–5; counting 6–10; number-to-quantity matching; missing-number sequences; more/less; same/different; object-based addition; numeral addition.
- **Everyday knowledge & thinking — 11 skills:** colours; 2D shapes; simple patterns; matching; sorting; animals; fruits and vegetables; familiar objects; body parts; everyday routines; visual memory/observation plus listening vocabulary comprehension.

Each skill has a child-facing lesson definition with objective, explanation, worked visual example, guided activity, at least two independent scorable activities, transfer activity and delayed-review source. The pack contains at least **128 authored scorable activity records** (4 per skill) plus explicit tracing practice records where relevant. Deterministic generated practice is separate from authored teaching content and is limited to bounded Nursery-safe families.

## Excluded scope

- No handwriting-quality, letter-form or motor-development correctness claim. Tracing only evaluates whether the child followed ordered broad checkpoints within a forgiving tolerance.
- No speech recognition, child voice recording, camera, cloud account, public upload, social feed or child chat.
- No advertising, `AD_ID`, manipulative streak pressure or child-facing purchase prompt.
- No CBSE/NCERT certification or endorsement claim.
- No production Nursery entitlement grant, cross-platform ownership sharing or store verification until real billing integration exists.
- No invented teacher approval, pilot outcome, store credential, billing result or device certification.

## Pack and free-sample boundary

- Internal pack ID: `brightquest_nursery`.
- Planned store product ID: `brightquest_nursery`.
- Planned price: ₹299 permanent one-time pack.
- `paidEligibility` remains `false` in `assets/content/nursery/pack_v1.json`.
- Development/review builds may expose all Nursery content while the pack is unreviewed, matching the existing Classes 3–5 repository behavior for `paidEligibility: false`.
- The production free sample is intentionally small: four complete activity-based sample activities, one each from letter recognition, counting, colours and shapes. The sample boundary is stored in pack metadata and must remain reviewable rather than inferred in UI code.
- When `paidEligibility` is eventually turned on, the Nursery repository must default to free-sample-only unless an explicit verified entitlement resolver is supplied. No local preference may become production proof of ownership.

## Success measures

Technical measures for this implementation:

- 32/32 skills have complete teach → guided → independent → transfer → review paths.
- 32/32 skills have at least two independent scorable records and one transfer record.
- Passive lesson steps never increment mastery.
- Mastery requires at least two independent correct responses with no hint/retry, one independent transfer success and later delayed review success before `secure` is shown.
- Generated practice is deterministic by seed, finite, has exactly one answer and unique non-answer options.
- Every activity has visible text equivalent to narration.
- Tracing works with touch and mouse and is explicitly excluded from handwriting-correctness claims.
- Compact (360×640), tablet and large/free-form layouts are covered by widget tests.
- Existing Class 3–5 automated contracts remain unchanged and continue to pass in a Flutter-capable environment.

Product-quality measures that **cannot be closed by code**:

- qualified early-years/primary teacher content review recorded against this exact revision;
- supervised Nursery child usability sessions completed with consent;
- real Android phone/tablet/free-form and Windows device qualification;
- Windows Narrator/resize/sleep-resume semantics canary qualification;
- production Google Play/Microsoft Store product setup and ownership verification.

## Delivery phases

| Phase | Outcome | Entry gate | Exit gate | Status |
| --- | --- | --- | --- | --- |
| N0 — Repository audit & contract | Plans grounded in existing content/evidence/audio/entitlement/save architecture; Nursery is a string-keyed pack | Current Classes 3–5 baseline present | Four plans complete; no integer-class coercion | Implemented in this change |
| N1 — Versioned content contract | Nursery schema, 32 skills, authored activity inventory and validator | N0 | All references/IDs/review metadata validate | Implemented in this change |
| N2 — Evidence & migration | Profile-isolated Nursery evidence/mastery/review persisted without altering Class 3–5 meaning | N1 | Legacy v5 saves load; new v6 field defaults safely; Nursery evidence survives reload | Implemented in this change |
| N3 — Deterministic practice | Bounded generators for early number/count/sequence/comparison/addition/pattern practice | N1 | Seed determinism, unique options, one valid answer, bounded totals | Implemented in this change |
| N4 — Interactive lesson experience | Nursery hub + reusable lesson flow + matching/sorting/tracing/choice interactions | N1–N3 | Objective, animation/example, guided, independent, transfer and feedback work on supported inputs | Implemented in this change |
| N5 — Audio/accessibility integration | Existing narration/ducking/voice settings reused; reduced motion/static fallbacks; keyboard labels | N4 | No unsafe Windows TTS registration/semantics change; visible equivalents present | Implemented in this change |
| N6 — Commercial parent boundary | Parent area exposes Nursery planned product and blockers without enabling purchase | N1 | `paidEligibility=false`, no child paywall, production entitlement fail-closed | Implemented in this change |
| N7 — Automated qualification | Format/analyze/tests/content/release tools + release builds | N1–N6 | Automated gates pass in Flutter/Android/Windows toolchains | Pending environment execution where toolchains are unavailable |
| N8 — Human/device/store release gates | Teacher sign-off, child pilot, store setup, real-device and Windows canary qualification | N7 | All external records exist for exact release revision | Pending external work |

## Decisions requiring product-owner approval

No missing product decision blocks this architecture. The following remain explicit future decisions rather than assumptions:

- whether the commercial display name should be “Nursery”, “Nursery Pack” or another store-facing label;
- final teacher-approved sequencing and vocabulary choices after review;
- whether a future Hindi Nursery pack is sold separately or bundled;
- whether Android and Windows purchases should ever be shared through a secure parent account/backend.

None of these changes the current safe implementation boundary.

## External gates

The Nursery pack must **not** be marked commercially ready or paid-eligible until all of the following are real and recorded:

1. A qualified reviewer approves every claimed skill, activity, explanation, narration line and free-sample boundary for the exact content revision.
2. Supervised child pilots are completed; confusing prompts, motor difficulty, guessing behavior and accessibility barriers are resolved.
3. Google Play and Windows production products are configured and real purchase/pending/cancel/refund/restore flows are verified.
4. Android phone/tablet/free-form release qualification passes on real devices.
5. Windows safe-default release passes real-device resize, sleep/resume and repeated narration soak.
6. Windows semantics canary separately passes Narrator + resize + sleep/resume native-crash qualification before semantics can be enabled in normal Windows builds.

## Alphabet discovery product refinement

Nursery letter learning is intentionally broader than a single fixed A-for-Apple mnemonic. Each A–Z letter ships with multiple familiar authored picture-word examples, scaling to 200+ bundled picture-word cards. Children can request another word for the current letter or move to the next letter, with visible text and narration changing together. This browsing remains exposure/guidance only; mastery still requires independent scorable evidence and delayed review. The extra picture assets are bundled offline and do not add advertising, tracking, network dependence or a third-party runtime package.
