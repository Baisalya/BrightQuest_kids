import '../curriculum/curriculum_models.dart';

/// Read-only readiness signal derived from existing progress. It is never
/// persisted, so Step 9 does not add a migration or a second source of truth.
enum AdaptiveReadinessBand {
  needsSupport,
  onTrack,
  stretchReady,
}

/// Presentation/session posture for one Learning World level.
enum AdaptiveMissionPosture {
  scaffoldedPractice,
  guidedPractice,
  lightPractice,
  supportedChallenge,
  independentChallenge,
  stretchChallenge,
  masteryProof,
}

/// Deterministic policy that changes scaffolding and session shape without
/// changing authored correctness rules, pass ratios, rewards or level order.
class AdaptiveMissionPolicy {
  const AdaptiveMissionPolicy({
    required this.levelType,
    required this.readiness,
    required this.posture,
    required this.targetDifficulty,
    required this.includeExplanation,
    required this.includeWorkedExample,
    required this.includeGuidedTry,
    required this.includeIndependentPractice,
    required this.includeTransfer,
    required this.includeExitTicket,
    required this.guidedIsCoached,
    required this.allowPreAttemptHints,
    required this.hintsEnabled,
    required this.hintUnlockAfterMisses,
    required this.rescueEnabled,
    required this.rescueUnlockAfterMisses,
    required this.allowsMainGameHints,
  });

  final LearningLevelType levelType;
  final AdaptiveReadinessBand readiness;
  final AdaptiveMissionPosture posture;

  /// The LearningLevel remains authoritative for curriculum difficulty.
  /// Adaptive support never silently raises or lowers this value.
  final int targetDifficulty;

  final bool includeExplanation;
  final bool includeWorkedExample;
  final bool includeGuidedTry;
  final bool includeIndependentPractice;
  final bool includeTransfer;
  final bool includeExitTicket;

  /// Practice can keep a true coached warm-up. Challenge warm-ups may still be
  /// present, but become an independent challenge surface when this is false.
  final bool guidedIsCoached;

  final bool allowPreAttemptHints;
  final bool hintsEnabled;
  final int hintUnlockAfterMisses;
  final bool rescueEnabled;
  final int rescueUnlockAfterMisses;

  /// Main game hints remain a Practice tool. Challenge and Mastery runs are
  /// independent even though post-attempt teaching feedback may still explain
  /// what happened after evidence has already been recorded.
  final bool allowsMainGameHints;

  bool get isMasteryProof => posture == AdaptiveMissionPosture.masteryProof;
  bool get isChallenge => levelType == LearningLevelType.challenge;
  bool get isPractice => levelType == LearningLevelType.practice;

  String get badgeLabel => switch (levelType) {
        LearningLevelType.practice => 'PRACTICE · LEVEL $targetDifficulty',
        LearningLevelType.challenge => 'CHALLENGE · LEVEL $targetDifficulty',
        LearningLevelType.mastery => 'MASTERY PROOF · LEVEL $targetDifficulty',
      };

  String get readinessLabel => switch (readiness) {
        AdaptiveReadinessBand.needsSupport => 'Support mode',
        AdaptiveReadinessBand.onTrack => 'On track',
        AdaptiveReadinessBand.stretchReady => 'Stretch ready',
      };

  String get message => switch (posture) {
        AdaptiveMissionPosture.scaffoldedPractice =>
          'Leo keeps the full teaching path and clues available while you rebuild the idea.',
        AdaptiveMissionPosture.guidedPractice =>
          'Learn it, practise with Leo, then finish independently before the main mission.',
        AdaptiveMissionPosture.lightPractice =>
          'You are showing strong readiness, so Practice keeps the key example but uses lighter scaffolding.',
        AdaptiveMissionPosture.supportedChallenge =>
          'Challenge keeps one coached warm-up, then the checkpoint becomes independent.',
        AdaptiveMissionPosture.independentChallenge =>
          'Review one example, then solve the challenge without a pre-attempt clue.',
        AdaptiveMissionPosture.stretchChallenge =>
          'The warm-up is compressed and clues unlock only after repeated misses.',
        AdaptiveMissionPosture.masteryProof =>
          'No hints or rescue power-ups. Clean first-attempt work is the strongest mastery evidence.',
      };

  String get semanticLabel => '$badgeLabel. $readinessLabel. $message';
}

/// Quick Play keeps its existing adaptive hint behavior. Learning World
/// Challenge/Mastery runs intentionally remove paid pre-attempt hints.
bool learningLevelAllowsMainGameHints(LearningLevel? level) =>
    level == null || level.type == LearningLevelType.practice;
