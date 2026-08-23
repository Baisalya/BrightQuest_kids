import '../learning/contextual_feedback_models.dart';
import '../learning/mission_session_models.dart';
import '../rewards/adventure_reward_models.dart';
import 'game_feel_models.dart';

/// Central presentation policy for BrightQuest's moment-to-moment game feel.
///
/// This deliberately reads already-authoritative learning/reward state and
/// converts it into mascot + motion cues. It never evaluates answers, grants
/// rewards, changes mastery evidence, or mutates progress.
class GameFeelDirector {
  const GameFeelDirector._();

  static BrightGameFeelMoment forFeedback(ContextualAttemptFeedback feedback) {
    if (feedback.correct) {
      return const BrightGameFeelMoment(
        kind: BrightMomentKind.success,
        mood: BrightMascotMood.celebrating,
        emoji: '🌟',
        semanticLabel: 'Leo celebrates the correct mission move',
      );
    }

    return switch (feedback.stage) {
      ContextualFeedbackStage.nudge => const BrightGameFeelMoment(
          kind: BrightMomentKind.retry,
          mood: BrightMascotMood.thinking,
          emoji: '🧩',
          semanticLabel: 'Leo pauses to think about the next move',
        ),
      ContextualFeedbackStage.strategy => const BrightGameFeelMoment(
          kind: BrightMomentKind.focus,
          mood: BrightMascotMood.focused,
          emoji: '🔎',
          semanticLabel: 'Leo focuses on the mission strategy',
        ),
      ContextualFeedbackStage.powerUp => const BrightGameFeelMoment(
          kind: BrightMomentKind.powerUp,
          mood: BrightMascotMood.encouraging,
          emoji: '⚡',
          semanticLabel: 'Leo offers a learning power-up',
        ),
      ContextualFeedbackStage.success => const BrightGameFeelMoment(
          kind: BrightMomentKind.success,
          mood: BrightMascotMood.celebrating,
          emoji: '🌟',
          semanticLabel: 'Leo celebrates the correct mission move',
        ),
    };
  }

  static BrightGameFeelMoment forReward(AdventureRewardMoment reward) =>
      switch (reward.tier) {
        AdventureRewardTier.retry => const BrightGameFeelMoment(
            kind: BrightMomentKind.retry,
            mood: BrightMascotMood.encouraging,
            emoji: '💪',
            semanticLabel: 'Leo encourages another mission attempt',
          ),
        AdventureRewardTier.clear => const BrightGameFeelMoment(
            kind: BrightMomentKind.success,
            mood: BrightMascotMood.cheerful,
            emoji: '✨',
            semanticLabel: 'Leo cheers the completed replay',
          ),
        AdventureRewardTier.starUpgrade => const BrightGameFeelMoment(
            kind: BrightMomentKind.unlock,
            mood: BrightMascotMood.celebrating,
            emoji: '⭐',
            semanticLabel: 'Leo celebrates a new star record',
          ),
        AdventureRewardTier.firstClear => const BrightGameFeelMoment(
            kind: BrightMomentKind.unlock,
            mood: BrightMascotMood.celebrating,
            emoji: '🚩',
            semanticLabel: 'Leo celebrates the first mission clear',
          ),
        AdventureRewardTier.bossClear => const BrightGameFeelMoment(
            kind: BrightMomentKind.bossClear,
            mood: BrightMascotMood.heroic,
            emoji: '👑',
            semanticLabel: 'Leo celebrates the cleared boss encounter',
          ),
        AdventureRewardTier.worldComplete => const BrightGameFeelMoment(
            kind: BrightMomentKind.worldClear,
            mood: BrightMascotMood.heroic,
            emoji: '🏆',
            semanticLabel: 'Leo celebrates the completed learning world',
          ),
      };

  static BrightGameFeelMoment forSessionPhase(MissionSessionPhase phase) =>
      switch (phase) {
        MissionSessionPhase.seeIt => const BrightGameFeelMoment(
            kind: BrightMomentKind.focus,
            mood: BrightMascotMood.focused,
            emoji: '👀',
            semanticLabel: 'Leo focuses on the mission idea',
          ),
        MissionSessionPhase.tryWithHelp => const BrightGameFeelMoment(
            kind: BrightMomentKind.hint,
            mood: BrightMascotMood.encouraging,
            emoji: '🦁',
            semanticLabel: 'Leo coaches the guided mission move',
          ),
        MissionSessionPhase.tryYourself => const BrightGameFeelMoment(
            kind: BrightMomentKind.focus,
            mood: BrightMascotMood.focused,
            emoji: '🎯',
            semanticLabel: 'Leo watches the independent mission attempt',
          ),
        MissionSessionPhase.applyInGame => const BrightGameFeelMoment(
            kind: BrightMomentKind.calm,
            mood: BrightMascotMood.cheerful,
            emoji: '🎮',
            semanticLabel: 'Leo is ready for the applied game mission',
          ),
      };
}
