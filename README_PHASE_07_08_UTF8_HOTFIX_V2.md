# Phase 7+8 UTF-8 Apply Hotfix v2

## Why this hotfix exists

The original `APPLY_PHASE_07_08.ps1` was UTF-8 without BOM. Windows PowerShell
5.1 can decode such scripts using the legacy system code page. The first patch
was ASCII-only and validated, but the next source contract contained the child
emoji default, so its decoded text no longer matched the UTF-8 Dart source.

The original script is atomic: because validation stopped before the write
section, the six large production files were not partially changed.

## What v2 changes

This package uses a Dart patcher instead of PowerShell.

- The patch payload is Base64-encoded UTF-8, so the patch file itself is ASCII.
- Dart decodes source and patch data as UTF-8 explicitly.
- CRLF/LF is normalized before matching.
- All 30 source contracts are validated and staged in memory.
- No production file is written unless every contract validates.
- It is idempotent: already-applied Phase 7+8 blocks are accepted.

## Apply from the BrightQuest repository root

```powershell
dart run .\tool\apply_phase_07_08_utf8.dart
dart format lib test
flutter analyze
```

Then run the focused Phase 7+8 tests:

```powershell
flutter test test\learner_stage_persistence_test.dart
flutter test test\nursery_first_class_shell_test.dart
flutter test test\learning_session_continue_test.dart
flutter test test\phase7_8_architecture_test.dart
flutter test test\phase5_6_home_worlds_architecture_test.dart
flutter test test\game_session_resume_safety_test.dart
flutter test test\nursery_calm_home_test.dart
flutter test test\nursery_simple_game_flow_test.dart
flutter test test\adaptive_ui_architecture_test.dart
flutter test test\widget_smoke_test.dart
```

If those pass:

```powershell
flutter test
```

Do not run the old `APPLY_PHASE_07_08.ps1` again.
