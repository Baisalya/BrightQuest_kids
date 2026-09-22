import 'dart:async';

import 'package:flutter/services.dart';

import '../accessibility/learning_audio_models.dart';
import '../accessibility/learning_narration_coordinator.dart';
import '../models/progress_models.dart';
import '../state/game_controller.dart';
import 'bright_audio_service.dart';

/// Owns short learning-feedback audio turns.
///
/// Every audible feedback action receives a monotonically increasing turn id
/// plus the narration ownership guards that were current at the instant the
/// learner acted. That gives us three independent cancellation boundaries:
///
/// * a newer feedback action makes an older one stale;
/// * a lesson/nursery scope change invalidates the session guard; and
/// * route/top-level navigation invalidates the global guard.
///
/// The result is deterministic "latest learner action wins" behaviour even
/// when SFX, short pauses and TTS futures complete out of order. Pauses are
/// cancellable timers, so leaving a learning surface cannot strand a pending
/// Flutter-test timer or wake stale speech later.
class FeedbackService {
  const FeedbackService._();

  static int _feedbackSerial = 0;
  static _FeedbackTurn? _activeTurn;

  static void correct(
    GameController controller, {
    String? answer,
    String? detail,
    LearningNarrationSession? narrationSession,
    BrightSfxProfile soundProfile = BrightSfxProfile.global,
  }) {
    unawaited(
      correctAndWait(
        controller,
        answer: answer,
        detail: detail,
        narrationSession: narrationSession,
        soundProfile: soundProfile,
      ),
    );
  }

