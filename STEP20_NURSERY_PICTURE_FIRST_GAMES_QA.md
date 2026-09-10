# Step 20 / Nursery Step 6 — Picture-first Easy Games QA

## Scope

Nursery authored and generated game presentation is upgraded without changing
activity IDs, response values, answer rules, mastery evidence, review scheduling,
or save/storage contracts.

The Step 5 extraction compile issue is also carried forward here: the authored
activity stage now imports `nursery_spoken_labels.dart`, which owns
`nurseryVisualFreeText`.

## Architecture

- `nursery_interactions.dart` is a thin interaction dispatcher.
- `nursery_choice_game.dart` owns responsive choice-card layout.
- `nursery_match_game.dart` owns pair matching state and response-map assembly.
- `nursery_sort_game.dart` owns picture-to-bucket assignment state.
- `nursery_trace_game.dart` owns checkpoint tracing and trace guidance.
- `nursery_game_value.dart` converts an authored value into a picture/vector/text
  presentation while leaving the submitted value untouched.
- `nursery_game_chrome.dart` owns reusable child-friendly instructions,
  progress messages and selected/completed cards.

These presentation files do not access `BrightQuestScope`, persistence,
practice generation, or answer evaluation.

## Picture-first rules

- Bundled local illustrations are preferred for known object/animal/food words.
- Colour words become painted colour swatches in colour context.
- Shape words become painted shapes in shape context.
- Alphabet words in tracing/letter-reading activities remain typography instead
  of accidentally becoming object pictures.
- Letters/numbers remain large scalable typography.
- Long routine/safety answers remain readable text and use a calm single-column
  layout.
- Compound answers such as `apple + carrot` render both picture concepts while
  preserving the original option ID/value.
- Raw authored emoji/pictograms are compatibility input only; new interaction
  presentation files do not render raw pictographic glyphs directly.

## Interaction contract coverage

Current authored Nursery pack:

- 112 `choice` activities / 328 authored options.
- 12 `pairMatch` activities / 48 left+right values.
- 4 `sortBuckets` activities / 16 item+bucket values.
- 4 `trace` activities.

Response shapes remain unchanged:

- choice → original option ID
- pair match → `Map<String, String>`
- sorting → raw item-to-bucket `Map<String, String>`
- trace → ordered checkpoint index list

## UX upgrades

- Choice cards are larger, responsive and image-first when possible.
- Long text answers automatically switch to one column.
- Matching shows explicit Pick → Match steps, selected state and completion state.
- Used match partners cannot be accidentally assigned to two cards at once.
- Sorting shows selected/placed picture state and picture/vector bucket cards.
- Trace highlights the next checkpoint and paints the completed path strongly.
- Authored and generated review choices share the same picture-first answer-card
  presentation.
- Visual-heavy prompts show their picture group before the short prompt copy.

## Validation

Run:

```powershell
flutter analyze
flutter test test/nursery_picture_first_games_test.dart
flutter test test/nursery_lesson_architecture_test.dart
flutter test test/nursery_visual_architecture_test.dart
flutter test test/phase_c_count_quiz_integration_test.dart
flutter test test/phase_d_accessibility_polish_test.dart
flutter test test/nursery_simple_game_flow_test.dart
flutter test test/nursery_layout_test.dart
flutter test
```
