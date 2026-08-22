# Nursery Upgrade — Content Plan

## Curriculum boundary

Nursery content is a BrightQuest internal early-learning progression, not a CBSE/NCERT certification. It is authored as a separate `brightquest_nursery` pack with its own versioned schema and review metadata because the existing `assets/content/curriculum_map.json` and `ContentPack` contract are deliberately Class 3–5 integer models.

Nursery v1 uses short concrete language, one instruction at a time, familiar objects, visible answer support and no assumption of reading fluency. Core numeral work is 0–20. Authored addition and generated sums have non-negative addends and totals ≤10. Phonics is simple letter-sound/beginning-sound awareness, not a claim of comprehensive phonics instruction.

## Learning domains

The implementation defines 32 skills:

1. `nur_alpha_uppercase` — recognise A–Z uppercase letters.
2. `nur_alpha_lowercase` — recognise a–z lowercase letters.
3. `nur_alpha_case_match` — match uppercase to lowercase.
4. `nur_alpha_word_picture` — A-for-Apple style word-picture association.
5. `nur_alpha_letter_sound` — connect selected letters to simple initial sounds.
6. `nur_alpha_listen_select` — listen to a letter/word instruction and select the visible answer.
7. `nur_alpha_beginning_sound` — match familiar words to beginning letters/sounds.
8. `nur_alpha_visual_discrimination` — distinguish visually similar letters in age-appropriate sets.
9. `nur_alpha_trace_upper` — guided uppercase tracing practice; checkpoint completion only.
10. `nur_alpha_trace_lower` — guided lowercase tracing practice; checkpoint completion only.
11. `nur_math_numbers_0_5` — recognise 0–5.
12. `nur_math_numbers_6_10` — recognise 6–10.
13. `nur_math_numbers_11_20` — recognise 11–20.
14. `nur_math_count_0_5` — count visible objects through 5.
15. `nur_math_count_6_10` — count visible objects through 10.
16. `nur_math_number_quantity` — match numerals to quantities.
17. `nur_math_missing_number` — complete ascending one-step sequences within 0–20.
18. `nur_math_more_less` — compare visibly different quantities.
19. `nur_math_same_different` — identify same/different groups.
20. `nur_math_add_objects` — combine two visible groups, totals ≤10.
21. `nur_math_add_numerals` — solve very easy numeral addition after object-model examples, totals ≤10.
22. `nur_knowledge_colours` — recognise common colours by name and visible swatch.
23. `nur_knowledge_shapes` — circle, square, triangle, rectangle, oval and star.
24. `nur_thinking_patterns` — continue AB/AAB/ABC visual patterns.
25. `nur_thinking_matching` — pair identical/related familiar items.
26. `nur_thinking_sorting` — sort by one explicit attribute/category.
27. `nur_knowledge_animals` — recognise familiar animals and simple vocabulary.
28. `nur_knowledge_food` — distinguish familiar fruits/vegetables.
29. `nur_knowledge_objects` — recognise familiar home/school objects.
30. `nur_knowledge_body_parts` — identify basic externally visible body parts with neutral, safe wording.
31. `nur_knowledge_routines` — order/choose safe everyday routines such as wash hands, brush teeth, pack bag and bedtime sequence.
32. `nur_thinking_observation_listening` — short visual-memory/observation and one-sentence listening comprehension.

## Skill progression

| Domain | Skill | Teach | Guided practice | Independent check | Transfer | Review |
| --- | --- | --- | --- | --- | --- | --- |
| Alphabet | Upper/lowercase recognition | Large letter + name + picture cue | choose named letter from 2–3 | choose unseen letter sets | find same letter in different case/font-like context | delayed recognition item |
| Alphabet | Word-picture / beginning sound | picture + word + highlighted first letter | pair letter to familiar object | choose beginning letter without highlight | new familiar word/picture | delayed sound/letter item |
| Alphabet | Case matching | show `A ↔ a` example | pair two cases | complete independent pair map | match same cases in new set | delayed pair set |
| Alphabet | Tracing | animated/static guide path | follow ordered checkpoints | optional independent trace | recognise traced target among choices | review recognition, not handwriting claim |
| Maths | Number recognition | numeral + spoken name + object model | choose numeral | independent choose numeral | match numeral to new quantity | delayed recognition |
| Maths | Counting | objects appear/group once | touch/click count choice | independent count new arrangement | count different object type/layout | delayed generated count |
| Maths | Quantity match | numeral beside object model | match numeral/group | independent pair | new object type | delayed pair |
| Maths | Sequences | number path with one gap | choose missing number | independent gap | different start/range | delayed generated sequence |
| Maths | Compare | two grouped quantities | choose more/less/same | independent comparison | different objects/orientation | delayed generated compare |
| Maths | Addition | two groups move together, then count | choose total with objects shown | independent object sum | numeral-only equivalent | delayed generated easy sum |
| Knowledge | Colours/shapes | named swatch/shape + familiar example | choose target | independent target | recognise in familiar object | delayed recognition |
| Thinking | Patterns | reveal repeating unit | choose next token | independent pattern | new token set with same rule | delayed generated pattern |
| Thinking | Matching/sorting | model one pair/category | guided pair/sort | independent complete set | new items/same relation | delayed set |
| Vocabulary | Animals/food/objects/body/routines | picture symbol + spoken/visible word | identify/choose | independent choice | use word/sequence in new prompt | delayed listening/recognition |
| Observation | Memory/listening | brief visual/listening model | guided recall | independent recall | new scene/sentence | delayed recall |

