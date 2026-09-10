import '../curriculum/curriculum_models.dart';
import '../models/progress_models.dart';
import 'adaptive_difficulty_engine.dart';
import 'adaptive_difficulty_models.dart';
import 'learning_models.dart';
import 'mission_variety_models.dart';

/// Converts existing BrightQuest learning evidence into deterministic mission
/// composition preferences.
///
/// It never changes answer rules, pass ratios or [LearningLevel.difficulty].
/// The output only ranks already-valid exact-tier candidates in Training and
/// the independent real game.
class MissionVarietyIntelligence {
  const MissionVarietyIntelligence();

  AdaptiveMissionSelectionProfile forLevel({
    required LearningLevel level,
    required LearningLevelProgress levelProgress,
    required GameProgress gameProgress,
    required LearningProfileState learningState,
    required Set<String> candidateCompetencyIds,
    DateTime? now,
  }) {
    if (candidateCompetencyIds.isEmpty) {
      return AdaptiveMissionSelectionProfile.neutral;
    }

    final timestamp = now ?? DateTime.now();
    final adaptive = const AdaptiveDifficultyEngine().forLevel(
      level: level,
      levelProgress: levelProgress,
      gameProgress: gameProgress,
    );
    final relevantEvidence = learningState.attemptEvidence
        .where(
          (item) =>
              item.classNumber == level.classNumber &&
              item.sourceGameId == level.gameId &&
              candidateCompetencyIds.contains(item.competencyId),
        )
        .toList(growable: false)
      ..sort((a, b) => _timeOf(b).compareTo(_timeOf(a)));

    final dueReview = <String>{
      for (final task in learningState.reviewTasks)
        if (task.classNumber == level.classNumber &&
            !task.completed &&
            candidateCompetencyIds.contains(task.competencyId) &&
            _isDue(task, timestamp))
          task.competencyId,
    };

    final cooldownDepth = switch (level.classNumber) {
      3 => 3,
      4 => 2,
      5 => 2,
      _ => 2,
    };
    final cooldown = <String>{};
    for (final evidence in relevantEvidence.take(cooldownDepth)) {
      if (!evidence.correct && !dueReview.contains(evidence.competencyId)) {
        cooldown.add(evidence.competencyId);
      }
    }

    final training = <String, int>{};
    final game = <String, int>{};
    var weakCount = 0;
    var strongCount = 0;

    for (final competencyId in candidateCompetencyIds) {
      final mastery = learningState.skillMastery[competencyId];
      final due = dueReview.contains(competencyId);
      final coolingDown = cooldown.contains(competencyId);
      final weak = _isWeak(mastery);
      final strong = _isStrong(mastery);
      if (weak) weakCount += 1;
      if (strong) strongCount += 1;

      var trainingPriority = _baseTrainingPriority(
        level: level,
        mastery: mastery,
        dueReview: due,
        weak: weak,
        strong: strong,
      );
      var gamePriority = _baseGamePriority(
        level: level,
        adaptive: adaptive,
        mastery: mastery,
        dueReview: due,
        weak: weak,
        strong: strong,
      );

      if (coolingDown) {
        // Exact activity repetition is already blocked by MissionExposureHistory.
        // This extra competency cooldown spaces the *concept* when another
        // competency can be selected instead.
        trainingPriority -= 90;
        gamePriority -= 110;
      }

      training[competencyId] = trainingPriority;
      game[competencyId] = gamePriority;
    }

    final demand = dueReview.isNotEmpty
        ? AdaptiveMissionDemandBand.spacedReview
        : weakCount > 0 ||
                adaptive.readiness == AdaptiveReadinessBand.needsSupport
            ? AdaptiveMissionDemandBand.reinforce
            : adaptive.readiness == AdaptiveReadinessBand.stretchReady ||
                    strongCount == candidateCompetencyIds.length
                ? AdaptiveMissionDemandBand.stretch
                : AdaptiveMissionDemandBand.balanced;

    final authoredTrainingBonus = switch (demand) {
      AdaptiveMissionDemandBand.reinforce => switch (level.classNumber) {
          3 => 28,
          4 => 24,
          5 => 20,
          _ => 22,
        },
      AdaptiveMissionDemandBand.spacedReview => 22,
      AdaptiveMissionDemandBand.balanced => 18,
      AdaptiveMissionDemandBand.stretch => 10,
    };
    final generatedGameBonus = demand == AdaptiveMissionDemandBand.stretch
        ? switch (level.classNumber) {
            3 => 6,
            4 => 10,
            5 => 14,
            _ => 8,
          }
        : 0;
    final mixedSkillGameBonus = demand == AdaptiveMissionDemandBand.stretch &&
            candidateCompetencyIds.length >= 2 &&
            strongCount >= 2
        ? switch (level.classNumber) {
            3 => 8,
            4 => 14,
            5 => 20,
            _ => 10,
          }
        : 0;

    return AdaptiveMissionSelectionProfile(
      demand: demand,
      trainingCompetencyPriorities: Map<String, int>.unmodifiable(training),
      gameCompetencyPriorities: Map<String, int>.unmodifiable(game),
      cooldownCompetencyIds: Set<String>.unmodifiable(cooldown),
      reviewDueCompetencyIds: Set<String>.unmodifiable(dueReview),
      authoredTrainingBonus: authoredTrainingBonus,
      generatedGameBonus: generatedGameBonus,
      mixedSkillGameBonus: mixedSkillGameBonus,
      reason: _reasonFor(
        demand: demand,
        dueCount: dueReview.length,
        weakCount: weakCount,
        cooldownCount: cooldown.length,
        classNumber: level.classNumber,
      ),
    );
  }

