# Phase 13 + Phase 14 — Migration compatibility + release certification

## Purpose

This is the final architecture/release pair. It does not add learner features.
It certifies that the Phase 1–12 product can upgrade old local state safely,
recover from corrupt resumability data, preserve authoritative progress, and
pass a repeatable production-oriented regression gate.

## Schema decision

No schema bump is introduced.

- Player/progress snapshot: schema **6**
- Game-session checkpoints/store: schema **1**

Both schemas already support the Phase 7–12 additive fields and behavior. A
version bump without an incompatible storage-format change would add migration
risk without adding a real migration boundary.

## Progress migration matrix

The SharedPreferences progress store keeps this fallback order:

1. `brightquest.player_snapshot.v6`
2. `brightquest.player_snapshot.v5`
3. `brightquest.player_snapshot.v3`
4. `brightquest.player_snapshot.v2`

A corrupt/non-map current snapshot does not block a still-valid supported
legacy snapshot. The next authoritative write goes to v6 and removes the
legacy keys.

Certified profile migrations include:

- old snapshot with no `learnerStage` -> `LearnerStage.school`;
- explicit Nursery remains Nursery;
- remembered valid School class 3/4/5 stays unchanged;
- missing/unsupported stored School class -> Class 4;
- old single-child root object -> current multi-profile container;
- invalid active-profile pointer -> an existing profile;
- map-key / embedded-profile-ID mismatch -> persisted map key is authoritative;
- coins/stars/XP/rewards survive supported migration paths.

## Entitlement-cache safety

Persisted class entitlement data is only a display/recovery cache. It must not
become current production authorization.

Phase 13 additionally rejects cached entries when:

- the map key is outside shipped Classes 3/4/5; or
- the payload's class number does not match the map key.

A store/backend-verified entitlement serializes back as `localCacheOnly`, so a
restarted app must verify with the store again before paid access is granted.

## Session recovery boundary

Game sessions are convenience/resumability state, not authoritative progress.

Certified behavior:

- schema-v1 sessions round-trip by canonical slot key;
- one corrupt checkpoint can be ignored while valid siblings survive;
- malformed/wrong-schema outer session storage is cleared;
- session corruption does not remove progress storage;
- controller restore discards sessions invalid for the current app while
  preserving profile progress;
- the existing stale/future/profile/class/game/level guards remain covered by
  the broader resume-safety regression suite.

## Release certification

`tool/phase13_14_release_certification.ps1` performs:

1. narrow idempotent Phase 13 migration hardening;
2. formatting;
3. semantic migration/release invariant verification;
4. `flutter analyze`;
5. focused Phase 13 migration/recovery tests;
6. representative Phase 1–12 architecture/regression gates;
7. deterministic mission/content quality audit;
8. full `flutter test`;
9. QA certificate emission **only after every gate passes**.

The certificate is written to:

`build/phase13_14_release_certification.txt`

### Default certification

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase13_14_release_certification.ps1
```

### Strict clean-git certification

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase13_14_release_certification.ps1 -RequireCleanGit
```

This certification runner is permanently QA-only. It accepts no Android or
Windows build switch; artifact generation is a separate packaging action.

## Release interpretation

A default PASS certifies source analysis, migrations, corruption recovery,
architecture invariants, content audit and the complete automated Flutter test
suite on that local checkout.

It does not by itself claim:

- Play Store approval;
- Microsoft Store approval;
- signed-store ownership verification;
- teacher review not represented by existing content contracts;
- real-device performance beyond the device tests actually run.