## Activity inventory

The static pack contains **128 authored scorable core activities**: exactly four mastery-capable records per skill (`guided`, `independentA`, `independentB`, `transfer`). Tracing skills also include authored checkpoint tracing records that are scorable for completion but explicitly `countsForMastery: false`; mastery for the tracing-related skill is still established through independent recognition/transfer evidence.

| Activity family | Learning objective | Interaction | Difficulty tiers | Generation rule | Review state |
| --- | --- | --- | --- | --- | --- |
| `singleChoice` | recognition, listening, count, sequence, compare, addition, vocabulary | large tap/click/focus buttons | 1–3 | authored + bounded deterministic practice for supported families | `needsReview` |
| `pairMatch` | case matching, numeral↔quantity, related matching, memory pairs | select left then matching right; completed pairs stay visible | 1–3 | authored only in v1 | `needsReview` |
| `sortBuckets` | fruit/vegetable, animal/object/category or attribute sorting | select/tap item then destination bucket; mouse/touch; buttons provide keyboard path | 1–3 | authored only in v1 | `needsReview` |
| `tracePath` | guided letter path following | touch/mouse pointer follows ordered forgiving checkpoints | 1–2 | authored path templates, finite checkpoints | `needsReview`; no handwriting correctness claim |
| `memoryChoice` | visual observation/listening recall | study card then single choice | 1–3 | authored only in v1 | `needsReview` |

Deterministic generator families in `nursery_practice_generator.dart`:

- number recognition 0–20;
- visible counting 0–10;
- number-to-quantity 0–10;
- missing-number sequences 0–20;
- more/less comparisons 0–10;
- easy addition, total ≤10;
- AB/AAB/ABC pattern continuation;
- uppercase/lowercase recognition and case-match option variants.

Every generator uses direct arithmetic/indexing into finite catalogs. There are no retry loops. Distractors are derived from bounded candidate sets, de-duplicated, and checked not to equal the correct answer.

## Narration and vocabulary

Every skill has `objectiveNarration`, `explanationNarration` and a visible equivalent. Every activity has visible `prompt`, `narrationText`, visible hint and visible feedback/explanation.

Narration rules:

- default to short sentences under roughly 12 words where possible;
- read instructions automatically when the lesson step changes if auto narration is enabled;
- a visible “Read aloud” control uses `speakPrompt` and includes answer choices when appropriate;
- correct feedback uses the existing cheerful `BrightAudioService.speakCorrect` path;
- wrong feedback uses `speakWrong` with guidance and does not shame the child;
- letter-sound text uses simple spellings such as “/m/ as in moon” rather than IPA, pending teacher review;
- no audio-only clue is required to complete an activity without a visible text alternative.

## Correct-answer rules and misconceptions

`NurseryResponseEvaluator` is the only runtime interpreter for Nursery response rules.

Supported rules and required behavior:

- `singleChoice`: exactly one authored/generated option equals `answer` after normalized text/number comparison.
- `pairMatch`: submitted map must contain exactly all required left keys and corresponding right values.
- `sortBuckets`: every submitted item must map to the authored bucket; incomplete maps are incorrect.
- `tracePath`: ordered checkpoint IDs must be completed in sequence. The result means “followed the guide path”, never “correct handwriting”.
- `memoryChoice`: same equality rule as `singleChoice`, but UI presents an observe/listen phase first.

