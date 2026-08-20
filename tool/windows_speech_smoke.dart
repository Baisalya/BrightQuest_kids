import 'dart:io';

import 'package:brightquest_kids/core/services/windows_speech_backend.dart';

Future<void> main() async {
  if (!Platform.isWindows) {
    stderr.writeln('Windows speech smoke test only runs on Windows.');
    exitCode = 2;
    return;
  }

  final speech = WindowsSpeechBackend();
  await speech.initialize();
  if (!speech.available) {
    stderr.writeln('No compatible Windows System.Speech voice is available.');
    exitCode = 3;
    return;
  }

  final voice = speech.defaultVoice;
  stdout.writeln(
    'Installed voices: ${speech.voices.map((item) => '${item.name} (${item.gender})').join(', ')}',
  );
  stdout.writeln(
    'Speaking with female-first default: ${voice?.name ?? 'system default'}...',
  );
  await speech.speak(
    'Fantastic! You chose twelve, and that is correct. BrightQuest smart read is ready.',
    volume: 0.85,
    rate: 0.42,
    voiceName: voice?.name,
  );
  stdout.writeln('Windows narration completed successfully.');
}
