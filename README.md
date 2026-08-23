# BrightQuest Kids

BrightQuest Kids is an offline-first Flutter learning adventure for Classes 3–5. It targets Android phones/tablets/free-form windows and Windows desktop from one responsive codebase.

Current version: **0.6.0+26**

Nursery implementation status: a separate draft Nursery learning pack is present in source with interactive teaching, scorable evidence/review, 208 offline A–Z picture-word cards, a stricter 157-example simple-phonics evidence pool, and fail-closed commercial eligibility. Phase B Letters & Sounds includes an independent phonics audit and skill-accurate Alphabet game-board regressions. It is not a production/commercial approval claim; qualified teacher review, child pilots, store configuration, device qualification and release builds remain required.

## Current product

- six Learning Worlds and nine adventure/reward experiences;
- validated separate Class 3, 4 and 5 JSON content packs plus 111 competency learning blueprints;
- 24 Practice → Challenge → Mastery path levels per class;
- adaptive Quick Play, resumable Discovery Check diagnostic, competency evidence and Power Review;
- first-try-aware scoring, achievements, stars, coins and rewards;
- independent local child profiles and save migration;
- parent PIN, learning goals, healthy-play time limits, competency evidence reports and weak-area summaries;
- responsive layouts for Android, Android free-form and Windows;
- offline BGM/SFX plus authored lesson/game narration, visible transcripts and smart prompt/choice/answer read-aloud;
- selectable installed voices with female-first selection and separate BGM/SFX/speech controls;
- high contrast, text scaling, reduced motion, haptics, dyslexia-friendly spacing, active Reading Focus and visible narration/audio captions;
- parent-only fail-closed ₹299 class entitlement foundation with free-sample boundaries; production store verification is intentionally not enabled yet.

The current release contains the technical learning-platform foundation through roadmap Phase 10, but it is **not commercially complete**: curriculum/content remains `needsReview`, production store verification is not configured, and teacher/pilot/real-device release gates are pending. It is not represented as CBSE/NCERT certified. See [PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md) for the exact technical-versus-external gate status.

## Learning model today

The application currently provides eight curriculum tracks per class:

- Maths: operations and fractions;
- English: story/sentence building and grammar;
- Science;
- EVS and recycling;
- map/geography skills;
- coding and algorithms.

Each track generates Practice, Challenge and Mastery levels. Quick Play remains separate and uses demonstrated game mastery to recommend difficulty. Retry-friendly games distinguish eventual success from first-try mastery so retries cannot create a misleading perfect score.

## Project layout

```text
lib/
  app/
  core/
    content/
    curriculum/
    gameplay/
    learning/
    entitlements/
    models/
    persistence/
    services/
    state/
    theme/
  features/
    adventures/
    games/
    home/
    parent/
    profile/
    progress/
  widgets/
test/
tool/
assets/
```

## Bootstrap and run

Windows PowerShell:

```powershell
./bootstrap_windows.ps1
flutter run -d windows
```

Android/macOS/Linux shell:

```bash
./bootstrap.sh
flutter run
```

Release qualification:

```powershell
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build apk --debug
flutter build windows
dart run tool/content/validate_content.dart
dart run tool/content/validate_learning_blueprints.dart
dart run tool/release/readiness_report.dart
dart run tool/windows_speech_smoke.dart
```

## Windows runtime safety

- Windows BGM and effects use the local MCI backend instead of the unstable `audioplayers_windows` event-channel runtime.
- The local Android-only `flutter_tts` fork prevents `flutter_tts_plugin.dll` from being registered or bundled on Windows.
- Windows narration uses installed `System.Speech` voices in a hidden child process, keeping speech-engine failures outside Flutter.
- Production Windows semantics remain temporarily excluded because the current native Flutter accessibility bridge previously produced invalid AXTree access violations. Android semantics remain enabled.

Do not restore Windows native TTS registration or Windows semantics without native crash/soak qualification.

## Audio asset origin

The BGM and SFX files under `assets/audio/` were generated specifically for this BrightQuest Kids source package. No third-party music or sound-effect files are bundled. Dynamic narration uses voices installed on the device. BGM is ducked during narration and restored afterward.

## Documentation

- [PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md): phase-by-phase learning, content, billing, privacy and release plan;
- [CHANGELOG.md](CHANGELOG.md): completed version history and technical fixes.

## Product boundary

BrightQuest remains offline-first, ad-free and child-safe by design. It currently has no cloud account, social feed, child chat, advertising SDK, remote analytics or production purchase entitlement. Those boundaries must only change through the reviewed phases and release gates in the roadmap.
