# Modified files — Nursery Step 8

Canonical content/schema:

- `assets/content/nursery/pack_v1.json` — migrates authored Nursery pictograms to semantic content and structured visual tokens.
- `assets/content/nursery/schema_v1.json` — documents semantic `visualKey` / `payload.visualTokens` contract.

Core Nursery production:

- `lib/core/nursery/nursery_content.dart` — semantic domain visual key, visual-token model access, canonical-content validation.
- `lib/core/nursery/nursery_legacy_visual_aliases.dart` — explicit backwards-compatibility adapter for pre-Step-8 pictogram values.
- `lib/core/nursery/nursery_practice_generator.dart` — semantic generated practice with structured visual tokens.
- `lib/core/nursery/nursery_response_evaluator.dart` — canonicalizes legacy responses while keeping evaluation rules centralized.
- `lib/core/nursery/nursery_spoken_labels.dart` — semantic speech/visual-text normalization plus legacy speech guard.
- `lib/core/nursery/nursery_visuals.dart` — semantic/countable visual resolver and compact visual-token groups.

Nursery presentation:

- `lib/features/nursery/nursery_game_value.dart` — semantic compound (`&`) picture values.
- `lib/features/nursery/nursery_lesson_activity.dart` — uses authored structured `visualTokens` for prompt pictures.
- `lib/features/nursery/nursery_visual.dart` — renders explicit semantic prompt tokens.

Nursery Math/My World QA reference:

- `lib/core/qa/nursery_math_world_audit.dart` — audits semantic visual quantities instead of scraping emoji from prompts.
- `lib/core/qa/nursery_math_world_reference.dart` — semantic expected/generated visual catalogs.
- `lib/core/qa/teaching_correctness_audit.dart` — validates generated semantic quantity labels instead of counting legacy dot glyphs.

Tests:

- `test/nursery_emoji_content_migration_test.dart` — canonical migration + generator + legacy compatibility release gate.
- `test/nursery_asset_vector_library_test.dart` — semantic asset/vector/token expectations.
- `test/nursery_visual_architecture_test.dart` — semantic resolver expectations.
- `test/nursery_picture_first_games_test.dart` — migrated semantic sorting payload expectation.
- `test/phase_b_phonics_correctness_test.dart` — semantic letter-card fallback expectations.
- `test/phase_c_count_quiz_integration_test.dart` — canonical picture-first count prompt.
- `test/phase_c_math_world_correctness_test.dart` — semantic speech/Math/My World expectations.

QA documentation:

- `STEP22_NURSERY_EMOJI_CONTENT_MIGRATION_QA.md`
- `MODIFIED_FILES_STEP22_NURSERY_EMOJI_CONTENT_MIGRATION.md`
