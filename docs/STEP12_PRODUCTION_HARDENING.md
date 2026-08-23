# Step 12 — Production Hardening, Cross-Device QA & Release Readiness

Step 12 does not declare BrightQuest Kids commercially released. It hardens the runtime and creates deterministic automated gates while leaving teacher review, child pilots, production store verification and real-device qualification as external evidence.

## Runtime changes

- A root `AppPersistenceBoundary` now flushes both authoritative progress and independent resumable mission slots when the app becomes inactive, hidden, paused or detached, on memory pressure, and on root disposal.
- `GameController.flushAll()` gives the lifecycle boundary one explicit durability operation while preserving the existing separate progress and schema-v1 session stores.
- Windows/desktop audio now treats `AppLifecycleState.hidden` like other background states, pausing music and stopping narration without changing the crash-isolated `System.Speech` and MCI backends.
- System accessibility text scaling is no longer overwritten by the in-app reading-size preference. The larger of the system and BrightQuest preference is respected up to the Step 12 tested ceiling of 2x.
- Extremely short free-form/tablet/desktop windows prioritize the five navigation destinations and temporarily remove only decorative brand/profile chrome below 460 logical pixels of height.

## Automated qualification matrix

The Step 12 regression suite covers the layout classes represented by these logical surfaces:

- 360×640 compact Android phone
- 640×360 phone landscape / short free-form surface
- 700×800 tablet
- 800×480 short tablet/free-form surface
- 1024×600 Windows/Android free-form
- 1280×520 short Windows desktop
- 1440×900 desktop
- 1920×1080 large desktop

The matrix validates minimum interaction targets, shell construction, compact Nursery construction, reduced-motion/high-contrast combinations, multi-slot persistence flush, system text-scale resolution and the static Windows crash-isolation contract.

## Automated gate

Windows PowerShell:

```powershell
tool\qa\run_step12.ps1
```

To additionally produce local release builds after all automated gates pass:

```powershell
tool\qa\run_step12.ps1 -BuildReleaseArtifacts
```

Linux/macOS/CI:

```bash
tool/qa/run_step12.sh
```

Set `BUILD_RELEASE_ARTIFACTS=1` to include Android/Windows release build commands where the host supports them.

## Fail-closed external gates

The source must continue to report commercial shipping as blocked until real evidence is recorded for all applicable external gates:

- qualified teacher/content sign-off;
- supervised child usability/pilot sessions;
- Google Play and Microsoft Store production purchase/restore verification;
- privacy, Data Safety/store listing and reviewer-instruction review;
- Android phone/tablet/free-form real-device qualification;
- native Windows resize/sleep-resume/narration/crash soak;
- Windows semantics canary qualification before any default semantics restoration;
- signed store artifacts and final screenshots/support material.

Automated tests can prove source invariants and regressions. They cannot substitute for those external qualification activities.
