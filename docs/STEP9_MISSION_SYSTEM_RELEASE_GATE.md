# Step 9 — Mission System Production Release Gate

This is the final release gate for the Classes 3–5 Learning World mission-system refactor (Steps 1–9).

## Automated gate

Run on Windows:

```powershell
.\tool\qa\run_step9.ps1
```

The gate fails closed and requires all of the following to pass:

1. `flutter analyze`
2. Step 9 persistence/longevity/replay tests
3. crash/resume/reward-idempotency regression tests
4. Step 8 focused content/balance tests
5. Step 8 128-seed audit (72 levels, 864 generated activities, 9,216 simulated runs)
6. complete `flutter test` regression suite

The mission system remains on `PlayerSnapshot.schemaVersion = 6`, `GameSessionCheckpoint.schemaVersion = 1`, `MissionRunPlan.schemaVersion = 1`, and `MissionExposureMemory.schemaVersion = 1`. Step 9 does not require a destructive migration.

## Shipping invariants

- Explicit World replay after a completed result starts a fresh encounter instead of reopening the old result checkpoint.
- In-progress lesson/game/completing checkpoints still resume.
- Reward completion remains idempotent across process death and reload.
- Mission anti-repeat memory is bounded and profile/class isolated.
- Unknown/corrupt anti-repeat-memory schemas fail closed to empty advisory history without deleting authoritative progress.
- Training/Game allocation remains exact-tier, non-overlapping and content-deduplicated.
- Existing Class 3/4/5 unlock, stars, coins, XP, mastery and retention semantics remain authoritative.
- Generated content that passes automated checks remains `needsReview`; automation does not certify curriculum content.
- Windows keeps crash-isolated narration and does not restore `flutter_tts_plugin.dll` or Flutter semantics by default.

## Manual device checks still required

Automated tests cannot certify physical-device behavior. Before a public/commercial build, perform and record:

### Android

- phone portrait and landscape
- tablet/free-form/resizable window if supported by the target device
- background → resume during Lesson, Training, Game, and result screens
- force-stop during a game, relaunch, resume, finish, and verify reward is applied once
- switch Class 3 → 4 → 5 and profiles; verify saved missions/history do not leak between them
- verify narration/audio lifecycle, paid hints, parent time limit and accessibility text scale
- exercise at least one fresh replay in every World and confirm the previous result does not reopen

### Windows

- 1280×720, 1366×768, 1920×1080, and a short/free-form window
- close/relaunch during Lesson and Game; verify checkpoint recovery
- close immediately after completion/reward and verify no duplicate reward after relaunch
- validate audio/narration process isolation
- confirm `flutter_tts_plugin.dll` is absent from the production plugin registration unless separately crash-qualified
- keep the Windows semantics canary disabled unless separately native-crash-qualified

## Release decision

`AUTOMATED STEP 9 RELEASE GATE: PASS` means the repository-level mission-system gate is green. It does **not** replace the manual Android/Windows device checks above, store policy review, signing, billing validation, or final human curriculum review of `needsReview` content.
