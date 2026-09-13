# BrightQuest Kids — Phase 7+8 overlay

This is a **modified-files overlay**, not a full repository source archive.

## Apply

From the BrightQuest repository root:

1. Extract this ZIP into the root and replace matching files.
2. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\APPLY_PHASE_07_08.ps1
```

3. Run the commands in `PHASE_07_08_QA.md`.

The PowerShell patcher is required because several large files were untouched by
Phase 3–6 and are intentionally patched in-place against the user's already
qualified local repository rather than being reconstructed from partial source
snippets.
