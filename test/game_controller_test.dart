import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/persistence/progress_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('correct answer rewards coins, XP and advances mastery', () {
    final controller = GameController();
    final initialCoins = controller.coins;

    final reward = controller.recordAnswer(
      gameId: 'math_market',
      correct: true,
      masteryGain: 0.25,
    );

    expect(controller.coins, initialCoins + 10);
    expect(controller.xp, 10);
    expect(controller.correctAnswers, 1);
    expect(controller.totalAnswers, 1);
    expect(controller.progressFor('math_market'), 0.25);
    expect(controller.statsFor('math_market').masteryStars, 1);
    expect(reward.starsAwarded, 1);
  });

  test('incorrect answer updates attempts without awarding currency', () {
    final controller = GameController();
    final initialCoins = controller.coins;

    controller.recordAnswer(gameId: 'science_lab', correct: false);

    expect(controller.coins, initialCoins);
    expect(controller.xp, 0);
    expect(controller.correctAnswers, 0);
    expect(controller.totalAnswers, 1);
    expect(controller.statsFor('science_lab').attempts, 1);
  });

  test('topic progress tracks topic accuracy and difficulty', () {
    final controller = GameController();
    controller.recordAnswer(
      gameId: 'math_market',
      topicId: 'mixed_operations',
      difficulty: 2,
      correct: true,
    );
    controller.recordAnswer(
      gameId: 'math_market',
      topicId: 'mixed_operations',
      difficulty: 2,
      correct: false,
    );

    final topic = controller.topicStatsFor('math_market', 'mixed_operations');
    expect(topic.attempts, 2);
    expect(topic.correctAnswers, 1);
    expect(topic.accuracy, 0.5);
    expect(topic.lastDifficulty, 2);
  });

  test('adaptive difficulty rises only from demonstrated mastery', () {
    final controller = GameController();
    expect(controller.recommendedDifficulty('math_market'), 1);

    for (var i = 0; i < 4; i++) {
      controller.recordAnswer(
        gameId: 'math_market',
        correct: true,
        masteryGain: 0.2,
      );
    }

    expect(controller.recommendedDifficulty('math_market'), 3);
  });

  test('spendCoins never makes balance negative', () {
    final controller = GameController();
    final original = controller.coins;

    expect(controller.spendCoins(original + 1), isFalse);
    expect(controller.coins, original);
    expect(controller.spendCoins(50), isTrue);
    expect(controller.coins, original - 50);
  });

  test('mission first-clear bonus cannot be claimed twice', () {
    final controller = GameController();
    final initialCoins = controller.coins;

    final first = controller.completeMission(
      gameId: 'math_market',
      missionId: 'math_market:c4:d1:core_run',
      score: 4,
      maxScore: 4,
    );
    final replay = controller.completeMission(
      gameId: 'math_market',
      missionId: 'math_market:c4:d1:core_run',
      score: 4,
      maxScore: 4,
    );

    expect(first.firstCompletion, isTrue);
    expect(first.coinsAwarded, 30);
    expect(first.starsAwarded, 2);
    expect(replay.firstCompletion, isFalse);
    expect(replay.coinsAwarded, 5);
    expect(replay.starsAwarded, 0);
    expect(controller.coins, initialCoins + 35);
  });

  test('failed run does not consume the first-clear bonus', () {
    final controller = GameController();

    final failed = controller.completeMission(
      gameId: 'map_quest',
      missionId: 'map_quest:c4:d1:core_run',
      score: 1,
      maxScore: 4,
    );
    final passed = controller.completeMission(
      gameId: 'map_quest',
      missionId: 'map_quest:c4:d1:core_run',
      score: 4,
      maxScore: 4,
    );

    expect(failed.firstCompletion, isFalse);
    expect(failed.coinsAwarded, 0);
    expect(passed.firstCompletion, isTrue);
    expect(passed.coinsAwarded, 30);
  });

  test('reward ownership persists through the progress store', () async {
    final store = MemoryProgressStore();
    final controller = GameController(store: store);
    await controller.load();

    expect(controller.buyReward(rewardId: 'lion_lab_coat', cost: 200), isTrue);
    await controller.flush();

    final restored = GameController(store: store);
    await restored.load();

    expect(restored.isRewardUnlocked('lion_lab_coat'), isTrue);
    expect(restored.coins, 50);
  });

  test('child profiles isolate progress and persist', () async {
    final store = MemoryProgressStore();
    final controller = GameController(store: store);
    await controller.load();
    final firstId = controller.activeProfileId;

    final secondId = controller.createProfile(
        name: 'Mira', classNumber: 5, avatarEmoji: '👧');
    expect(secondId, isNotEmpty);
    controller.recordAnswer(gameId: 'science_lab', correct: true);
    expect(controller.correctAnswers, 1);
    expect(controller.selectedClass, 5);

    expect(controller.switchProfile(firstId), isTrue);
    expect(controller.correctAnswers, 0);
    expect(controller.selectedClass, 4);

    await controller.flush();
    final restored = GameController(store: store);
    await restored.load();
    expect(restored.profiles.length, 2);
    expect(restored.activeProfileId, firstId);
    expect(restored.switchProfile(secondId), isTrue);
    expect(restored.correctAnswers, 1);
    expect(restored.activeProfileName, 'Mira');
  });

  test('legacy phase 2 snapshot migrates into first child profile', () {
    final migrated = PlayerSnapshot.fromJson(<String, Object?>{
      'schemaVersion': 2,
      'coins': 777,
      'selectedClass': 5,
      'xp': 120,
      'correctAnswers': 3,
      'totalAnswers': 4,
    });

    expect(migrated.schemaVersion, 6);
    expect(migrated.profiles.length, 1);
    expect(migrated.activeProfile.coins, 777);
    expect(migrated.activeProfile.selectedClass, 5);
    expect(migrated.activeProfile.xp, 120);
  });

  test('class selection and parent settings persist per child', () async {
    final store = MemoryProgressStore();
    final controller = GameController(store: store);
    await controller.load();

    controller.setClass(5);
    controller.setDailyMinutesGoal(45);
    controller.setDailyTimeLimitMinutes(90);
    controller.setTimeLimitEnabled(true);
    controller.setSoundEnabled(false);
    controller.setRemindersEnabled(false);
    await controller.flush();

    final restored = GameController(store: store);
    await restored.load();

    expect(restored.selectedClass, 5);
    expect(restored.dailyMinutesGoal, 45);
    expect(restored.dailyTimeLimitMinutes, 90);
    expect(restored.timeLimitEnabled, isTrue);
    expect(restored.soundEnabled, isFalse);
    expect(restored.remindersEnabled, isFalse);
  });

  test('parent PIN is a four digit local gate', () {
    final controller = GameController();
    expect(controller.setParentPin('12'), isFalse);
    expect(controller.setParentPin('abcd'), isFalse);
    expect(controller.setParentPin('4821'), isTrue);
    expect(controller.hasParentPin, isTrue);

    controller.lockParentArea();
    expect(controller.isParentSessionUnlocked, isFalse);
    expect(controller.verifyParentPin('1111'), isFalse);
    expect(controller.verifyParentPin('4821'), isTrue);
    expect(controller.isParentSessionUnlocked, isTrue);
  });

  test('daily challenge rewards can only be claimed once', () {
    final controller = GameController();
    for (var i = 0; i < 8; i++) {
      controller.recordAnswer(gameId: 'math_market', correct: i.isEven);
    }
    final challenge = controller.dailyChallenges.first;
    final before = controller.coins;

    expect(controller.isDailyChallengeReady(challenge), isTrue);
    expect(controller.claimDailyChallenge(challenge.id), isTrue);
    expect(controller.coins, before + challenge.rewardCoins);
    expect(controller.claimDailyChallenge(challenge.id), isFalse);
  });

  test('daily time limit becomes enforceable from tracked study time', () {
    final controller = GameController();
    controller.setDailyTimeLimitMinutes(15);
    controller.setTimeLimitEnabled(true);
    controller.addStudySeconds(300);
    controller.addStudySeconds(300);
    controller.addStudySeconds(300);

    expect(controller.studyMinutesToday, 15);
    expect(controller.dailyTimeLimitReached, isTrue);
  });

  test('learning path starts with practice unlocked and later stages locked',
      () {
    final controller = GameController();
    final track = levelsForGame(4, 'math_market');

    expect(track.length, 3);
    expect(controller.isLevelUnlocked(track[0]), isTrue);
    expect(controller.isLevelUnlocked(track[1]), isFalse);
    expect(controller.isLevelUnlocked(track[2]), isFalse);
  });

  test('failed learning level does not clear it or unlock next stage', () {
    final controller = GameController();
    final track = levelsForGame(4, 'math_market');

    final reward = controller.completeLearningLevel(
      level: track[0],
      score: 1,
      maxScore: 4,
    );

    expect(reward.levelCompleted, isFalse);
    expect(reward.firstCompletion, isFalse);
    expect(reward.coinsAwarded, 0);
    expect(controller.levelStatsFor(track[0].id).completed, isFalse);
    expect(controller.isLevelUnlocked(track[1]), isFalse);
    expect(controller.statsFor('math_market').completedRuns, 0);
  });

  test('clearing a learning level awards stars and unlocks next stage', () {
    final controller = GameController();
    final track = levelsForGame(4, 'math_market');
    final beforeCoins = controller.coins;

    final reward = controller.completeLearningLevel(
      level: track[0],
      score: 4,
      maxScore: 4,
    );

    expect(reward.levelCompleted, isTrue);
    expect(reward.firstCompletion, isTrue);
    expect(reward.levelStars, 3);
    expect(reward.levelStarsAwarded, 3);
    expect(reward.unlockedNextLevel, isTrue);
    expect(controller.levelStatsFor(track[0].id).earnedStars, 3);
    expect(controller.isLevelUnlocked(track[1]), isTrue);
    expect(controller.learningPathStars, 3);
    expect(controller.coins, greaterThan(beforeCoins));
    expect(controller.statsFor('math_market').completedRuns, 1);
  });

  test(
      'learning level replay cannot reclaim first-clear rewards but can improve stars',
      () {
    final controller = GameController();
    final level = levelsForGame(4, 'math_market').first;

    final first =
        controller.completeLearningLevel(level: level, score: 3, maxScore: 4);
    final replay =
        controller.completeLearningLevel(level: level, score: 4, maxScore: 4);
    final secondReplay =
        controller.completeLearningLevel(level: level, score: 4, maxScore: 4);

    expect(first.firstCompletion, isTrue);
    expect(first.levelStars, 2);
    expect(replay.firstCompletion, isFalse);
    expect(replay.levelStars, 3);
    expect(replay.levelStarsAwarded, 1);
    expect(secondReplay.firstCompletion, isFalse);
    expect(secondReplay.levelStarsAwarded, 0);
    expect(controller.levelStatsFor(level.id).earnedStars, 3);
  });

  test('learning level progress is isolated between child profiles', () {
    final controller = GameController();
    final firstId = controller.activeProfileId;
    final firstLevel = levelsForGame(4, 'science_lab').first;
    controller.completeLearningLevel(level: firstLevel, score: 4, maxScore: 4);
    expect(controller.levelStatsFor(firstLevel.id).completed, isTrue);

    controller.createProfile(name: 'Mira', classNumber: 4, avatarEmoji: '👧');
    expect(controller.levelStatsFor(firstLevel.id).completed, isFalse);

    controller.switchProfile(firstId);
    expect(controller.levelStatsFor(firstLevel.id).completed, isTrue);
  });

  test(
      'schema 3 profile snapshot migrates to schema 5 without losing profile data',
      () {
    final migrated = PlayerSnapshot.fromJson(<String, Object?>{
      'schemaVersion': 3,
      'activeProfileId': 'child_a',
      'profiles': <String, Object?>{
        'child_a': <String, Object?>{
          'id': 'child_a',
          'name': 'Aarav',
          'avatarEmoji': '🧒',
          'selectedClass': 5,
          'coins': 333,
          'xp': 88,
          'gameProgress': <String, Object?>{},
        },
      },
    });

    expect(migrated.schemaVersion, 6);
    expect(migrated.activeProfileId, 'child_a');
    expect(migrated.activeProfile.name, 'Aarav');
    expect(migrated.activeProfile.selectedClass, 5);
    expect(migrated.activeProfile.coins, 333);
    expect(migrated.activeProfile.xp, 88);
    expect(migrated.activeProfile.levelProgress, isEmpty);
  });

  test('first level and perfect level achievements unlock once', () {
    final controller = GameController();
    final level = levelsForGame(4, 'fraction_pizza').first;

    final reward =
        controller.completeLearningLevel(level: level, score: 4, maxScore: 4);
    final replay =
        controller.completeLearningLevel(level: level, score: 4, maxScore: 4);

    expect(reward.newAchievementIds, contains('first_steps'));
    expect(reward.newAchievementIds, contains('perfect_level'));
    expect(replay.newAchievementIds, isNot(contains('first_steps')));
    expect(replay.newAchievementIds, isNot(contains('perfect_level')));
  });
}
