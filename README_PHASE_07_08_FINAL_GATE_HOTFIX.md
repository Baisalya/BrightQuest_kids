# Phase 7+8 Final Gate Hotfix

This hotfix changes **tests only**. No production file is modified.

## Fix 1 — Phase 7+8 architecture contract

The test searched NurseryHomeScreen source for the literal `rootMode:`. The
actual implemented constructor is `this.rootMode = false`, with
`final bool rootMode;`, so the old assertion was incorrect.

The replacement checks the actual persisted root-mode API shape.

## Fix 2 — Windows speech host capability

`audio_experience_test.dart` already verifies the deterministic app contract:

- `System.Speech` is used;
- PowerShell `-EncodedCommand` is used;
- speech is process-isolated;
- voice selection is implemented;
- UTF-16LE command encoding is correct.

The old runtime tail additionally required every Windows test host to have an
enabled System.Speech voice. That is machine configuration and can transiently
or permanently be unavailable. `WindowsSpeechBackend` intentionally handles
this by remaining unavailable rather than crashing the learning app.

The updated runtime assertion verifies:
- if unavailable, the backend reports an empty voice list consistently;
- if available, voices must be non-empty and female-default selection is still
  validated when female voices exist.

## Apply from repo root

```powershell
dart run .\tool\phase7_8_final_gate_hotfix.dart
dart format test\phase7_8_architecture_test.dart test\audio_experience_test.dart
flutter analyze

flutter test test\phase7_8_architecture_test.dart
flutter test test\audio_experience_test.dart
flutter test
```
