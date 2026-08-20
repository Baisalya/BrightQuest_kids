# BrightQuest Kids — Phase 0 Content Reviewer Checklist

This checklist is the human approval record for the Phase 0 curriculum contract. The JSON mappings are an internal BrightQuest draft based on official references; they are **not** a CBSE or NCERT certification, endorsement, or approval.

## Reviewer ownership

Before any class pack is described as reviewed or made paid-eligible, record:

- reviewer name;
- role/qualification relevant to primary Classes 3–5;
- classes/subjects reviewed;
- review date and curriculum contract revision;
- requested changes and the revision in which each change was resolved.

The machine-readable owner is `primary_teacher_reviewer` in `assets/content/curriculum_map.json`. Its `ownerName` must remain unset until a real qualified reviewer is assigned.

## Review sequence for each class

For **each of Classes 3, 4 and 5**, review all of the following before changing any review state to `approved`:

1. **Class boundary** — confirm the reading-length guidance, vocabulary guidance, whole-number range and any stretch content are developmentally appropriate.
2. **Competency set** — confirm that the 30–40 competencies form a sensible class-pack scope, are observable and are neither misleadingly broad nor unnecessarily duplicated.
3. **Learning outcomes** — confirm each outcome is demonstrable by a child and actually supports its parent competency.
4. **Current-content mapping** — inspect every current game/topic selector in `current_content_audit.json`; confirm the mapped competency is correct or explicitly mark the selector for removal/rework.
5. **Out-of-class items** — identify any question, mission, vocabulary item, calculation range, science claim or geography fact that belongs outside the class boundary.
6. **Duplicates** — inspect the duplicate groups printed by `dart run tool/content/coverage_report.dart`; decide whether each duplicate is intentional retrieval practice, needs differentiated wording, or should be removed.
7. **Knowledge value** — reject mappings where the activity only tests repeated recall without supporting real understanding, explanation, application, transfer or later retention.
8. **Correctness** — verify prompts, expected answers, explanations, hints, distractor misconceptions, map facts and scientific claims.
9. **Mastery evidence** — approve or revise the Phase 0 evidence target: independent correctness, a transfer item, no final mastery hint, confidence evidence and delayed review.
10. **Free/paid boundary** — explicitly approve the eight activity-level demos (one per game) and which reviewed competencies may be claimed as part of the ₹299 permanent one-time class pack. Do not approve a broad unit-level sample that unlocks unrelated activities.

## Review-state rules

Allowed states are:

- `draft` — authored but not ready for reviewer attention;
- `needsReview` — ready for qualified human review;
- `inReview` — a named reviewer is actively checking it;
- `changesRequested` — reviewer found a required correction;
- `approved` — a named qualified reviewer approved this exact revision;
- `retired` — content/competency is intentionally no longer active.

Never set `approved` from automated tests alone. A revision change after approval requires another review before the new revision can be treated as approved.

## Commercial and public-claim gate

A class pack must remain `paidEligibility: false` while any claimed competency, learning outcome, unit, class boundary, or free-sample boundary is unapproved. The product may say that content is internally mapped to reference outcomes only when that statement is accurate; do not claim CBSE/NCERT certification or endorsement.

The planned commercial model is **₹299 once per class pack**, not a subscription. Child-facing screens must not add purchase pressure; purchase/restore work belongs to the later parent-area entitlement phase.

## Sign-off record

Complete this section only with real reviewer evidence:

| Field | Value |
| --- | --- |
| Reviewer name | Pending |
| Qualification / role | Pending |
| Class 3 boundary + objectives | Pending |
| Class 4 boundary + objectives | Pending |
| Class 5 boundary + objectives | Pending |
| Free sample boundaries | Pending |
| Paid-pack boundaries | Pending |
| Contract revision reviewed | Pending |
| Review date | Pending |
| Change-request references | Pending |

Until these approvals are recorded, Phase 0's **technical validation may pass**, but the **qualified-reviewer exit gate remains pending** and Phase 1 must not start.
