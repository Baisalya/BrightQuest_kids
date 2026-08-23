import '../curriculum/curriculum_models.dart';
import '../models/progress_models.dart';
import 'adaptive_difficulty_models.dart';

/// Builds a read-only support/session policy from existing progress.
///
/// Important boundary: LearningLevel.difficulty and LearningLevel.passRatio stay
/// authoritative. This engine adapts scaffolding, not curriculum correctness or
/// progression requirements.
class AdaptiveDifficultyEngine {
  const AdaptiveDifficultyEngine();

  AdaptiveMissionPolicy forLevel({
    required LearningLevel level,
    required LearningLevelProgress levelProgress,
    required GameProgress gameProgress,
  }) {
    final readiness = _readinessFor(
      level: level,
      levelProgress: levelProgress,
      gameProgress: gameProgress,
    );

    return switch (level.type) {
      LearningLevelType.practice => _practice(level, readiness),
      LearningLevelType.challenge => _challenge(level, readiness),
      LearningLevelType.mastery => _mastery(level, readiness),
    };
  }

  AdaptiveReadinessBand _readinessFor({
    required LearningLevel level,
    required LearningLevelProgress levelProgress,
    required GameProgress gameProgress,
  }) {
    final failedThisLevel = levelProgress.attempts > 0 &&
        !levelProgress.completed &&
        levelProgress.bestRatio < level.passRatio;
    final establishedStruggle = gameProgress.attempts >= 4 &&
        (gameProgress.accuracy < 0.58 || gameProgress.mastery < 0.28);
    if (failedThisLevel || establishedStruggle) {
      return AdaptiveReadinessBand.needsSupport;
    }

    final strongLevelReplay = levelProgress.bestRatio >= 0.90;
    final establishedStrength = gameProgress.attempts >= 4 &&
        gameProgress.mastery >= 0.65 &&
        gameProgress.accuracy >= 0.78;
    if (strongLevelReplay || establishedStrength) {
      return AdaptiveReadinessBand.stretchReady;
    }

    return AdaptiveReadinessBand.onTrack;
  }

  AdaptiveMissionPolicy _practice(
    LearningLevel level,
    AdaptiveReadinessBand readiness,
  ) {
    if (readiness == AdaptiveReadinessBand.needsSupport) {
      return AdaptiveMissionPolicy(
        levelType: level.type,
        readiness: readiness,
        posture: AdaptiveMissionPosture.scaffoldedPractice,
        targetDifficulty: level.difficulty,
        includeExplanation: true,
        includeWorkedExample: true,
        includeGuidedTry: true,
        includeIndependentPractice: true,
        includeTransfer: true,
        includeExitTicket: true,
        guidedIsCoached: true,
        allowPreAttemptHints: true,
        hintsEnabled: true,
        hintUnlockAfterMisses: 0,
        rescueEnabled: true,
        rescueUnlockAfterMisses: 1,
        allowsMainGameHints: true,
      );
    }

    if (readiness == AdaptiveReadinessBand.stretchReady) {
      return AdaptiveMissionPolicy(
        levelType: level.type,
        readiness: readiness,
        posture: AdaptiveMissionPosture.lightPractice,
        targetDifficulty: level.difficulty,
        includeExplanation: false,
        includeWorkedExample: true,
        includeGuidedTry: true,
        includeIndependentPractice: true,
        includeTransfer: true,
        includeExitTicket: true,
        guidedIsCoached: true,
        allowPreAttemptHints: false,
        hintsEnabled: true,
        hintUnlockAfterMisses: 1,
        rescueEnabled: true,
        rescueUnlockAfterMisses: 2,
        allowsMainGameHints: true,
      );
    }

    return AdaptiveMissionPolicy(
      levelType: level.type,
      readiness: readiness,
      posture: AdaptiveMissionPosture.guidedPractice,
      targetDifficulty: level.difficulty,
      includeExplanation: true,
      includeWorkedExample: true,
      includeGuidedTry: true,
      includeIndependentPractice: true,
      includeTransfer: true,
      includeExitTicket: true,
      guidedIsCoached: true,
      allowPreAttemptHints: true,
      hintsEnabled: true,
      hintUnlockAfterMisses: 0,
      rescueEnabled: true,
      rescueUnlockAfterMisses: 2,
      allowsMainGameHints: true,
    );
  }

  AdaptiveMissionPolicy _challenge(
    LearningLevel level,
    AdaptiveReadinessBand readiness,
  ) {
    if (readiness == AdaptiveReadinessBand.needsSupport) {
      return AdaptiveMissionPolicy(
        levelType: level.type,
        readiness: readiness,
        posture: AdaptiveMissionPosture.supportedChallenge,
        targetDifficulty: level.difficulty,
        includeExplanation: true,
        includeWorkedExample: true,
        includeGuidedTry: true,
        includeIndependentPractice: false,
        includeTransfer: false,
        includeExitTicket: true,
        guidedIsCoached: true,
        allowPreAttemptHints: true,
        hintsEnabled: true,
        hintUnlockAfterMisses: 0,
        rescueEnabled: true,
        rescueUnlockAfterMisses: 1,
        allowsMainGameHints: false,
      );
    }

    if (readiness == AdaptiveReadinessBand.stretchReady) {
      return AdaptiveMissionPolicy(
        levelType: level.type,
        readiness: readiness,
        posture: AdaptiveMissionPosture.stretchChallenge,
        targetDifficulty: level.difficulty,
        includeExplanation: false,
        includeWorkedExample: false,
        includeGuidedTry: true,
        includeIndependentPractice: false,
        includeTransfer: false,
        includeExitTicket: true,
        guidedIsCoached: false,
        allowPreAttemptHints: false,
        hintsEnabled: true,
        hintUnlockAfterMisses: 2,
        rescueEnabled: true,
        rescueUnlockAfterMisses: 3,
        allowsMainGameHints: false,
      );
    }

    return AdaptiveMissionPolicy(
      levelType: level.type,
      readiness: readiness,
      posture: AdaptiveMissionPosture.independentChallenge,
      targetDifficulty: level.difficulty,
      includeExplanation: false,
      includeWorkedExample: true,
      includeGuidedTry: true,
      includeIndependentPractice: false,
      includeTransfer: false,
      includeExitTicket: true,
      guidedIsCoached: false,
      allowPreAttemptHints: false,
      hintsEnabled: true,
      hintUnlockAfterMisses: 1,
      rescueEnabled: true,
      rescueUnlockAfterMisses: 2,
      allowsMainGameHints: false,
    );
  }

  AdaptiveMissionPolicy _mastery(
    LearningLevel level,
    AdaptiveReadinessBand readiness,
  ) =>
      AdaptiveMissionPolicy(
        levelType: level.type,
        readiness: readiness,
        posture: AdaptiveMissionPosture.masteryProof,
        targetDifficulty: level.difficulty,
        includeExplanation: false,
        includeWorkedExample: false,
        includeGuidedTry: false,
        includeIndependentPractice: false,
        includeTransfer: false,
        includeExitTicket: true,
        guidedIsCoached: false,
        allowPreAttemptHints: false,
        hintsEnabled: false,
        hintUnlockAfterMisses: 999,
        rescueEnabled: false,
        rescueUnlockAfterMisses: 999,
        allowsMainGameHints: false,
      );
}
