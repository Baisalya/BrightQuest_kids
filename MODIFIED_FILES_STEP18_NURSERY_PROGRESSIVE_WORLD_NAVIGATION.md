# Step 18 — Modified Files

Compared with the QA-passed Step 17 TestScopeFix baseline:

- `lib/features/nursery/nursery_home_screen.dart`
  - Removes embedded world/skill-detail implementation.
  - Opens the dedicated progressive world screen.
  - Keeps the calm home focused on one primary action and four worlds.
- `lib/features/nursery/nursery_world_screen.dart` (new)
  - Renders recommended path, numbered learning paths and small skill groups.
  - Keeps the ABC Picture Book inside ABC & Sounds.
- `lib/features/nursery/nursery_world_plan.dart` (new)
  - Pure deterministic path catalog/progress/recommendation planner over existing skill IDs.
- `lib/features/nursery/nursery_domain_presentation.dart` (new)
  - Shared child-facing domain labels, subtitles and colours.
- `lib/core/nursery/nursery_visuals.dart`
  - Adds semantic visuals for learning-path identities.
- `test/nursery_progressive_world_navigation_test.dart` (new)
  - Covers complete/unique path mapping, recommendation and world→path navigation.
- `test/nursery_visual_architecture_test.dart`
  - Extends emoji-contract protection to the new world screen.
- `STEP18_NURSERY_PROGRESSIVE_WORLD_NAVIGATION_QA.md` (new)
- `MODIFIED_FILES_STEP18_NURSERY_PROGRESSIVE_WORLD_NAVIGATION.md` (new)
