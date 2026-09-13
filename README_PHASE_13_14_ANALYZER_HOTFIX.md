# Phase 13+14 Analyzer Hotfix

The first certification run reached the analyzer after:

- Phase 13 migration hardening applied successfully;
- all 14 semantic release invariants passed.

`flutter analyze` then failed only because the verifier helper declared an
optional `minimum` constructor parameter that no check ever overrode:

`unused_element_parameter`

This hotfix changes only:

`tool/verify_phase13_14_release_invariants.dart`

The unused optional parameter and field are removed. Every invariant still
requires at least one regex match, which is exactly the behavior the current
check list used.

Production files changed: **0**

## Apply

Extract this ZIP into the repository root, then run:

```powershell
dart format .\tool\verify_phase13_14_release_invariants.dart
flutter analyze
powershell -ExecutionPolicy Bypass -File .\tool\phase13_14_release_certification.ps1
```

Do not use `-RequireCleanGit` yet unless you first commit or stash the Phase
13+14 changes. A dirty working tree is expected while applying/testing this
phase.
