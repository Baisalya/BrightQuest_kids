import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app/brightquest_app.dart';
import 'core/persistence/shared_preferences_progress_store.dart';
import 'core/services/bright_audio_service.dart';
import 'core/state/game_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = GameController(store: SharedPreferencesProgressStore());
  await controller.load();
  final app = BrightQuestApp(controller: controller);

  // Current Flutter Windows builds can repeatedly submit invalid incremental
  // AXTree updates for this dense, eager IndexedStack and eventually fault in
  // flutter_windows.dll. Keep Android semantics fully enabled; on Windows use
  // a stable empty Flutter subtree until the engine bridge is fixed.
  runApp(Platform.isWindows ? ExcludeSemantics(child: app) : app);

  // Let the first Windows frame and accessibility tree settle before touching
  // optional native audio/TTS backends. This also keeps app startup resilient:
  // learning UI is already alive even if a device audio service is unavailable.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeOptionalAudio(controller));
  });
}

Future<void> _initializeOptionalAudio(GameController controller) async {
  await Future<void>.delayed(const Duration(milliseconds: 350));
  final audio = BrightAudioService.instance;
  await audio.initialize();
  await audio.setSessionEnabled(controller.soundEnabled);
  if (controller.soundEnabled) {
    await audio.playMenuMusic();
  }
}
