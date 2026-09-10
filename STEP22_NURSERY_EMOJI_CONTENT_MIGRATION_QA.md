# Step 22 / Nursery Step 8 — Complete Emoji Removal & Content Migration QA

## Scope

This step removes emoji/pictogram dependency from canonical Nursery authored and generated learning content while preserving existing skill/activity IDs, evidence/mastery behavior, save compatibility, review flow, and Step 7 Study → Guided Play → Independent Game navigation.

The migration is intentionally split into two boundaries:

1. **Canonical semantic content** — new Nursery content uses words and structured `payload.visualTokens` rather than emoji.
2. **Legacy response compatibility** — `nursery_legacy_visual_aliases.dart` accepts pre-Step-8 pictogram values at evaluator/rendering boundaries, but those values are never authored or rendered by the current Nursery content pipeline.

## Canonical content migration

- Nursery domain metadata uses semantic `visualKey` values instead of `emoji`.
- All 26 letter associations keep the same 208 bundled local picture assets; `picture` fallbacks are semantic lowercase words.
- Visual-heavy authored activities move picture groups to `payload.visualTokens`.
- Choice IDs, pair-match payloads, sort assignments, prompts, narration, and correctness rules use semantic values.
- `schema_v1.json` documents the Step 8 semantic visual-token contract.
- The content validator rejects known legacy Nursery pictograms in canonical content.

## Generated practice migration

`NurseryPracticeGenerator` no longer emits emoji for counting, addition, colours, shapes, My World, patterns, matching, sorting, or observation practice.

- repeated quantities are represented by repeated semantic tokens and compacted by the visual resolver;
- colour visuals use explicit tokens such as `colour:red` where disambiguation matters;
- deterministic generated IDs remain `nursery-generated:<skillId>:<seed>`;
- generator-family assignment and activity evidence behavior are unchanged.

## Compatibility boundary

`nursery_legacy_visual_aliases.dart` is the only Nursery production file intentionally containing the old pictograms. `NurseryResponseEvaluator` canonicalizes legacy choice/map responses before comparison, allowing pre-migration values to evaluate against new semantic rules.

Static compatibility comparison performed against the QA-passed Step 7 baseline:

- all 132 activity IDs are identical;
- all 32 skill IDs are identical;
- activity `skillId`, `phase`, `interaction`, mastery/review eligibility are unchanged;
- every legacy authored choice correct value canonicalizes to its Step 8 semantic correct value;
- every legacy choice-option set canonicalizes to the Step 8 option set;
- every legacy pair-match and sort map canonicalizes exactly to the Step 8 map;
- trace rules are unchanged.

## Static release checks performed

- Canonical `pack_v1.json`: **0 Extended_Pictographic matches** (Step 7 baseline: 535 matches across 429 lines).
- Canonical `schema_v1.json`: **0 Extended_Pictographic matches**.
- Nursery production code outside the legacy alias adapter: **0 Extended_Pictographic matches**.
- Nursery-specific QA code outside compatibility fixtures: no authored emoji dependency.
- Pack counts unchanged: 4 domains, 32 skills, 132 activities, 26 letter associations.
- 208/208 letter-card asset paths still exist and are unchanged.
- All authored `visualTokens` are string lists.
- Every authored choice correct value exists in its option IDs.
- `pubspec.yaml`: unchanged.
- `game_controller.dart`: unchanged.
- `nursery_learning_models.dart`: unchanged.
- `nursery_lesson_screen.dart`: unchanged.
- Step 7 journey planner/board: unchanged.
- No backend/network/package dependency introduced.
- JSON parse checks pass for both Nursery pack and schema.

## Additional regression coverage

`test/nursery_emoji_content_migration_test.dart` covers:

- semantic/validator-clean canonical content;
- all 208 letter-card fallbacks and assets;
- all 132 authored activities free from legacy pictograms;
- deterministic generated practice across all skills and seeds 0–63 free from legacy pictograms;
- legacy choice, matching, sorting, and observation responses still evaluate correctly;
- old pictograms remain isolated to the explicit compatibility boundary.

Existing Nursery visual, asset/vector, picture-first, phonics, count/quiz, and Math/My World tests were updated to assert semantic content rather than raw emoji strings.

## Flutter qualification

The archive preparation environment does not contain Flutter/Dart SDK tooling, so no claim is made that `flutter analyze` or `flutter test` was executed here. Run locally:

```powershell
flutter analyze
flutter test test/nursery_emoji_content_migration_test.dart
flutter test test/nursery_asset_vector_library_test.dart
flutter test test/nursery_visual_architecture_test.dart
flutter test test/nursery_picture_first_games_test.dart
flutter test test/phase_b_phonics_correctness_test.dart
flutter test test/phase_c_count_quiz_integration_test.dart
flutter test test/phase_c_math_world_correctness_test.dart
flutter test test/nursery_study_guided_independent_flow_test.dart
flutter test
```


## QA follow-up — semantic migration compatibility fixes

Local Flutter qualification of the first Step 8 package exposed three migration-boundary issues, all corrected in this QA-fix build:

- `NurseryVisualResolver` could recurse between `forInteractionValue` and `fromLegacyToken` for repeated legacy geometric picture symbols such as `●●●` / `★★`. The compatibility canonicalizer now handles those non-emoji Unicode visual symbols separately from the emoji alias map and converts repeated runs to semantic counted labels before rendering.
- `phase_b_phonics_correctness_test.dart` still assumed the pre-migration beginning-sound visual-token shape `[emojiPicture, word]`. Generated Step 8 practice intentionally emits the semantic word token only, so the test now resolves the authored example word semantically rather than indexing the removed pictogram slot.
- `TeachingCorrectnessAudit` still counted `●` runes in generated number-quantity answers. It now understands canonical `N dot` / `N dots` labels while retaining a legacy-dot fallback for compatibility fixtures.
- The three `unnecessary_non_null_assertion` analyzer warnings in `NurseryVisualResolver.compactVisualTokens` were removed without changing behavior.

These corrections do not change the canonical content pack, activity/skill IDs, generator seed/ID contract, response evaluator rules, save/mastery models, Step 7 journey flow, or package dependencies.

The cumulative Step 8 modified-file set relative to the QA-passed Step 7 baseline is **23 files**.
