/// Adaptive composition posture for one planned Learning World run.
///
/// This does not replace curriculum difficulty. Practice/Challenge/Mastery
/// remain on their authored exact tier; the posture only changes which valid
/// competencies and fresh variants are preferred inside that tier.
enum AdaptiveMissionDemandBand {
  reinforce,
  balanced,
  spacedReview,
  stretch,
}

/// Storage-free selection preferences consumed by [MissionRunPlanner].
///
/// Priorities are deliberately simple integers so the planner stays
/// deterministic and renderer-neutral. Larger values are preferred.
class AdaptiveMissionSelectionProfile {
  const AdaptiveMissionSelectionProfile({
    this.demand = AdaptiveMissionDemandBand.balanced,
    this.trainingCompetencyPriorities = const <String, int>{},
    this.gameCompetencyPriorities = const <String, int>{},
    this.cooldownCompetencyIds = const <String>{},
    this.reviewDueCompetencyIds = const <String>{},
    this.authoredTrainingBonus = 18,
    this.generatedGameBonus = 0,
    this.mixedSkillGameBonus = 0,
    this.reason = 'Balanced mission rotation from the current level pool.',
  });

  static const neutral = AdaptiveMissionSelectionProfile();

  final AdaptiveMissionDemandBand demand;
  final Map<String, int> trainingCompetencyPriorities;
  final Map<String, int> gameCompetencyPriorities;

  /// Competencies with a very recent incorrect attempt. When alternatives
  /// exist they are temporarily de-prioritised so the same concept is not
  /// drilled again immediately. A due spaced-review task overrides cooldown.
  final Set<String> cooldownCompetencyIds;
  final Set<String> reviewDueCompetencyIds;

  /// Training normally favours reviewed authored material as a soft ranking
  /// signal, while stretch-ready children can receive more fresh deterministic
  /// variants in the independent game. Neither bonus overrides freshness.
  final int authoredTrainingBonus;
  final int generatedGameBonus;

  /// Soft preference for reviewed activities that explicitly declare linked
  /// competencies through existing relatedCompetencyIds metadata.
  /// No prerequisite relationship is inferred by this profile.
  final int mixedSkillGameBonus;
  final String reason;

  int trainingPriorityFor(String competencyId) =>
      trainingCompetencyPriorities[competencyId] ?? 0;

  int gamePriorityFor(String competencyId) =>
      gameCompetencyPriorities[competencyId] ?? 0;
}
