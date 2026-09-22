import 'dart:async';

import '../../core/services/bright_audio_service.dart';

/// Short, gentle interaction cues reserved for Nursery surfaces.
///
/// Nursery deliberately does not reuse the sharper game packs: these helpers
/// keep toy-like option/action/transition sounds consistent across choice,
/// matching, sorting, tracing and lesson navigation.
void playNurseryTapSound() {
  unawaited(
    BrightAudioService.instance.playNurserySfx(BrightInteractionSfx.tap),
  );
}

void playNurseryOptionSound() {
  unawaited(
    BrightAudioService.instance.playNurserySfx(BrightInteractionSfx.option),
  );
}

void playNurseryActionSound() {
  unawaited(
    BrightAudioService.instance.playNurserySfx(BrightInteractionSfx.action),
  );
}

void playNurseryNextSound() {
  unawaited(
    BrightAudioService.instance.playNurserySfx(BrightInteractionSfx.next),
  );
}

void playNurseryStartSound() {
  unawaited(
    BrightAudioService.instance.playNurserySfx(BrightInteractionSfx.start),
  );
}
