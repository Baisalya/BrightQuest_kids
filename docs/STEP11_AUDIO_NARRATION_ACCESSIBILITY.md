# Step 11 — Audio, Narration & Accessibility Integration

Step 11 connects the existing learning flow, narration preferences and visible accessibility support without changing curriculum correctness, evidence, mastery, rewards, saves or entitlements.

## Runtime architecture

```text
Authored lesson/activity/game prompt
              ↓
      LearningAudioDirector
              ↓
       LearningNarrationCue
        ↙                 ↘
visible transcript      BrightAudioService
(reading/captions)      (existing backends)
```

`LearningAudioDirector` only selects text that already exists in the authored lesson/activity/game state. It does not generate facts, answers, hints or explanations.

`LearningNarrationBar` is the common child-facing boundary. It keeps the current narration text visible when captions are enabled, keeps that text visible in Reading Focus even when captions are disabled, exposes a standard keyboard/touch/mouse Read aloud button, and exposes Stop narration when a voice is available.

## Automatic narration

The existing `bright_audio.auto_narration` preference now applies to Learning World lesson steps as well as game introductions. A lesson cue is spoken at most once for the currently mounted step. Going to another step or resuming a saved step creates a new cue and may narrate that step again.

Main-game question narration remains manual. Game launch already performs the existing guide introduction, so automatically speaking the question at the same moment would create two competing speech requests. The visible transcript and Read aloud control remain available for every `GameScaffold` prompt.

## Visible meaning and Reading Focus

Captions are independent of audio availability. If speech is muted, unavailable or fails, the prompt/lesson text and choices remain visible.

Reading Focus is no longer a stored-only preference for Class 3–5 lesson surfaces. It now:

- keeps the current narration transcript visible even when the caption switch is off;
- increases line spacing and emphasis in the current teaching text;
- reduces decorative tint behind the teaching text and strengthens the focus border.

This is a reading preference only and is not presented as a medical treatment.

## Windows safety boundary

Step 11 does **not** restore the Windows `flutter_tts` plugin or Windows Flutter semantics.

Windows keeps:

- BGM/SFX through `WindowsMciAudioBackend`;
- narration through the crash-isolated `WindowsSpeechBackend` child PowerShell process using `System.Speech`;
- Flutter semantics excluded by default unless the existing `BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY` flag is explicitly enabled for native soak testing;
- the active-page-only app shell with no `IndexedStack`.

Android continues using the local Android-only `flutter_tts` fork and normal Flutter semantics.

## Verification targets

Run:

```powershell
dart format lib test
flutter analyze
flutter test test/learning_audio_accessibility_test.dart
flutter test test/audio_experience_test.dart
flutter test test/phase_d_accessibility_polish_test.dart
flutter test test/game_session_resume_safety_test.dart
flutter test
```

Real-device release qualification still requires Android TalkBack/keyboard checks and the documented Windows Narrator + resize/minimise/sleep-resume canary soak before any Windows semantics restoration.
