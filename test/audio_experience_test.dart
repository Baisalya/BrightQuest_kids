import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/models/game_models.dart';
import 'package:brightquest_kids/core/services/bright_audio_service.dart';
import 'package:brightquest_kids/core/services/windows_speech_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every adventure has bundled BGM and a guide intro', () {
    for (final game in games) {
      expect(
        BrightAudioService.gameMusicAssets.containsKey(game.id),
        isTrue,
        reason: 'Missing BGM mapping for ${game.id}',
      );
      expect(
        BrightAudioService.gameIntroLines.containsKey(game.id),
        isTrue,
        reason: 'Missing guide intro for ${game.id}',
      );
      final asset = BrightAudioService.gameMusicAssets[game.id]!;
      expect(
        File('assets/$asset').existsSync(),
        isTrue,
        reason: 'Missing bundled audio asset assets/$asset',
      );
    }
  });

  test('all declared sound effects exist on disk', () {
    expect(BrightAudioService.sfxAssets.length, BrightSfx.values.length);
    for (final effect in BrightSfx.values) {
      final asset = BrightAudioService.sfxAssets[effect];
      expect(asset, isNotNull, reason: 'Missing SFX mapping for $effect');
      expect(
        File('assets/$asset').existsSync(),
        isTrue,
        reason: 'Missing bundled SFX assets/$asset',
      );
    }
  });

  test('Windows desktop audio avoids audioplayers native event-channel backend',
      () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final service =
        File('lib/core/services/bright_audio_service.dart').readAsStringSync();
    final backend = File('lib/core/services/windows_mci_audio_backend.dart')
        .readAsStringSync();
    final shim = File('third_party/audioplayers_windows_stub/pubspec.yaml')
        .readAsStringSync();

    expect(pubspec, contains('audioplayers_windows_stub'));
    expect(service, contains('if (Platform.isWindows)'));
    expect(service, contains('await _windowsAudio.initialize()'));
    expect(backend, contains("DynamicLibrary.open('winmm.dll')"));
    expect(backend, contains('mciSendStringW'));
    expect(shim, contains('implements: audioplayers'));
  });

  test('Windows desktop excludes the crashing flutter_tts native plugin', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final androidTts =
        File('third_party/flutter_tts_android/pubspec.yaml').readAsStringSync();
    final service =
        File('lib/core/services/bright_audio_service.dart').readAsStringSync();
    final windowsRegistrant =
        File('windows/flutter/generated_plugin_registrant.cc')
            .readAsStringSync();
    final entryPoint = File('lib/main.dart').readAsStringSync();

    expect(pubspec, contains('third_party/flutter_tts_android'));
    expect(androidTts, contains('pluginClass: FlutterTtsPlugin'));
    expect(androidTts, isNot(contains('supportedVariants:')));
    expect(windowsRegistrant, isNot(contains('FlutterTtsPlugin')));
    expect(service, contains('bool get voiceAvailable => !Platform.isWindows'));
    expect(entryPoint, contains('Platform.isWindows ? ExcludeSemantics'));
  });

  test('Windows narration uses an isolated System.Speech helper', () async {
    final backend = File('lib/core/services/windows_speech_backend.dart')
        .readAsStringSync();

    expect(backend, contains('System.Speech'));
    expect(backend, contains("'-EncodedCommand'"));
    expect(backend, contains('Process.start'));
    expect(backend, contains(r'\$voice.SelectVoice(\$voiceName)'));
    expect(WindowsSpeechBackend.systemRateFor(0.30), -3);
    expect(WindowsSpeechBackend.systemRateFor(0.62), 2);

    final encoded = WindowsSpeechBackend.encodePowerShellCommand('Speak ✓');
    final bytes = base64Decode(encoded);
    final units = <int>[
      for (var index = 0; index < bytes.length; index += 2)
        bytes[index] | (bytes[index + 1] << 8),
    ];
    expect(String.fromCharCodes(units), 'Speak ✓');

    if (Platform.isWindows) {
      final speech = WindowsSpeechBackend();
      await speech.initialize();
      expect(speech.available, isTrue);
      expect(speech.voices, isNotEmpty);
      if (speech.voices.any((voice) => voice.isFemale)) {
        expect(speech.defaultVoice?.isFemale, isTrue);
      }
    }
  });

  test('voice choices identify female voices for female-first defaults', () {
    const reportedFemale = BrightVoiceOption(
      id: 'android:en-IN:guide',
      name: 'Guide',
      locale: 'en-IN',
      gender: 'Female',
    );
    const knownWindowsFemale = BrightVoiceOption(
      id: 'windows:Microsoft Zira Desktop',
      name: 'Microsoft Zira Desktop',
      locale: 'en-US',
    );
    const male = BrightVoiceOption(
      id: 'windows:Microsoft David Desktop',
      name: 'Microsoft David Desktop',
      locale: 'en-US',
      gender: 'Male',
    );

    expect(reportedFemale.isFemale, isTrue);
    expect(knownWindowsFemale.isFemale, isTrue);
    expect(male.isFemale, isFalse);
  });

  test('smart read and independent audio controls stay wired', () {
    final scaffold = File('lib/widgets/bright_widgets.dart').readAsStringSync();
    final dashboard = File('lib/features/parent/parent_dashboard_screen.dart')
        .readAsStringSync();
    final feedback =
        File('lib/core/services/bright_audio_service.dart').readAsStringSync();

    expect(scaffold, contains('speakPrompt('));
    expect(scaffold, contains('choices: voiceChoices'));
    expect(feedback, contains('You chose \${answer.trim()}'));
    expect(
        feedback, contains('The correct answer is \${correctAnswer.trim()}'));
    expect(dashboard, contains("Key('guide_voice_selector')"));
    expect(dashboard, contains('BGM music volume'));
    expect(dashboard, contains('Game sound effects volume'));
    expect(dashboard, contains('Speech narration volume'));
  });
}
