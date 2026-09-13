# Phase 03 + 04 QA

Baseline branch: `master`

Baseline commit: `973a0eef94fad30e154bc322540c3a3b2257fecf`

## Static checks completed in the delivery environment

PASS:

- All modified/new Dart files have balanced `()`, `[]` and `{}` delimiters.
- `ParentGateScreen` is not part of the learner `_pageFor` destination mapping.
- There is no `LearnerShellDestination.parent` value.
- `Grown-up area` is the separate parent utility action.
- `Today`, `Worlds`, `Journey` and `Me` learner semantics are present.
- `AppPersistenceBoundary` remains wired into `BrightQuestApp`.
- system text scaling still uses `media.textScaler.scale(1)` and `brightEffectiveTextScale`.
- `IndexedStack` is not introduced.
- compact utility-width arithmetic is a `double` expression.
- Class 3 and Class 4/5 policies are explicit and covered by a pure policy test.
- updated shell tests no longer depend on the removed `Home`, `Progress`, `Profile` or parent-tab semantics.
- parent pushed-route regression checks the existing gate and visible back affordance.

## Runtime status

Flutter and Dart executables are not installed in the delivery runtime, so `dart format`, `flutter analyze` and `flutter test` could not be executed here. No runtime-pass claim is made.

Run from the BrightQuest repository root after overlaying the modified-files ZIP:

```powershell
dart format lib/app/brightquest_app.dart lib/app/learner_shell_policy.dart lib/features/parent/parent_gate_screen.dart test/learner_shell_policy_test.dart test/adaptive_ui_architecture_test.dart test/widget_smoke_test.dart test/widget_test.dart test/step12_production_hardening_test.dart
flutter analyze
flutter test test/learner_shell_policy_test.dart
flutter test test/adaptive_ui_architecture_test.dart
flutter test test/widget_smoke_test.dart
flutter test test/widget_test.dart
flutter test test/step12_production_hardening_test.dart
flutter test
```

Any analyzer/test failure should be treated as a blocker before starting Phase 5 + 6.