  /// Plays the same guarded correct-feedback turn as [correct], but completes
  /// only after its audible feedback has finished or been cancelled. Timed
  /// challenge games use this to advance without cutting off the feedback
  /// narration.
  static Future<void> correctAndWait(
    GameController controller, {
    String? answer,
    String? detail,
    LearningNarrationSession? narrationSession,
    Duration minimumDuration = Duration.zero,
    BrightSfxProfile soundProfile = BrightSfxProfile.global,
  }) async {
    if (controller.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (!controller.soundEnabled) return;

    final turn = _beginTurn(narrationSession);
    final startedAt = DateTime.now();
    await _runTurn(
      turn,
      () async {
        await _playCorrectAudio(
          BrightAudioService.instance,
          turn: turn,
          answer: answer,
          detail: detail,
          soundProfile: soundProfile,
        );
        final remaining = minimumDuration - DateTime.now().difference(startedAt);
        if (remaining > Duration.zero) {
          await turn.wait(remaining);
        }
      },
    );
  }

  static void wrong(
    GameController controller, {
    String? answer,
    String? correctAnswer,
    String? guidance,
    LearningNarrationSession? narrationSession,
    BrightSfxProfile soundProfile = BrightSfxProfile.global,
  }) {
    unawaited(
      wrongAndWait(
        controller,
        answer: answer,
        correctAnswer: correctAnswer,
        guidance: guidance,
        narrationSession: narrationSession,
        soundProfile: soundProfile,
      ),
    );
  }

  /// Plays guarded wrong-answer feedback and completes only after that feedback
  /// has finished or been cancelled. Timed games keep manual Next disabled until
  /// this future settles so a correction cannot spill into the next question.
  static Future<void> wrongAndWait(
    GameController controller, {
    String? answer,
    String? correctAnswer,
    String? guidance,
    LearningNarrationSession? narrationSession,
    Duration minimumDuration = Duration.zero,
    BrightSfxProfile soundProfile = BrightSfxProfile.global,
  }) async {
    if (controller.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!controller.soundEnabled) return;

    final turn = _beginTurn(narrationSession);
    final startedAt = DateTime.now();
    await _runTurn(
      turn,
      () async {
        await _playWrongAudio(
          BrightAudioService.instance,
          turn: turn,
          answer: answer,
          correctAnswer: correctAnswer,
          guidance: guidance,
          soundProfile: soundProfile,
        );
        final remaining = minimumDuration - DateTime.now().difference(startedAt);
        if (remaining > Duration.zero) {
          await turn.wait(remaining);
        }
      },
    );
  }

  static void complete(
    GameController controller, {
    MissionReward? reward,
    BrightSfxProfile soundProfile = BrightSfxProfile.global,
  }) {
    if (controller.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (!controller.soundEnabled) return;

    final turn = _beginTurn(null);
    unawaited(
      _runTurn(
        turn,
        () => _playCompletionAudio(
          BrightAudioService.instance,
          reward,
          turn: turn,
          soundProfile: soundProfile,
        ),
      ),
    );
  }

  static void tap(
    GameController controller, {
    BrightSfxProfile soundProfile = BrightSfxProfile.global,
  }) {
    if (controller.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (controller.soundEnabled) {
      unawaited(
        BrightAudioService.instance.playProfileSfx(
          soundProfile,
          BrightInteractionSfx.tap,
        ),
      );
    }
  }

  static void hint(
    GameController controller,
    String text, {
    LearningNarrationSession? narrationSession,
    LearningNarrationCue? narrationCue,
    BrightSfxProfile soundProfile = BrightSfxProfile.global,
  }) {
    if (!controller.soundEnabled) return;

    final turn = _beginTurn(narrationSession);
    unawaited(
      _runTurn(
        turn,
        () => _playHintAudio(
          BrightAudioService.instance,
          turn: turn,
          text: text,
          narrationCue: narrationCue,
          soundProfile: soundProfile,
        ),
      ),
    );
  }

  static _FeedbackTurn _beginTurn(
    LearningNarrationSession? narrationSession,
  ) {
    _activeTurn?.cancel();

    final coordinator = LearningNarrationCoordinator.instance;
    final turn = _FeedbackTurn(
      serial: ++_feedbackSerial,
      globalGuard: coordinator.captureGlobalGuard(),
      narrationSession: narrationSession,
      sessionGuard: narrationSession?.captureGuard(),
    );
    turn.attachGlobalInvalidationListener(
      coordinator.addGlobalInvalidationListener(turn.cancel),
    );
    _activeTurn = turn;
    return turn;
  }

  static Future<void> _runTurn(
    _FeedbackTurn turn,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } finally {
      turn.finish();
      if (identical(_activeTurn, turn)) {
        _activeTurn = null;
      }
    }
  }

  static bool _isTurnCurrent(_FeedbackTurn turn) {
    if (turn.isCancelled || turn.serial != _feedbackSerial) return false;
    final coordinator = LearningNarrationCoordinator.instance;
    if (!coordinator.isGlobalGuardCurrent(turn.globalGuard)) return false;
    final guard = turn.sessionGuard;
    if (guard != null && !turn.narrationSession!.isGuardCurrent(guard)) {
      return false;
    }
    return true;
  }

  /// Takes the speech channel away from a still-reading prompt before an
  /// answer/hint sound starts. This does not advance the lesson scope; the
  /// guards captured in [_beginTurn] therefore remain valid unless the UI
  /// actually moves or another feedback turn supersedes this one.
  static Future<bool> _prepareTurn(
    BrightAudioService audio,
    _FeedbackTurn turn,
  ) async {
    if (!_isTurnCurrent(turn)) return false;
    final session = turn.narrationSession;
    if (session != null) {
      await session.interruptCurrentSpeech();
    } else {
      await audio.stopVoice();
    }
    return _isTurnCurrent(turn);
  }

  static Future<void> _playCorrectAudio(
    BrightAudioService audio, {
    required _FeedbackTurn turn,
    String? answer,
    String? detail,
    required BrightSfxProfile soundProfile,
  }) async {
    if (!await _prepareTurn(audio, turn)) return;
    await audio.playProfileSfx(soundProfile, BrightInteractionSfx.correct);
    if (!await turn.wait(const Duration(milliseconds: 180))) return;
    if (!_isTurnCurrent(turn)) return;

    final session = turn.narrationSession;
    if (session != null) {
      await session.speakCorrect(answer: answer, detail: detail);
      return;
    }
    await audio.speakCorrect(answer: answer, detail: detail);
  }

  static Future<void> _playWrongAudio(
    BrightAudioService audio, {
    required _FeedbackTurn turn,
    String? answer,
    String? correctAnswer,
    String? guidance,
    required BrightSfxProfile soundProfile,
  }) async {
    if (!await _prepareTurn(audio, turn)) return;
    await audio.playProfileSfx(soundProfile, BrightInteractionSfx.wrong);
    if (!await turn.wait(const Duration(milliseconds: 160))) return;
    if (!_isTurnCurrent(turn)) return;

    final session = turn.narrationSession;
    if (session != null) {
      await session.speakWrong(
        answer: answer,
        correctAnswer: correctAnswer,
        guidance: guidance,
      );
      return;
    }
    await audio.speakWrong(
      answer: answer,
      correctAnswer: correctAnswer,
      guidance: guidance,
    );
  }

  static Future<void> _playHintAudio(
    BrightAudioService audio, {
    required _FeedbackTurn turn,
    required String text,
    LearningNarrationCue? narrationCue,
    required BrightSfxProfile soundProfile,
  }) async {
    if (!await _prepareTurn(audio, turn)) return;
    await audio.playProfileSfx(soundProfile, BrightInteractionSfx.hint);
    if (!_isTurnCurrent(turn)) return;

    final session = turn.narrationSession;
    final cue = narrationCue;
    if (session != null && cue != null) {
      await session.speakCue(cue, manual: true);
      return;
    }
    if (session != null) {
      await session.speak(text, manual: true);
      return;
    }
    await audio.speak(cue?.spokenText ?? text, manual: true);
  }

  static Future<void> _playCompletionAudio(
    BrightAudioService audio,
    MissionReward? reward, {
    required _FeedbackTurn turn,
    required BrightSfxProfile soundProfile,
  }) async {
    if (!await _prepareTurn(audio, turn)) return;
    await audio.playProfileSfx(soundProfile, BrightInteractionSfx.complete);
    if (!_isTurnCurrent(turn)) return;
    await audio.speakComplete(reward: reward);

    if (reward == null || !_isTurnCurrent(turn)) return;
    if (reward.starsAwarded > 0 || reward.levelStarsAwarded > 0) {
      await audio.playSfx(BrightSfx.star);
      if (!_isTurnCurrent(turn)) return;
    }
    if (reward.unlockedNextLevel) {
      if (!await turn.wait(const Duration(milliseconds: 180))) return;
      if (!_isTurnCurrent(turn)) return;
      await audio.playSfx(BrightSfx.unlock);
    }
  }
}

class _FeedbackTurn {
  _FeedbackTurn({
    required this.serial,
    required this.globalGuard,
    required this.narrationSession,
    required this.sessionGuard,
  });

  final int serial;
  final LearningNarrationGlobalGuard globalGuard;
  final LearningNarrationSession? narrationSession;
  final LearningNarrationGuard? sessionGuard;

  bool _cancelled = false;
  Timer? _delayTimer;
  Completer<void>? _delayCompleter;
  VoidCallback? _removeGlobalInvalidationListener;

  bool get isCancelled => _cancelled;

  void attachGlobalInvalidationListener(VoidCallback removeListener) {
    if (_cancelled) {
      removeListener();
      return;
    }
    _removeGlobalInvalidationListener = removeListener;
  }

  Future<bool> wait(Duration duration) async {
    if (_cancelled) return false;

    final completer = Completer<void>();
    _delayCompleter = completer;
    _delayTimer = Timer(duration, () {
      _delayTimer = null;
      if (identical(_delayCompleter, completer)) {
        _delayCompleter = null;
      }
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
    return !_cancelled;
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancelDelay();
    _removeGlobalInvalidationListener?.call();
    _removeGlobalInvalidationListener = null;
  }

  void finish() {
    _cancelDelay();
    _removeGlobalInvalidationListener?.call();
    _removeGlobalInvalidationListener = null;
  }

  void _cancelDelay() {
    _delayTimer?.cancel();
    _delayTimer = null;
    final completer = _delayCompleter;
    _delayCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
