# BrightQuest Kids Store release runbook

This is the first file an AI should read for a BrightQuest release request.

## Choose one action

If the owner has not already selected an action, ask which of these three jobs
is wanted:

1. QA/testing only.
2. Generate only: choose Android AAB, Windows executable, or future MSIX.
3. Store action only: upload an existing artifact or promote the exact tested
   artifact to Production.

Never combine QA and artifact generation in one command. When the owner says
the current source is already tested, do not rerun Phase D merely because an
artifact was requested. Store upload/promotion always reuses the existing
artifact and never rebuilds or retests it.

## QA only

```powershell
.\tool\qa\run_phase_d.ps1
```

This default runs Phase D validation, the complete Flutter tests, and analysis.
It does not build Android or Windows artifacts. Record the source commit or
working-tree identity, date, commands, and result before reusing this evidence.

`run_phase_d.ps1` and `run_phase_d.sh` are permanently QA-only. They accept no
artifact-build switch.

## Android AAB packaging only

When QA is already accepted for the current source:

```powershell
flutter pub get
flutter build appbundle --release
Get-FileHash .\build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
```

Record package ID, version name/code, signing certificate, size, SHA-256, build
flags, and the reused QA evidence before upload.

## Windows build and MSIX status

The current repository can build a Windows executable:

```powershell
flutter pub get
flutter build windows --release
```

This is not a Microsoft Store MSIX. BrightQuest has no canonical Partner Center
identity/manifest/MSIX packaging workflow yet. If MSIX generation is selected, stop and
report that MSIX packaging must first be implemented and verified; never rename
the Windows build or an archive to `.msix`.

## Upload and promotion

- Upload only the recorded artifact with its existing version and SHA-256.
- Closed/internal testing does not require another local build.
- Production promotion must use the exact artifact that passed Store/device QA.
- Do not run Phase D, tests, analysis, or a build during promotion.
- Billing remains fail-closed. No ₹299 class pack is commercially releasable
  until the human/content/device and real Store verification gates in
  `RELEASE_QA_CHECKLIST.md` and `STORE_BILLING_INTEGRATION.md` pass.
