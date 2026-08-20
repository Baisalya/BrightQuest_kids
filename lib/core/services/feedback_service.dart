import 'dart:async';

import 'package:flutter/services.dart';

import '../models/progress_models.dart';
import '../state/game_controller.dart';
import 'bright_audio_service.dart';

class FeedbackService {
  const FeedbackService._();

  static void correct(
    GameController controller, {
    String? answer,
    String? detail,
  }) {
    if (controller.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (controller.soundEnabled) {
      final audio = BrightAudioService.instance;
      unawaited(_playCorrectAudio(audio, answer: answer, detail: detail));
    }
  }

  static void wrong(
    GameController controller, {
    String? answer,
    String? correctAnswer,
    String? guidance,
  }) {
    if (controller.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (controller.soundEnabled) {
      final audio = BrightAudioService.instance;
      unawaited(
        _playWrongAudio(
          audio,
          answer: answer,
          correctAnswer: correctAnswer,
          guidance: guidance,
        ),
      );
    }
  }

  static Future<void> _playCorrectAudio(
    BrightAudioService audio, {
    String? answer,
    String? detail,
  }) async {
    await audio.playSfx(BrightSfx.correct);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await audio.speakCorrect(answer: answer, detail: detail);
  }

  static Future<void> _playWrongAudio(
    BrightAudioService audio, {
    String? answer,
    String? correctAnswer,
    String? guidance,
  }) async {
    await audio.playSfx(BrightSfx.wrong);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    await audio.speakWrong(
      answer: answer,
      correctAnswer: correctAnswer,
      guidance: guidance,
    );
  }

  static void complete(GameController controller, {MissionReward? reward}) {
    if (controller.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (controller.soundEnabled) {
      unawaited(_playCompletionAudio(BrightAudioService.instance, reward));
    }
  }

  static Future<void> _playCompletionAudio(
    BrightAudioService audio,
    MissionReward? reward,
  ) async {
    await audio.playSfx(BrightSfx.complete);
    await audio.speakComplete(reward: reward);

    if (reward == null) return;
    if (reward.starsAwarded > 0 || reward.levelStarsAwarded > 0) {
      await audio.playSfx(BrightSfx.star);
    }
    if (reward.unlockedNextLevel) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await audio.playSfx(BrightSfx.unlock);
    }
  }

  static void tap(GameController controller) {
    if (controller.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (controller.soundEnabled) {
      unawaited(BrightAudioService.instance.playSfx(BrightSfx.tap));
    }
  }

  static void hint(GameController controller, String text) {
    if (!controller.soundEnabled) return;
    final audio = BrightAudioService.instance;
    unawaited(audio.playSfx(BrightSfx.hint));
    unawaited(audio.speak(text, manual: true));
  }
}
