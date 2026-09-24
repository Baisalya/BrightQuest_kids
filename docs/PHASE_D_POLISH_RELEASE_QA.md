# Phase D — Polish & Release Candidate QA

## Purpose

Phase D is the final technical QA/polish pass after the verified Phase A–C learning-correctness gates. It does **not** convert BrightQuest into a commercially approved release. Qualified teacher sign-off, supervised child pilots, production store verification, privacy/store review, and real-device/native Windows qualification remain external release gates and are deliberately left pending.

## Scope

Phase D covers four technical areas:

1. **Regression sweep and final fixes** — preserve all Phase A, B and C teaching-correctness gates and run the complete Flutter regression suite again after Phase-D changes.
2. **Performance polish** — keep Nursery motion finite, reject repeating timers/animations, keep the 208 local letter-card bundle bounded, and decode A–Z garden thumbnails at 128 px instead of decoding 26 full 512 px cards simultaneously.
3. **Accessibility evaluation** — test representative Alphabet, Math, My World and Thinking boards at compact phone, tablet and Windows/free-form sizes with maximum supported text scale (1.3), high contrast, dyslexia-friendly spacing and reduced motion enabled. Answer choices must expose stable spoken semantics and remain touch/mouse/keyboard-compatible through standard Flutter controls.
4. **Localization review** — all currently shipped authored learning content remains explicitly `en-IN`; no Hindi or mixed-locale content is enabled without a separately reviewed translation pack. Prompts, explanations, narration, hints and feedback must remain non-empty. Classes 3–5 authored activity narration is stored as the structured `narration.text` field; learning blueprints use `narrationText`. The Phase-D gate validates those real contract fields rather than stringifying the containing JSON object.

## Performance budgets

These are defensive source/runtime budgets for the current Nursery implementation, not marketing claims:

- no `Timer.periodic`, `.repeat(` or repeating animation controller in `lib/features/nursery/`;
- each A–Z source card is at most 512×512 and 128 KiB;
- the complete A–Z card bundle remains at most 6 MiB;
- the A–Z Letter Garden requests 128×128 decode-cache thumbnails because 26 cards can be visible in one scrolling surface;
- reduced-motion mode must keep the same learning content and controls while suppressing optional entrance/reaction motion.

## Automated Windows gate

Run from the repository root:

```powershell
dart format lib test tool
.\tool\qa\run_phase_d.ps1
```

`run_phase_d.ps1` is fail-fast and performs:

1. formatting gate;
2. complete verified Phase-C gate (which itself preserves Phase A + B);
3. Phase-D release-candidate audit;
4. Class 3–5 and Nursery content validators;
5. static release-safety validator;
6. Phase-D accessibility/localization/performance tests;
7. complete Flutter test suite;
8. `flutter analyze`.

The default command is QA-only. Add `-BuildAndroidAab` or `-BuildWindows` only
when that artifact is explicitly requested. See `STORE_RELEASE_RUNBOOK.md`.

Only the PowerShell runner may print:

```text
=== Phase D completed successfully ===
```

The success line proves only the selected QA/build actions. A default run does
not prove an Android or Windows artifact was built. The shell runner can
validate the same source/tests on a non-Windows host, but it cannot close a
separately requested Windows build gate.

## Release-candidate output vs commercial release

A green Phase D means the repository has passed the automated technical release-candidate gate on the machine that ran it. It still does **not** prove:

- qualified teacher/content approval;
- supervised child usability or learning evidence;
- Google Play/Microsoft Store purchase/restore/refund verification;
- privacy/store-listing approval;
- Android real-device soak;
- Windows Narrator/semantics canary qualification;
- native Windows resize/sleep-resume/crash soak;
- signed store artifact acceptance.

`paidEligibility` and external Nursery release gates must therefore remain fail-closed until those records genuinely exist.
