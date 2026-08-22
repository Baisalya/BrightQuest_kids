# Phase E — Classes 3–5 Full Teacher & Curriculum Hardening

## Status

Technical implementation complete; Windows verification still required.

Phase E does **not** claim qualified-teacher approval, CBSE certification, NCERT certification, supervised child-pilot evidence, store approval, or device certification. All Class 3–5 content remains `needsReview` until a real qualified reviewer signs it off.

## Purpose

Phase E applies the same “do not teach a wrong answer” standard used in the Nursery hardening work to the Class 3–5 learning system. It protects legacy games while adding curriculum-first teaching for competencies that did not fit those game formats.

## Coverage

Each class retains its 63 legacy game activities and now adds 48 `skill_studio` activities, for 111 authored activities per class / 333 total. The existing legacy inventory remains 189 records and its 88 historical selectors remain unchanged.

The 48 Skill Studio activities in each class cover the 12 competencies that previously had no authored activity. Each receives a guided, independent, mastery-check and transfer-shaped activity. Existing learning blueprints are also rewritten so every competency has concrete teaching, worked-example, guided, independent, transfer and delayed-review language rather than generic placeholders.

## Honest constructed-response boundary

Two productive-language competencies deliberately remain outside automatic mastery:

- `c3_eng_short_composition`
- `c5_eng_explain_justify`

Their Skill Studio tasks are useful recognition/scaffolding practice, but selecting a strong example is not equivalent to independently composing or justifying an answer. Their activities therefore declare:

- `masteryEligible: false`
- `evidenceScope: practiceOnlyConstructedResponsePending`

The lesson UI still teaches and practises these skills but does not write mastery evidence. Diagnostic and Power Review also exclude practice-only activities. Secure mastery remains blocked until a genuine constructed response can be reviewed against an appropriate rubric by an adult/teacher workflow.

## Curriculum/content corrections made in Phase E

- Fixed the Class 3 `125 + 75` explanation so the bridge strategy includes the remaining 50 instead of jumping from 150 to 200.
- Re-authored ambiguous grammar sentences so the intended noun/verb/adjective target is not competing with several equally valid words in the same sentence.
- Shortened the Class 3 north-direction map prompt while preserving the learning target.
- Changed recycling explanations and child-facing wording so BrightQuest material groups are not presented as universal local recycling rules.
- Added frozen answer references for all 144 Skill Studio activities so future JSON answer drift cannot validate itself.
- Added explicit mastery/evidence metadata to Skill Studio payloads.
- Added a case-sensitive exact-text scoring rule for capitalization, punctuation and editing competencies so a lowercase distractor cannot be accepted when capitalisation is the skill being assessed.

## Class Skill Studio

`Class Skill Studio` is a competency-first learning tool available from Home. It lists all 37 competencies for the selected Class 3, 4 or 5 and opens the existing teach → worked example → guided → independent → transfer → review lesson engine directly for the selected competency.

Skill Studio is intentionally separate from the eight legacy game formats. A measurement, reading-comprehension or community-interdependence competency should not be forced into a Math Market, Map Quest or other unrelated game merely to obtain an activity ID.

## Automated Phase E gate

`tool/qa/run_phase_e.ps1` is fail-fast and runs:

1. formatting gate;
2. the entire verified Phase D chain (which itself preserves A → B → C and builds Android/Windows release candidates);
3. independent Classes 3–5 curriculum hardening audit;
4. content-contract validator;
5. fail-closed release-safety report;
6. focused Phase E unit/widget regressions;
7. complete Flutter test suite;
8. final `flutter analyze`.

The hardening audit checks class boundaries, activity/blueprint counts, Skill Studio inventory, frozen answer references, correct-answer acceptance, distractor rejection, generic-blueprint removal, source-activity validity, false approval, practice-only boundaries, known ambiguity regressions and recycling-local-rule wording.

## Release interpretation

A green Phase E means the repository passed its automated technical curriculum-hardening gates. It does **not** replace:

- qualified teacher/content review of all 333 Class 3–5 activities and 111 learning blueprints;
- rubric-based constructed-response review for productive language;
- supervised child usability/evidence pilots;
- production billing/store verification;
- privacy/store-listing review;
- Android real-device and native Windows crash/accessibility qualification.
