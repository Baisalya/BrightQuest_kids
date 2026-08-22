# Phase D Release-Candidate Checklist

This checklist separates **implemented automated gates** from **results that still require execution/evidence**. Do not tick an execution or external-evidence item merely because the supporting code exists.

## Implemented automated coverage

- [x] Phase D fail-fast PowerShell runner added.
- [x] Verified Phase C (and therefore A+B) is a prerequisite of the Phase D runner.
- [x] Whole-pack `en-IN` localization consistency audit added for Nursery and Classes 3–5.
- [x] Prompt/explanation/narration/feedback completeness checks added.
- [x] Nursery finite-motion source audit added.
- [x] A–Z image source/decode performance budgets added.
- [x] A–Z Garden 128×128 thumbnail decode optimization implemented.
- [x] Max-text/high-contrast/reduced-motion responsive Nursery widget coverage added.
- [x] Stable answer semantics regression added.
- [x] Android release AAB build step added to the Windows Phase D gate.
- [x] Normal crash-isolated Windows release build step added to the Windows Phase D gate.

## Machine verification — pending until run

- [ ] `dart format --output=none --set-exit-if-changed lib test tool`
- [ ] verified Phase C baseline completes inside the Phase D runner
- [ ] Phase D release-candidate static audit passes
- [ ] Class 3–5 content validator passes
- [ ] Nursery content validator passes
- [ ] release-safety validator passes
- [ ] focused Phase D tests pass
- [ ] complete Flutter regression suite passes
- [ ] `flutter analyze` reports zero issues
- [ ] Android release AAB builds successfully
- [ ] normal Windows release build succeeds without restoring unsafe Windows TTS/semantics defaults
- [ ] runner prints `=== Phase D completed successfully ===`

## External release evidence — intentionally pending

- [ ] qualified teacher/content reviewer sign-off
- [ ] supervised child usability/learning pilot evidence
- [ ] production Google Play purchase/pending/refund/restore verification
- [ ] production Microsoft Store entitlement verification if distributed there
- [ ] privacy/Data Safety/store-listing review
- [ ] Android real-device low-memory/free-form/sleep-resume soak
- [ ] native Windows resize/sleep-resume/crash soak
- [ ] Windows Narrator semantics canary qualification
- [ ] signed store artifacts and reviewer/support instructions accepted

A green automated Phase D creates a **technical release candidate**. It does not by itself make the ₹299 pack commercially eligible.
