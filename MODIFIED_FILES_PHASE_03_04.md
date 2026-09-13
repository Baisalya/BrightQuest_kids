# Modified Files — Phase 03 + 04

Baseline: `master` @ `973a0eef94fad30e154bc322540c3a3b2257fecf`

## New

- `lib/app/learner_shell_policy.dart`
  - Pure learner-shell destination and class-density policy.
- `test/learner_shell_policy_test.dart`
  - Class 3 / Class 4-5 / defensive fallback policy coverage.
- `docs/PHASE_03_04_LEARNER_SHELL.md`
  - Architecture and phase-boundary documentation.
- `PHASE_03_04_QA.md`
  - Static QA and local qualification commands.
- `MODIFIED_FILES_PHASE_03_04.md`
  - This manifest.

## Modified

- `lib/app/brightquest_app.dart`
  - Replaces integer five-tab shell with typed learner destinations.
  - Separates parent controls from learner navigation.
  - Adds shared class-adaptive navigation policy consumption on bottom/side navigation.
  - Preserves active-only page mounting and existing persistence/audio/text-scale boundaries.
- `lib/features/parent/parent_gate_screen.dart`
  - Preserves existing PIN flow and adds a route-aware back affordance for the new pushed parent route.
- `test/adaptive_ui_architecture_test.dart`
  - Updates navigation contracts and adds guarded-parent/class-density regressions.
- `test/widget_smoke_test.dart`
  - Updates shell semantics, parent-route and Windows profile-navigation coverage.
- `test/widget_test.dart`
  - Updates root-shell semantic smoke contract.
- `test/step12_production_hardening_test.dart`
  - Keeps the existing short/free-form shell qualification aligned with the new `Today` semantic.
