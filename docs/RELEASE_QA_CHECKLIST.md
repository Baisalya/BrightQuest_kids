# BrightQuest Kids Release QA Checklist

## Automated gate

- Run `dart format lib test tool`.
- Run `flutter analyze` with zero warnings/errors.
- Run `flutter test` and all content/release tools.
- Build Android release AAB/APK and Windows release executable.
- Verify schema-v5 migration from legacy saves and corrupted-save fallback.
- Verify Class 3/4/5 content and free samples offline.
- Verify no `AD_ID`, ads SDK, child chat or social upload path is present.
- Verify local entitlement edits cannot grant production access.
- Verify Windows generated plugin registration does not restore `flutter_tts`.

## Real-device gate

- Android: compact 360×640, tablet, free-form resize, low-memory resume, sleep/resume and offline cold start.
- Windows: resize, sleep/resume, repeated narration, repeated game navigation and native crash soak.
- Accessibility: keyboard focus, large text, high contrast, reduced motion, colour-independent feedback and Android screen-reader checks.
- Windows Flutter semantics remain disabled until a separate native engine/plugin soak proves restoration safe.

## Human gate

- Qualified primary teacher signs each release content matrix.
- Five-child supervised usability sessions are completed for the relevant class pack.
- Privacy/Data Safety/store listing and screenshots are reviewed.
- Unseen pre/post pilot is analysed without making unsupported efficacy claims.

No class pack should be marked commercially ready until every applicable external gate is recorded with real evidence.
