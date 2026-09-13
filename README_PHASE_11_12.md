# BrightQuest Kids — Phase 11+12 modified-files overlay

This ZIP is a modified-files overlay, not a full repository source archive.

## Apply from repository root

1. Extract the ZIP into the current qualified BrightQuest repository.
2. Replace matching full files.
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase11_12_release_gate.ps1
```

Do not manually run old Phase 7/8 patch scripts again.

The Phase 11+12 release gate applies only its own idempotent UTF-8 Dart patcher,
then qualifies the new capability and accessibility boundaries.
