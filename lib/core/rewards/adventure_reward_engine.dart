import '../curriculum/curriculum_catalog.dart';
import '../curriculum/curriculum_models.dart';
import '../curriculum/world_mission_catalog.dart';
import '../curriculum/world_mission_models.dart';
import '../models/progress_models.dart';
import 'adventure_reward_models.dart';

/// Builds reward/progression presentation from already-authoritative state.
///
/// This engine never changes scores, stars, coins, XP, unlocks or persistence.
/// Those remain owned by GameController and the existing curriculum catalog.
class AdventureRewardEngine {
  const AdventureRewardEngine._();

  static AdventureRewardMoment summarize({
    required LearningLevel level,
    required MissionReward? reward,
    required int score,
    required int maxScore,
  }) {
    final plan = WorldMissionCatalog.planForLevel(level);
    final levels = levelsForSubject(level.classNumber, level.subject);
    final index = levels.indexWhere((candidate) => candidate.id == level.id);
    final validLevelReward = reward?.levelId == level.id ? reward : null;
    final ratio = maxScore <= 0 ? 0.0 : score / maxScore;
    final cleared =
        validLevelReward?.levelCompleted ?? ratio >= level.passRatio;
    final firstClear = validLevelReward?.firstCompletion ?? false;
    final levelStars = validLevelReward?.levelStars ?? 0;
    final levelStarsAwarded = validLevelReward?.levelStarsAwarded ?? 0;
    final bossClear = cleared && plan.isBoss;
    final zoneComplete = bossClear;
    final worldComplete = cleared && index >= 0 && index == levels.length - 1;

    WorldMissionPlan? nextPlan;
    if (cleared &&
        firstClear &&
        validLevelReward?.unlockedNextLevel == true &&
        index >= 0 &&
        index + 1 < levels.length) {
      nextPlan = WorldMissionCatalog.planForLevel(levels[index + 1]);
    }

    final tier = !cleared
        ? AdventureRewardTier.retry
        : worldComplete
            ? AdventureRewardTier.worldComplete
            : bossClear
                ? AdventureRewardTier.bossClear
                : firstClear
                    ? AdventureRewardTier.firstClear
                    : levelStarsAwarded > 0
                        ? AdventureRewardTier.starUpgrade
                        : AdventureRewardTier.clear;

    return AdventureRewardMoment(
      tier: tier,
      cleared: cleared,
      firstClear: firstClear,
      bossClear: bossClear,
      zoneComplete: zoneComplete,
      worldComplete: worldComplete,
      score: score,
      maxScore: maxScore,
      levelStars: levelStars,
      levelStarsAwarded: levelStarsAwarded,
      coinsAwarded: reward?.coinsAwarded ?? 0,
      xpAwarded: reward?.xpAwarded ?? 0,
      headline: _headlineFor(tier, plan),
      message: _messageFor(tier, plan, nextPlan),
      missionPlan: plan,
      nextMissionPlan: nextPlan,
    );
  }

  static AdventureZoneProgress zoneProgress({
    required Iterable<LearningLevel> levels,
    required LearningLevelProgress Function(String levelId) progressFor,
  }) {
    var total = 0;
    var completed = 0;
    var stars = 0;
    for (final level in levels) {
      total += 1;
      final progress = progressFor(level.id);
      if (progress.completed) completed += 1;
      stars += progress.earnedStars.clamp(0, 3).toInt();
    }
    return AdventureZoneProgress(
      completedMissions: completed,
      totalMissions: total,
      earnedStars: stars,
      maxStars: total * 3,
    );
  }

  static AdventureWorldProgress worldProgress({
    required Iterable<LearningLevel> levels,
    required LearningLevelProgress Function(String levelId) progressFor,
  }) {
    final allLevels = levels.toList(growable: false);
    final byTopic = <String, List<LearningLevel>>{};
    for (final level in allLevels) {
      byTopic
          .putIfAbsent(level.curriculumTopicId, () => <LearningLevel>[])
          .add(level);
    }

    var completed = 0;
    var stars = 0;
    for (final level in allLevels) {
      final progress = progressFor(level.id);
      if (progress.completed) completed += 1;
      stars += progress.earnedStars.clamp(0, 3).toInt();
    }

    var completedZones = 0;
    for (final zoneLevels in byTopic.values) {
      if (zoneLevels.isNotEmpty &&
          zoneLevels.every((level) => progressFor(level.id).completed)) {
        completedZones += 1;
      }
    }

    return AdventureWorldProgress(
      completedMissions: completed,
      totalMissions: allLevels.length,
      earnedStars: stars,
      maxStars: allLevels.length * 3,
      completedZones: completedZones,
      totalZones: byTopic.length,
    );
  }

  static String _headlineFor(
    AdventureRewardTier tier,
    WorldMissionPlan plan,
  ) =>
      switch (tier) {
        AdventureRewardTier.retry => plan.isBoss
            ? 'The boss is still guarding this checkpoint!'
            : 'Quest not cleared yet',
        AdventureRewardTier.worldComplete =>
          '${plan.identity.worldTitle} conquered!',
        AdventureRewardTier.bossClear => plan.completionHeadline,
        AdventureRewardTier.firstClear => plan.completionHeadline,
        AdventureRewardTier.starUpgrade => 'New best mission score!',
        AdventureRewardTier.clear => 'Quest replay complete!',
      };

  static String _messageFor(
    AdventureRewardTier tier,
    WorldMissionPlan plan,
    WorldMissionPlan? nextPlan,
  ) =>
      switch (tier) {
        AdventureRewardTier.retry =>
          'Use what you learned, try the mission again and clear the checkpoint.',
        AdventureRewardTier.worldComplete =>
          'Every quest in this world is cleared. Replay missions to collect any missing stars.',
        AdventureRewardTier.bossClear => nextPlan == null
            ? 'Boss cleared. This zone is complete!'
            : 'Boss cleared. ${nextPlan.zoneTitle} is now ready to explore.',
        AdventureRewardTier.firstClear => nextPlan == null
            ? 'Checkpoint cleared for the first time.'
            : '${nextPlan.phaseLabel} is now ready.',
        AdventureRewardTier.starUpgrade =>
          'You improved your star record on this mission.',
        AdventureRewardTier.clear =>
          'Mission replay saved. Keep chasing a three-star clear.',
      };
}
