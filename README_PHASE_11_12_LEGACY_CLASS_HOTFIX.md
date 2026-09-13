# Phase 11+12 Legacy Class Migration Hotfix

The Phase 11 capability test exposed a real deserialization gap:
`ChildProfileSnapshot.fromJson()` accepted any persisted integer class.

This hotfix changes only persisted-profile restoration:

- stored Class 3 -> Class 3
- stored Class 4 -> Class 4
- stored Class 5 -> Class 5
- stored Class 1/2/6/other invalid integer -> Class 4
- missing class -> Class 4

It does not create Class 1/2/6 content and does not change valid profiles.

## Apply from repository root

```powershell
dart run .\tool\phase11_12_legacy_class_hotfix.dart
dart format lib\core\models\progress_models.dart
flutter analyze
flutter test test\learner_capability_boundary_test.dart
```

If that passes, rerun the original Phase 11+12 release gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase11_12_release_gate.ps1
```

The original Phase 11+12 patcher is idempotent, so already-applied contracts
will be accepted.
