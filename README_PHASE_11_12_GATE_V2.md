# Phase 11+12 Release Gate v2

Use this after:

1. the original Phase 11+12 source patcher completed successfully; and
2. the legacy-class migration hotfix was applied.

The original gate reran an exact-text idempotency check after `dart format`.
One Parent Dashboard selector was line-wrapped by the formatter, so the old
patcher saw one exact formatted-new block and one differently formatted-new
block and stopped fail-closed.

This v2 gate does **not** modify production source and does **not** rerun the
original patcher.

Instead it:

1. semantically verifies all important Phase 11+12 production contracts;
2. formats the qualified sources/tests;
3. runs `flutter analyze`;
4. runs the focused/regression tests;
5. runs the full Flutter test suite.

## Run from the repository root

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase11_12_release_gate_v2.ps1
```

Do not run the old `phase11_12_release_gate.ps1` again for this qualification.
