# BrightQuest Kids

BrightQuest Kids is an offline-first Flutter learning adventure for Classes 3–5. It targets Android phones/tablets/free-form windows and Windows desktop from one responsive codebase.

Current version: **0.4.21+24**

## Current product

- six Learning Worlds and nine adventure/reward experiences;
- separate Class 3, 4 and 5 content banks;
- 24 Practice → Challenge → Mastery path levels per class;
- adaptive Quick Play and topic/game progress;
- first-try-aware scoring, achievements, stars, coins and rewards;
- independent local child profiles and save migration;
- parent PIN, learning goals, healthy-play time limits and weak-area summaries;
- responsive layouts for Android, Android free-form and Windows;
- offline BGM/SFX plus smart prompt, choice and answer narration;
- selectable installed voices with female-first selection and separate BGM/SFX/speech controls;
- high contrast, text scaling, reduced motion and haptics preferences.

The current release is a strong technical prototype. It is not yet represented as a complete paid curriculum pack or as CBSE/NCERT certified. The implementation-ready path to a genuine ₹299-per-class product is in [PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md).

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
