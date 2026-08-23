import 'package:flutter/foundation.dart';

/// Child-facing play posture for an activity inside a mission session.
enum LearningGamePlayMode {
  coached,
  solo,
  transfer,
  checkpoint,
  challenge,
  mastery,
}

typedef LearningGameHintRevealCallback = void Function(
  int hintIndex,
  String text,
);

@immutable
class LearningGameGuidance {
  const LearningGameGuidance({
    required this.mode,
    this.hints = const <String>[],
    this.rescueText,
    this.onHintRevealed,
    this.allowPreAttemptHints = false,
    this.hintsEnabled = true,
    this.hintUnlockAfterMisses = 1,
    this.rescueEnabled = true,
    this.rescueUnlockAfterMisses = 2,
  });

  final LearningGamePlayMode mode;

  /// Authored hint text only. No adaptive policy may synthesize a curriculum
  /// clue or correct response.
  final List<String> hints;

  /// Authored reteach text from LessonEngine, exposed only as an optional
  /// power-up when the current policy allows it.
  final String? rescueText;

  /// Reports the exact authored clue/power-up that was actually opened so the
  /// lesson evidence layer can preserve its existing hint-level semantics.
  final LearningGameHintRevealCallback? onHintRevealed;

  /// Policy gates. These control when authored help becomes available; they do
  /// not change correctness, evidence rules or authored activity difficulty.
  final bool allowPreAttemptHints;
  final bool hintsEnabled;
  final int hintUnlockAfterMisses;
  final bool rescueEnabled;
  final int rescueUnlockAfterMisses;

  bool get allowsCoachBeforeAttempt =>
      hintsEnabled &&
      allowPreAttemptHints &&
      mode == LearningGamePlayMode.coached &&
      hints.isNotEmpty;

  bool get allowsHintsAfterMiss => hintsEnabled && hints.isNotEmpty;

  bool get allowsRescueAfterMiss =>
      rescueEnabled && rescueText != null && rescueText!.trim().isNotEmpty;

  bool canRevealHint(int completedAttempts) {
    if (!hintsEnabled || hints.isEmpty) return false;
    if (completedAttempts <= 0) return allowsCoachBeforeAttempt;
    return completedAttempts >= hintUnlockAfterMisses;
  }

  bool canRevealRescue(int completedAttempts) =>
      allowsRescueAfterMiss && completedAttempts >= rescueUnlockAfterMisses;

  String get modeLabel => switch (mode) {
        LearningGamePlayMode.coached => 'TRY WITH HELP',
        LearningGamePlayMode.solo => 'TRY YOURSELF',
        LearningGamePlayMode.transfer => 'APPLY IN GAME',
        LearningGamePlayMode.checkpoint => 'MISSION CHECKPOINT',
        LearningGamePlayMode.challenge => 'CHALLENGE RUN',
        LearningGamePlayMode.mastery => 'MASTERY PROOF',
      };

  String get modeMessage => switch (mode) {
        LearningGamePlayMode.coached =>
          'Play the mission. Ask Leo for a clue only when you need one.',
        LearningGamePlayMode.solo =>
          'No clue first — use the strategy you just discovered.',
        LearningGamePlayMode.transfer =>
          'Use the idea in a fresh situation and explain it through your move.',
        LearningGamePlayMode.checkpoint =>
          'Final check: finish this one independently to clear the mission.',
        LearningGamePlayMode.challenge =>
          'Challenge mode: solve independently. Help unlocks only after the policy allows it.',
        LearningGamePlayMode.mastery =>
          'Proof mode: no hints or rescue power-ups. Make your strongest independent move.',
      };
}
