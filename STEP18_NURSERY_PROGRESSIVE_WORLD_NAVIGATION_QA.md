# Step 18 — Nursery Progressive World & Skill Navigation QA

## Scope

This step changes Nursery navigation only. Existing Nursery content IDs, activity IDs,
mastery/evidence states, review scheduling, saves, TTS, asset decoding and Classes 3–5
content remain unchanged.

## Architecture

- `NurseryWorldPlanner` is a pure presentation planner over existing stable skill IDs.
- `NurseryWorldScreen` owns world/path navigation and no longer lives inside the calm-home file.
- `NurseryHomeScreen` remains focused on the one-primary-action + four-world landing experience.
- Domain labels/colours are shared through `nursery_domain_presentation.dart`.
- No new persistence field, content schema, backend, package or network dependency was added.

## Child-facing path map

- ABC & Sounds: 4 paths / 10 existing skills
- Numbers: 4 paths / 11 existing skills
- My World: 3 paths / 7 existing skills
- Match & Think: 3 paths / 4 existing skills

Every current authored Nursery skill belongs to exactly one path. Each path contains at
most three skills so a child does not see a 10–11 item skill dump.

## Recommendation order

Within a world, the recommended path is derived from existing state only:

1. A path containing a due review skill.
2. The path containing the most recently active skill.
3. The first unfinished path.
4. The first path when everything is secure.

The child is guided but not locked out of other paths.

## Static checks performed in this environment

- Current 32 authored Nursery skills are covered exactly once by the path catalog.
- No path contains more than three current skills.
- No Nursery content JSON or save/evidence model was modified.
- Step 2 semantic visual resolver is reused for path visuals.
- `NurseryHomeScreen` is reduced to calm-home responsibilities; world navigation is isolated.
- Full and modified-file ZIP integrity is checked after packaging.

## Flutter qualification

Flutter/Dart SDK is not available in the execution container. Run on the project machine:

```powershell
flutter analyze
flutter test test/nursery_progressive_world_navigation_test.dart
flutter test test/nursery_simple_game_flow_test.dart
flutter test test/nursery_layout_test.dart
flutter test
```
