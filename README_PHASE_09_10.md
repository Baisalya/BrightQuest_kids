# BrightQuest Kids — Phase 9+10 modified-files overlay

This ZIP is a modified-files overlay, not a full repository archive.

## Apply from repository root

1. Extract the ZIP into the BrightQuest repo and replace matching files.
2. Either follow `PHASE_09_10_QA.md`, or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase9_10_release_gate.ps1
```

The release gate formats the changed files, analyzes the app, runs Phase 9+10
targeted/regression tests and then runs the full Flutter test suite.
