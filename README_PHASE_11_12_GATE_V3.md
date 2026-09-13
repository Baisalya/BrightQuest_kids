# Phase 11+12 Release Gate v3

This is a verifier-only fix. Production source is not modified.

The v2 semantic verifier required this exact lexical shape:

`LearnerCapabilityBoundary.supportedSchoolClasses`

After `dart format`, one Parent Dashboard occurrence can be split as:

```dart
LearnerCapabilityBoundary
    .supportedSchoolClasses
```

That is the same Dart expression, but the v2 regular expression did not allow
whitespace around the dot. It therefore reported 1 match instead of 2.

v3 changes only the verifier expression to accept formatter whitespace around
the member-access dot while still requiring two Parent Dashboard selector
occurrences.

## Run

Extract this ZIP into the repository root, then:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase11_12_release_gate_v3.ps1
```

Do not rerun the original Phase 11 source patcher. v3 first semantically verifies
the already-applied source, then runs format, analyze, focused regressions and
the full Flutter test suite.