Wrong responses map to a short misconception/guidance ID such as `letter_case_confusion`, `beginning_sound_confusion`, `count_one_to_one`, `number_quantity_confusion`, `sequence_step`, `compare_quantity`, `addition_recount`, `shape_feature`, `pattern_unit`, `sort_category` or `listening_detail`. These are learning guidance labels, not diagnoses.

## Randomisation and repetition rules

- Generator result is a pure function of `family + seed + tier`; same inputs return the same item.
- Seeds are bounded integer inputs. No random retry loops are used.
- Choice sets contain 2–4 values depending on difficulty; all values are unique and the correct answer appears exactly once.
- Counting uses at most 10 visible objects; generated object symbols come from a finite child-safe catalog.
- Missing-number sequences are ascending by 1 only in Nursery v1.
- Comparisons avoid accidental ties unless the target skill is explicitly `same`.
- Addition uses non-negative integers, each addend ≤5 in tier 1 and total ≤10 in all tiers.
- Generated practice IDs include family/tier/seed and remain linked to the owning Nursery skill ID for evidence.
- Session selection rotates authored independent and generated variants deterministically from the skill ID + evidence count, preventing unbounded randomness and immediate duplicate options.

## Content authoring requirements

Every Nursery skill record must include:

- stable `nur_...` skill ID and domain;
- title, objective and child-visible objective text;
- explanation, worked example and visual tokens;
- narration equivalent;
- at least four scorable activity IDs;
- review metadata with `needsReview`, revision and reviewer owner;
- one or more independent activities and a separate transfer activity;
- a delayed-review source activity or generator family;
- any tracing path explicitly marked non-handwriting and not sole mastery evidence.

Every activity must include:

- stable ID and `skillId`;
- stage: `guided`, `independent`, `transfer`, `review` or `tracePractice`;
- interaction type;
- difficulty 1–3;
- prompt, narration, visible explanation and hint;
- response rule and options/items/buckets as needed;
- misconception guidance;
- `countsForMastery` flag;
- review status/revision/author/reviewer owner.

No activity may be changed from `needsReview` to `approved` by a script or automated test.

## Qualified-review workflow

1. Run Nursery schema/content validation and print the 32-skill/128-core-activity coverage matrix.
2. Reviewer checks learning sequence, age appropriateness, word-picture accuracy, sound examples, number ranges, body/routine wording, distractors and visible/narrated equivalence.
3. Reviewer checks that every mastery claim has two independent scorable items, one transfer item and delayed-review source.
4. Reviewer checks free samples independently from paid content.
5. Requested changes update revision numbers and return to `needsReview` or `changesRequested` as appropriate.
6. Only a named qualified reviewer may set the exact revision to `approved` and record date/ownership.
7. `paidEligibility` stays false until every claimed skill/activity plus the pack/free-sample boundary is approved and the non-content release gates are also complete.

## A–Z multi-example discovery expansion

The A–Z catalog is not limited to one memorised “A for Apple” association. Every letter now contains a larger authored discovery pool, expanding to 208 bundled picture-word examples across the alphabet. Each example carries a visible word, picture fallback, bundled local picture-card asset, sound cue, display phrase and explicit sound/beginning-sound eligibility flags. Typical sequences begin with familiar core items such as `A: Apple → Ant → Aeroplane`, `B: Ball → Banana → Bird`, and `C: Cat → Car → Cup`, then continue with extra words such as `Axe / Avocado / Alligator`, `Book / Bus / Butterfly`, and `Cake / Candle / Carrot`. The discovery UI cycles these examples without creating evidence, while independent/review generators continue to select among the authored examples deterministically.

Beginning-sound practice is stricter than simple letter association. Only examples explicitly marked `beginningSoundEligible` can appear in beginning-sound evidence. This avoids turning exceptional spellings such as X-ray/Xylophone into misleading simple-phonics claims. An example may still be shown for letter familiarity while being excluded from a particular sound evaluator.

Phase B further separates discovery vocabulary from simple phonics evidence. The 208 discovery cards remain available for A–Z vocabulary exploration, while only 157 curated, clear simple-onset examples are eligible for `alpha_letter_sounds` and `alpha_beginning_sound`. Irregular/alternate vowel examples (`Eye`, `Eagle`, `Island`, `Ocean`, `Unicorn`), Q/U patterns, X patterns, `Ship`/SH, and initial consonant clusters such as `Frog`, `Star`, and `Train` are retained for discovery but excluded from simple-phonics mastery. This prevents spelling membership from being mistaken for a single uncomplicated phoneme relationship.
