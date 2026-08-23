import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/rewards/adventure_reward_engine.dart';
import 'package:brightquest_kids/core/rewards/adventure_reward_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Adventure reward loop', () {
    test('first clear surfaces authoritative rewards and next mission', () {
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      const reward = MissionReward(
        firstCompletion: true,
        coinsAwarded: 30,
        xpAwarded: 45,
        starsAwarded: 2,
        levelId: 'c4_math_operations:math_market:l1',
        levelCompleted: true,
        levelStars: 2,
        levelStarsAwarded: 2,
        unlockedNextLevel: true,
      );

      final moment = AdventureRewardEngine.summarize(
        level: level,
        reward: reward,
        score: 4,
        maxScore: 5,
      );

      expect(moment.tier, AdventureRewardTier.firstClear);
      expect(moment.coinsAwarded, 30);
      expect(moment.xpAwarded, 45);
      expect(moment.levelStars, 2);
      expect(
          moment.nextMissionPlan?.levelId, 'c4_math_operations:math_market:l2');
    });

    test('mastery clear is treated as a zone completion', () {
      final level = learningLevelById('c4_math_operations:math_market:l3')!;
      const reward = MissionReward(
        firstCompletion: true,
        coinsAwarded: 50,
        xpAwarded: 65,
        starsAwarded: 3,
        levelId: 'c4_math_operations:math_market:l3',
        levelCompleted: true,
        levelStars: 3,
        levelStarsAwarded: 3,
        unlockedNextLevel: true,
      );

      final moment = AdventureRewardEngine.summarize(
        level: level,
        reward: reward,
        score: 5,
        maxScore: 5,
      );

      expect(moment.tier, AdventureRewardTier.bossClear);
      expect(moment.zoneComplete, isTrue);
      expect(moment.nextMissionPlan?.zoneTitle, 'Fraction Feast Hall');
    });

    test('last mastery clear becomes a world completion moment', () {
      final levels = levelsForSubject(
          4,
          learningLevels
              .firstWhere(
                  (level) => level.id == 'c4_math_operations:math_market:l1')
              .subject);
      final level = levels.last;
      final reward = MissionReward(
        firstCompletion: true,
        coinsAwarded: 50,
        xpAwarded: 65,
        starsAwarded: 2,
        levelId: level.id,
        levelCompleted: true,
        levelStars: 2,
        levelStarsAwarded: 2,
      );

      final moment = AdventureRewardEngine.summarize(
        level: level,
        reward: reward,
        score: 4,
        maxScore: 5,
      );

      expect(moment.tier, AdventureRewardTier.worldComplete);
      expect(moment.worldComplete, isTrue);
      expect(moment.nextMissionPlan, isNull);
    });

    test('star-upgrade replay does not pretend an old unlock is new', () {
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      const reward = MissionReward(
        firstCompletion: false,
        coinsAwarded: 10,
        xpAwarded: 15,
        starsAwarded: 1,
        levelId: 'c4_math_operations:math_market:l1',
        levelCompleted: true,
        levelStars: 3,
        levelStarsAwarded: 1,
        unlockedNextLevel: true,
      );

      final moment = AdventureRewardEngine.summarize(
        level: level,
        reward: reward,
        score: 5,
        maxScore: 5,
      );

      expect(moment.tier, AdventureRewardTier.starUpgrade);
      expect(moment.levelStarsAwarded, 1);
      expect(moment.nextMissionPlan, isNull);
    });

    test('failed run never invents rewards or an unlock', () {
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      const reward = MissionReward(
        firstCompletion: false,
        coinsAwarded: 0,
        xpAwarded: 0,
        starsAwarded: 0,
        levelId: 'c4_math_operations:math_market:l1',
        levelCompleted: false,
      );

      final moment = AdventureRewardEngine.summarize(
        level: level,
        reward: reward,
        score: 1,
        maxScore: 5,
      );

      expect(moment.tier, AdventureRewardTier.retry);
      expect(moment.cleared, isFalse);
      expect(moment.unlockedSomething, isFalse);
      expect(moment.coinsAwarded, 0);
    });

    test('zone and world progress read existing progress without mutation', () {
      final levels = levelsForSubject(
          4,
          learningLevels
              .firstWhere(
                  (level) => level.id == 'c4_math_operations:math_market:l1')
              .subject);
      final progress = <String, LearningLevelProgress>{
        for (final level in levels)
          level.id: LearningLevelProgress(
            completedRuns: level.id.endsWith(':l1') ? 1 : 0,
            earnedStars: level.id.endsWith(':l1') ? 2 : 0,
          ),
      };

      final world = AdventureRewardEngine.worldProgress(
        levels: levels,
        progressFor: (id) => progress[id]!,
      );
      final firstZone = AdventureRewardEngine.zoneProgress(
        levels: levels.take(3),
        progressFor: (id) => progress[id]!,
      );

      expect(world.totalMissions, levels.length);
      expect(world.earnedStars, 4);
      expect(firstZone.totalMissions, 3);
      expect(firstZone.completedMissions, 1);
      expect(firstZone.complete, isFalse);
    });
  });
}
