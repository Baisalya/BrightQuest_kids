# BrightQuest Kids Store release runbook

This is the first file an AI should read for a BrightQuest release request.

## Choose one action

If the owner has not already selected an action, ask which one is wanted:

1. QA/testing only.
2. Android AAB build only.
3. Windows executable build only.
4. Microsoft Store MSIX build.
5. Upload an existing artifact to testing.
6. Promote the exact tested artifact to Production.

Do not combine these automatically. When the owner says the current source is
already tested, do not rerun Phase D merely because an artifact was requested.
Store upload/promotion always reuses the existing artifact and never rebuilds
it.

## QA only

```powershell
.\tool\qa\run_phase_d.ps1
```

This default runs Phase D validation, the complete Flutter tests, and analysis.
It does not build Android or Windows artifacts. Record the source commit or
working-tree identity, date, commands, and result before reusing this evidence.

Fresh QA plus one explicitly requested technical artifact is also supported:

```powershell
.\tool\qa\run_phase_d.ps1 -BuildAndroidAab
.\tool\qa\run_phase_d.ps1 -BuildWindows
```

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
identity/manifest/MSIX packaging workflow yet. If action 4 is selected, stop and
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
