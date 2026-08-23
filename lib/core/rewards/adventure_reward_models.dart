import '../curriculum/world_mission_models.dart';

enum AdventureRewardTier {
  retry,
  clear,
  starUpgrade,
  firstClear,
  bossClear,
  worldComplete,
}

/// Presentation-only summary of one completed BrightQuest mission.
///
/// Reward amounts and unlock decisions are supplied by the existing
/// [GameController] through MissionReward. This model never grants or mutates
/// rewards itself.
class AdventureRewardMoment {
  const AdventureRewardMoment({
    required this.tier,
    required this.cleared,
    required this.firstClear,
    required this.bossClear,
    required this.zoneComplete,
    required this.worldComplete,
    required this.score,
    required this.maxScore,
    required this.levelStars,
    required this.levelStarsAwarded,
    required this.coinsAwarded,
    required this.xpAwarded,
    required this.headline,
    required this.message,
    required this.missionPlan,
    this.nextMissionPlan,
  });

  final AdventureRewardTier tier;
  final bool cleared;
  final bool firstClear;
  final bool bossClear;
  final bool zoneComplete;
  final bool worldComplete;
  final int score;
  final int maxScore;
  final int levelStars;
  final int levelStarsAwarded;
  final int coinsAwarded;
  final int xpAwarded;
  final String headline;
  final String message;
  final WorldMissionPlan missionPlan;
  final WorldMissionPlan? nextMissionPlan;

  double get scoreRatio => maxScore <= 0 ? 0 : score / maxScore;
  bool get unlockedSomething => nextMissionPlan != null;
}

class AdventureZoneProgress {
  const AdventureZoneProgress({
    required this.completedMissions,
    required this.totalMissions,
    required this.earnedStars,
    required this.maxStars,
  });

  final int completedMissions;
  final int totalMissions;
  final int earnedStars;
  final int maxStars;

  bool get complete => totalMissions > 0 && completedMissions == totalMissions;
  double get completionRatio =>
      totalMissions <= 0 ? 0 : completedMissions / totalMissions;
  double get starRatio => maxStars <= 0 ? 0 : earnedStars / maxStars;
}

class AdventureWorldProgress {
  const AdventureWorldProgress({
    required this.completedMissions,
    required this.totalMissions,
    required this.earnedStars,
    required this.maxStars,
    required this.completedZones,
    required this.totalZones,
  });

  final int completedMissions;
  final int totalMissions;
  final int earnedStars;
  final int maxStars;
  final int completedZones;
  final int totalZones;

  bool get complete => totalMissions > 0 && completedMissions == totalMissions;
  double get completionRatio =>
      totalMissions <= 0 ? 0 : completedMissions / totalMissions;
}