  int _baseTrainingPriority({
    required LearningLevel level,
    required SkillMastery? mastery,
    required bool dueReview,
    required bool weak,
    required bool strong,
  }) {
    if (dueReview) return 120;
    if (weak) {
      return switch (level.classNumber) {
        3 => 82,
        4 => 72,
        5 => 62,
        _ => 70,
      };
    }
    if (mastery == null || mastery.state == LearningEvidenceState.notStarted) {
      return 32;
    }
    if (mastery.state == LearningEvidenceState.introduced ||
        mastery.state == LearningEvidenceState.practising) {
      return 44;
    }
    if (strong) return 8;
    return 24;
  }

  int _baseGamePriority({
    required LearningLevel level,
    required AdaptiveMissionPolicy adaptive,
    required SkillMastery? mastery,
    required bool dueReview,
    required bool weak,
    required bool strong,
  }) {
    if (dueReview) return level.isMastery ? 48 : 70;
    if (weak) {
      // Practice can re-check a weak concept sooner; Challenge/Mastery avoid
      // overloading the independent proof surface while Training supports it.
      return switch (level.type) {
        LearningLevelType.practice => 48,
        LearningLevelType.challenge => 30,
        LearningLevelType.mastery => 22,
      };
    }
    if (strong) {
      final classStretch = switch (level.classNumber) {
        3 => 28,
        4 => 36,
        5 => 44,
        _ => 32,
      };
      return adaptive.readiness == AdaptiveReadinessBand.stretchReady
          ? classStretch + 16
          : classStretch;
    }
    if (mastery == null || mastery.state == LearningEvidenceState.notStarted) {
      return 20;
    }
    return 32;
  }

  bool _isWeak(SkillMastery? mastery) {
    if (mastery == null) return false;
    if (mastery.state == LearningEvidenceState.needsSupport ||
        mastery.state == LearningEvidenceState.reviewDue) {
      return true;
    }
    return mastery.evidenceCount >= 2 && mastery.accuracy < 0.60;
  }

  bool _isStrong(SkillMastery? mastery) {
    if (mastery == null) return false;
    if (mastery.state == LearningEvidenceState.secure ||
        mastery.state == LearningEvidenceState.masteredNow) {
      return true;
    }
    return mastery.evidenceCount >= 3 &&
        mastery.accuracy >= 0.80 &&
        mastery.confidence >= 0.65;
  }

  bool _isDue(ReviewTask task, DateTime now) {
    final due = task.dueAt;
    return due != null && !due.isAfter(now);
  }

  DateTime _timeOf(AttemptEvidence evidence) =>
      DateTime.tryParse(evidence.recordedAtIso)?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  String _reasonFor({
    required AdaptiveMissionDemandBand demand,
    required int dueCount,
    required int weakCount,
    required int cooldownCount,
    required int classNumber,
  }) =>
      switch (demand) {
        AdaptiveMissionDemandBand.spacedReview =>
          '$dueCount due skill${dueCount == 1 ? '' : 's'} are returning through spaced review while recent exact missions stay suppressed.',
        AdaptiveMissionDemandBand.reinforce =>
          'Class $classNumber Training favours $weakCount developing skill${weakCount == 1 ? '' : 's'}; $cooldownCount very recent miss${cooldownCount == 1 ? '' : 'es'} are spaced before repeating.',
        AdaptiveMissionDemandBand.stretch =>
          'Strong evidence shifts the independent run toward fresh variants and reviewed linked-skill activities while staying on the same curriculum tier.',
        AdaptiveMissionDemandBand.balanced =>
          'The run balances competencies, mission families and recent exposure on the current curriculum tier.',
      };
}
