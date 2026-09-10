import '../curriculum/curriculum_models.dart';
import '../models/progress_models.dart';

class WorldEncounterProgress {
  const WorldEncounterProgress({
    required this.completedEncounters,
    required this.totalEncounters,
  });

  final int completedEncounters;
  final int totalEncounters;

  bool get complete =>
      totalEncounters > 0 && completedEncounters >= totalEncounters;
  double get completionRatio => totalEncounters <= 0
      ? 0
      : (completedEncounters / totalEncounters).clamp(0.0, 1.0).toDouble();
}

/// Presentation/recommendation policy for richer World progression.
///
/// These encounter targets deliberately do not change canonical level unlocks,
/// rewards, stars or mastery. A child never loses an already-earned unlock.
/// The World screen simply recommends fresh runs until the practice/challenge
/// set has enough varied encounters, then moves on to the mastery checkpoint.
class WorldProgressionPolicy {
  const WorldProgressionPolicy();

  int recommendedEncountersFor(LearningLevel level) => switch (level.type) {
        LearningLevelType.practice => 2,
        LearningLevelType.challenge => 2,
        LearningLevelType.mastery => 1,
      };

  int completedRecommendedEncounters({
    required LearningLevel level,
    required LearningLevelProgress progress,
  }) =>
      progress.completedRuns.clamp(0, recommendedEncountersFor(level)).toInt();

  bool hasMetRecommendation({
    required LearningLevel level,
    required LearningLevelProgress progress,
  }) =>
      progress.completedRuns >= recommendedEncountersFor(level);

  WorldEncounterProgress progressForLevels({
    required Iterable<LearningLevel> levels,
    required LearningLevelProgress Function(String levelId) progressFor,
  }) {
    var completed = 0;
    var total = 0;
    for (final level in levels) {
      final target = recommendedEncountersFor(level);
      total += target;
      completed += progressFor(level.id).completedRuns.clamp(0, target).toInt();
    }
    return WorldEncounterProgress(
      completedEncounters: completed,
      totalEncounters: total,
    );
  }
}
