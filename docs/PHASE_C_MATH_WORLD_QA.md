# BrightQuest Phase C — Math & My World QA

## Purpose

Phase C builds on the verified Phase A + Phase B baseline and focuses on Nursery early mathematics, My World factual clarity, visual/audio synchronization, generated-practice variety and Count/Quiz integration.

Automated success is a software/content-safety gate only. It does not claim qualified-teacher approval, child-pilot evidence, production billing readiness or Android/Windows device qualification.

## Phase C corrections

### Early Math

- Number-recognition generation now traverses the complete skill range before repeating.
- Counting generation uses a deterministic cycle of amount + visual-object combinations instead of unconstrained pseudo-random selection.
- The zero case uses an explicit empty counting space and scores `0` without pretending a visible symbol is an object to count.
- Number↔quantity, missing-number, more/less, same/different and addition generators now use bounded deterministic catalogs.
- Addition facts remain non-negative and capped at a total of 10. Object addition varies the visible object while preserving the exact arithmetic.
- Sequential review generation is audited for early repeats across every Nursery skill, not only Alphabet.

### My World

Phase C independently cross-checks all 28 authored My World answers and generated picture→word catalogs for colours, shapes, animals, foods, familiar objects, body parts and routines.

Wording fixes remove avoidable ambiguity:

- a door example asks about the **front face** when testing a 2D rectangle;
- the farm-animal transfer uses **hooves** as a distinguishing clue;
- the body-part transfer identifies **feet at the end of each leg**, avoiding shoe/ground-contact ambiguity;
- the morning-routine item uses the concrete action **get dressed for the day** instead of a circular “get ready” answer;
- the road-safety transfer requires the child to **stay with the adult and wait until it is safe to cross**.

These remain draft content with `needsReview`; the repository does not invent teacher approval.

## Visual / audio synchronization

`nursery_spoken_labels.dart` provides stable spoken equivalents for Nursery visual tokens. Math and My World narration no longer depends on how a particular OS voice chooses to pronounce emoji or shape symbols.

Examples:

- counting prompt `🍎🍎🍎` → “apple, apple, apple” (the TTS does not reveal “3”)
- counting/addition prompt `★★` → “star, star”
- `🔴` → “red circle”
- `▲` → “triangle”
- `🐱` → “cat”

Automatic activity narration, manual “Hear instruction and choices”, hints, spoken correct/wrong responses, answer-button semantics and play-board portal semantics use the same normalization policy. Counting prompts speak objects one-by-one so audio does not leak the numeric answer. Visible UI content is unchanged by this speech layer.

## Non-repetition

`NurseryReviewSeedPlanner` chooses a stable first review seed and then advances from the latest generated review seed for that profile/skill. Generated families use cycle-based selection so sequential seeds traverse their review pool before repeating within the declared Phase-C window.

This does not create mastery by itself. Existing evidence rules still require the correct independent/transfer/delayed-review evidence.

## Phase C automated gate

On Windows:

```powershell
dart format lib test tool
.\tool\qa\run_phase_c.ps1
```

The runner is fail-fast and performs:

1. formatting gate;
2. the complete verified Phase B runner (which itself re-runs Phase A);
3. focused Phase C Math + My World simulation/audit;
4. Nursery content validation;
5. release-safety validation;
6. Count/Quiz unit + widget integration tests;
7. complete Flutter regression suite;
8. `flutter analyze`.

Only the final line below means the automated Phase C gate is green:

```text
=== Phase C completed successfully ===
```

## External gates remain pending

- named qualified teacher/content review;
- supervised child usability/learning pilot;
- real Android audio, accessibility, resize and lifecycle qualification;
- safe-default native Windows qualification and separate Narrator canary;
- production Google Play / Microsoft Store one-time purchase verification;
- privacy/store listing/reviewer evidence.
