import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/brightquest_app.dart';
import 'core/content/content_repository.dart';
import 'core/entitlements/entitlement_service.dart';
import 'core/persistence/shared_preferences_progress_store.dart';
import 'core/services/bright_audio_service.dart';
import 'core/state/game_controller.dart';

const bool _windowsSemanticsCanary = bool.fromEnvironment(
  'BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final entitlementService = EntitlementService();
  final contentRepository = await ContentRepository.loadBundled(
    loadAssetString: rootBundle.loadString,
    accessPolicy: DevelopmentPackAccessPolicy.fromEnvironment(
      developmentMode: kDebugMode,
    ),
    verifiedAccessResolver: entitlementService.hasProductionAccess,
  );
  final controller = GameController(store: SharedPreferencesProgressStore());
  await controller.load();
  final app = BrightQuestApp(
    controller: controller,
    contentRepository: contentRepository,
    entitlementService: entitlementService,
  );

  // The shell now mounts only its active page, substantially reducing AXTree
  // churn. Windows semantics still fail closed by default until the canary has
  // passed Narrator + resize/sleep-resume testing on real machines.
  runApp(
    Platform.isWindows && !_windowsSemanticsCanary
        ? ExcludeSemantics(child: app)
        : app,
  );

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
