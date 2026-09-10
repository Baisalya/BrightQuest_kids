# Nursery Final Release Checklist

This checklist closes the Nursery Steps 1–10 implementation track. It does not mark external commercial or real-device gates complete; those remain fail-closed until they are actually recorded.

## Automated qualification

Run on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File tool/qa/run_nursery_final.ps1
```

The runner must complete:

- `flutter analyze` with no issues;
- the Nursery final release gate;
- emoji/content migration regression;
- finite/reduced-motion regression;
- lesson architecture regression;
- picture-first game regression;
- Study → Guided Play → Independent Game regression;
- simple-game and responsive-layout regression;
- Phase A teaching-correctness audit;
- Phase B phonics audit;
- Phase C count/math/My World audits;
- Phase D accessibility/release-candidate audits;
- the complete `flutter test` suite.

## Frozen Nursery product contracts

Before release-candidate tagging, automated tests must still confirm:

- 4 Nursery domains;
- 32 stable skill IDs;
- 132 stable authored activity IDs;
- 26 letter associations;
- 208 local letter-card assets;
- canonical Nursery content is semantic rather than emoji-based;
- legacy emoji/geometric responses remain compatible through the isolated adapter;
- every skill has Study → Guided Play → Independent Game reachability;
- response evaluation and deterministic generated practice remain self-consistent;
- Nursery motion is finite, respects reduced motion, and avoids periodic/repeating loops;
- local image decode bounds and asset budgets remain enforced;
- no new Nursery cloud/network dependency is introduced.

## External gates that must remain fail-closed until completed

Do not change the corresponding pack flags merely because automated tests pass. Record these only after real completion:

- qualified teacher/content review;
- supervised child pilot;
- production store billing configuration/verification;
- Android phone/tablet/free-form qualification;
- Windows desktop soak/qualification;
- privacy/store listing review;
- signed production artifacts and support/release evidence.

Automated QA passing means the code/content baseline is internally qualified. It does not replace these external release gates.
