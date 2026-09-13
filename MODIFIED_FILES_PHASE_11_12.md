# Modified files — Phase 11 + Phase 12

## New production file

- `lib/core/capabilities/learner_capability_boundary.dart`
  - recognized Nursery→Class 6 span;
  - available Nursery/Class 3/4/5 boundary;
  - unsupported Class 1/2/6 fail-closed helpers.

## Full production replacements

- `lib/app/learner_shell_policy.dart`
  - removes unsupported-class shell fallback.
- `lib/widgets/bright_adaptive.dart`
  - 48dp minimum target;
  - large-text stack helper;
  - readable grid-width helper.
- `lib/app/brightquest_app.dart`
  - 48dp side/bottom navigation targets.
- `lib/features/home/home_screen.dart`
  - large-text-aware Today primary hero.
- `lib/features/progress/progress_screen.dart`
  - large-text-aware Journey hero.
- `lib/features/profile/profile_screen.dart`
  - large-text-aware identity/reward layouts.
- `lib/features/games/rewards_room_screen.dart`
  - large-text-aware hero/actions and wrapping celebration summaries.

## Existing production files patched in-place by tool/apply_phase11_12_hardening.dart

- `lib/core/state/game_controller.dart`
- `lib/features/parent/parent_dashboard_screen.dart`
- `lib/features/parent/class_pack_screen.dart`
- `lib/core/entitlements/entitlement_service.dart`
- `lib/core/content/content_repository.dart`
- `lib/widgets/bright_widgets.dart`
- `lib/widgets/bright_design_system.dart`
- `lib/widgets/learning_accessibility_widgets.dart`

The Dart patcher is UTF-8 explicit, ASCII payload-safe, idempotent and validates
all contracts before writing any of those files.

## Tests

- `test/learner_capability_boundary_test.dart` — NEW
- `test/bright_accessibility_layout_test.dart` — NEW
- `test/phase11_12_accessibility_ui_test.dart` — NEW
- `test/phase11_12_architecture_test.dart` — NEW
- `test/learner_shell_policy_test.dart`
  - unsupported classes now fail closed.
- `test/adaptive_ui_architecture_test.dart`
  - 48dp minimum-target invariant.

## Intentionally untouched

- curriculum/content assets;
- Class 3/4/5 curriculum catalog entries;
- Nursery content/evidence engines;
- reward/economy algorithms;
- achievement and cosmetic catalogs;
- PlayerSnapshot schema;
- entitlement product IDs;
- Parent PIN implementation;
- GameRouter/Phase 7 Continue contract.
