import 'package:flutter/foundation.dart';

import '../content/achievement_catalog.dart';
import '../curriculum/curriculum_catalog.dart';
import '../curriculum/curriculum_models.dart';
import '../models/game_models.dart';
import '../models/progress_models.dart';
import '../persistence/progress_store.dart';

class GameController extends ChangeNotifier {
  GameController({ProgressStore? store})
      : _store = store ?? MemoryProgressStore(),
        _snapshot = PlayerSnapshot();

  final ProgressStore _store;
  PlayerSnapshot _snapshot;
  bool _loaded = false;
  bool _parentSessionUnlocked = false;
  Future<void> _saveTail = Future<void>.value();

  ChildProfileSnapshot get _profile => _snapshot.activeProfile;

  bool get isLoaded => _loaded;
  int get coins => _profile.coins;
  int get stars => _profile.stars;
  int get streak => _profile.streak;
  int get selectedClass => _profile.selectedClass;
  int get xp => _profile.xp;
  int get correctAnswers => _profile.correctAnswers;
  int get totalAnswers => _profile.totalAnswers;
  int get dailyMinutesGoal => _profile.dailyMinutesGoal;
  int get dailyTimeLimitMinutes => _profile.dailyTimeLimitMinutes;
  bool get timeLimitEnabled => _profile.timeLimitEnabled;
  bool get soundEnabled => _profile.soundEnabled;
  bool get remindersEnabled => _profile.remindersEnabled;
  int get answersToday => _profile.answersToday;
  int get correctToday => _profile.correctToday;
  int get xpToday => _profile.xpToday;
  int get missionsToday => _profile.missionsToday;
  int get studySecondsToday => _profile.studySecondsToday;
  double get studyMinutesToday => _profile.studySecondsToday / 60;
  int get level => (xp ~/ 100) + 1;
  double get accuracy => totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;
  double get dailyAccuracy => answersToday == 0 ? 0.0 : correctToday / answersToday;
  Set<String> get unlockedRewards => Set<String>.unmodifiable(_profile.unlockedRewards);
  Set<String> get unlockedAchievementIds =>
      Set<String>.unmodifiable(_profile.unlockedAchievementIds);

  String get activeProfileId => _snapshot.activeProfileId;
  String get activeProfileName => _profile.name;
  String get activeProfileAvatar => _profile.avatarEmoji;
  List<ChildProfileSnapshot> get profiles =>
      List<ChildProfileSnapshot>.unmodifiable(_snapshot.profiles.values);

  bool get hasParentPin => (_snapshot.parentPinCode ?? '').length == 4;
  bool get isParentSessionUnlocked => _parentSessionUnlocked;
  bool get highContrastEnabled => _snapshot.highContrastEnabled;
  bool get reducedMotionEnabled => _snapshot.reducedMotionEnabled;
  bool get hapticsEnabled => _snapshot.hapticsEnabled;
  double get textScale => _snapshot.textScale;
  bool get dailyTimeLimitReached =>
      timeLimitEnabled && studySecondsToday >= dailyTimeLimitMinutes * 60;

  int get learningPathStars => levelsForClass(selectedClass).fold<int>(
        0,
        (sum, level) => sum + levelStatsFor(level.id).earnedStars,
      );

  int get completedLearningLevels => levelsForClass(selectedClass)
      .where((level) => levelStatsFor(level.id).completed)
      .length;

  int get totalLearningLevels => levelsForClass(selectedClass).length;

  double get learningPathProgress => totalLearningLevels == 0
      ? 0
      : completedLearningLevels / totalLearningLevels;

  static const List<DailyChallenge> _challenges = <DailyChallenge>[
    DailyChallenge(
      id: 'answer_8',
      title: 'Answer 8 learning questions',
      metric: DailyChallengeMetric.answers,
      target: 8,
      rewardCoins: 20,
    ),
    DailyChallenge(
      id: 'earn_60_xp',
      title: 'Earn 60 XP',
      metric: DailyChallengeMetric.xp,
      target: 60,
      rewardCoins: 25,
    ),
    DailyChallenge(
      id: 'mission_1',
      title: 'Complete 1 adventure mission',
      metric: DailyChallengeMetric.missions,
      target: 1,
      rewardCoins: 25,
    ),
    DailyChallenge(
      id: 'study_10',
      title: 'Learn for 10 minutes',
      metric: DailyChallengeMetric.studyMinutes,
      target: 10,
      rewardCoins: 30,
    ),
  ];

  List<DailyChallenge> get dailyChallenges => _challenges;

  Future<void> load() async {
    final raw = await _store.read();
    if (raw != null) {
      _snapshot = PlayerSnapshot.fromJson(raw);
    }
    _snapshot.schemaVersion = 4;
    _normalizeToday();
    _loaded = true;
    notifyListeners();
  }

  GameProgress statsFor(String gameId) =>
      _profile.gameProgress.putIfAbsent(gameId, GameProgress.new);

  TopicProgress topicStatsFor(String gameId, String topicId) => statsFor(gameId)
      .topicProgress
      .putIfAbsent(topicId, TopicProgress.new);

  LearningLevelProgress levelStatsFor(String levelId) => _profile.levelProgress
      .putIfAbsent(levelId, LearningLevelProgress.new);

  double progressFor(String gameId) => statsFor(gameId).mastery;

  bool isRewardUnlocked(String rewardId) =>
      _profile.unlockedRewards.contains(rewardId);

  bool isMissionCompleted(String missionId) =>
      _profile.completedMissionIds.contains(missionId);

  bool isAchievementUnlocked(String achievementId) =>
      _profile.unlockedAchievementIds.contains(achievementId);

  bool isDailyChallengeClaimed(String challengeId) =>
      _profile.claimedDailyChallengeIds.contains(challengeId);

  bool isLevelUnlocked(LearningLevel level) {
    if (level.classNumber != selectedClass) return false;
    final track = levelsForGame(level.classNumber, level.gameId);
    final index = track.indexWhere((candidate) => candidate.id == level.id);
    if (index < 0) return false;
    if (index == 0) return true;
    return levelStatsFor(track[index - 1].id).completed;
  }

  LearningLevel? nextLevelForSubject(SubjectWorld subject) {
    final levels = levelsForSubject(selectedClass, subject);
    for (final level in levels) {
      if (isLevelUnlocked(level) && !levelStatsFor(level.id).completed) {
        return level;
      }
    }
    return null;
  }

  LearningLevel? nextRecommendedLearningLevel() {
    final classLevels = levelsForClass(selectedClass);
    final available = classLevels
        .where((level) => isLevelUnlocked(level) && !levelStatsFor(level.id).completed)
        .toList();
    if (available.isEmpty) return null;

    available.sort((a, b) {
      final aGame = statsFor(a.gameId);
      final bGame = statsFor(b.gameId);
      final aScore = aGame.attempts == 0
          ? -1.0
          : aGame.mastery * 0.65 + aGame.accuracy * 0.35;
      final bScore = bGame.attempts == 0
          ? -1.0
          : bGame.mastery * 0.65 + bGame.accuracy * 0.35;
      final scoreOrder = aScore.compareTo(bScore);
      if (scoreOrder != 0) return scoreOrder;
      return a.order.compareTo(b.order);
    });
    return available.first;
  }

  int completedLevelsForSubject(SubjectWorld subject) =>
      levelsForSubject(selectedClass, subject)
          .where((level) => levelStatsFor(level.id).completed)
          .length;

  int totalLevelsForSubject(SubjectWorld subject) =>
      levelsForSubject(selectedClass, subject).length;

  int starsForSubject(SubjectWorld subject) =>
      levelsForSubject(selectedClass, subject).fold<int>(
        0,
        (sum, level) => sum + levelStatsFor(level.id).earnedStars,
      );

  double progressForSubject(SubjectWorld subject) {
    final total = totalLevelsForSubject(subject);
    if (total == 0) return 0;
    return completedLevelsForSubject(subject) / total;
  }

  int dailyChallengeValue(DailyChallenge challenge) => switch (challenge.metric) {
        DailyChallengeMetric.answers => answersToday,
        DailyChallengeMetric.xp => xpToday,
        DailyChallengeMetric.missions => missionsToday,
        DailyChallengeMetric.studyMinutes => studySecondsToday ~/ 60,
      };

  bool isDailyChallengeReady(DailyChallenge challenge) =>
      dailyChallengeValue(challenge) >= challenge.target;

  bool claimDailyChallenge(String challengeId) {
    _normalizeToday();
    DailyChallenge? challenge;
    for (final candidate in _challenges) {
      if (candidate.id == challengeId) {
        challenge = candidate;
        break;
      }
    }
    if (challenge == null ||
        !isDailyChallengeReady(challenge) ||
        _profile.claimedDailyChallengeIds.contains(challenge.id)) {
      return false;
    }
    _profile.claimedDailyChallengeIds.add(challenge.id);
    _profile.coins += challenge.rewardCoins;
    _changed();
    return true;
  }

  int recommendedDifficulty(String gameId) {
    final stats = statsFor(gameId);
    if (stats.attempts < 4) return 1;
    if (stats.mastery >= 0.65 && stats.accuracy >= 0.78) return 3;
    if (stats.mastery >= 0.28 && stats.accuracy >= 0.58) return 2;
    return 1;
  }

  List<String> weakestGameIds({int limit = 3}) {
    final played = _profile.gameProgress.entries
        .where((entry) => entry.value.attempts > 0)
        .toList();
    played.sort((a, b) {
      final aScore = a.value.mastery * 0.65 + a.value.accuracy * 0.35;
      final bScore = b.value.mastery * 0.65 + b.value.accuracy * 0.35;
      return aScore.compareTo(bScore);
    });
    return played
        .take(limit.clamp(0, played.length).toInt())
        .map((entry) => entry.key)
        .toList();
  }

  void setClass(int value) {
    if (value < 3 || value > 5 || value == _profile.selectedClass) return;
    _profile.selectedClass = value;
    _changed();
  }

  void setSoundEnabled(bool value) {
    if (_profile.soundEnabled == value) return;
    _profile.soundEnabled = value;
    _changed();
  }

  void setRemindersEnabled(bool value) {
    if (_profile.remindersEnabled == value) return;
    _profile.remindersEnabled = value;
    _changed();
  }

  void setDailyMinutesGoal(int value) {
    final normalized = value.clamp(10, 60).toInt();
    if (_profile.dailyMinutesGoal == normalized) return;
    _profile.dailyMinutesGoal = normalized;
    _changed();
  }

  void setDailyTimeLimitMinutes(int value) {
    final normalized = value.clamp(15, 180).toInt();
    if (_profile.dailyTimeLimitMinutes == normalized) return;
    _profile.dailyTimeLimitMinutes = normalized;
    _changed();
  }

  void setTimeLimitEnabled(bool value) {
    if (_profile.timeLimitEnabled == value) return;
    _profile.timeLimitEnabled = value;
    _changed();
  }

  void setHighContrastEnabled(bool value) {
    if (_snapshot.highContrastEnabled == value) return;
    _snapshot.highContrastEnabled = value;
    _changed();
  }

  void setReducedMotionEnabled(bool value) {
    if (_snapshot.reducedMotionEnabled == value) return;
    _snapshot.reducedMotionEnabled = value;
    _changed();
  }

  void setHapticsEnabled(bool value) {
    if (_snapshot.hapticsEnabled == value) return;
    _snapshot.hapticsEnabled = value;
    _changed();
  }

  void setTextScale(double value) {
    final normalized = value.clamp(0.9, 1.3).toDouble();
    if ((_snapshot.textScale - normalized).abs() < 0.001) return;
    _snapshot.textScale = normalized;
    _changed();
  }

  String createProfile({
    required String name,
    required int classNumber,
    String avatarEmoji = '🧒',
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final normalizedClass = classNumber.clamp(3, 5).toInt();
    final id = 'child-${DateTime.now().microsecondsSinceEpoch}';
    _snapshot.profiles[id] = ChildProfileSnapshot(
      id: id,
      name: trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed,
      avatarEmoji: avatarEmoji,
      selectedClass: normalizedClass,
    );
    _snapshot.activeProfileId = id;
    _normalizeToday();
    _changed();
    return id;
  }

  bool switchProfile(String profileId) {
    if (!_snapshot.profiles.containsKey(profileId) ||
        _snapshot.activeProfileId == profileId) {
      return false;
    }
    _snapshot.activeProfileId = profileId;
    _normalizeToday();
    _changed();
    return true;
  }

  bool renameActiveProfile(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    _profile.name = trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed;
    _changed();
    return true;
  }

  bool deleteProfile(String profileId) {
    if (_snapshot.profiles.length <= 1 ||
        !_snapshot.profiles.containsKey(profileId)) {
      return false;
    }
    _snapshot.profiles.remove(profileId);
    if (_snapshot.activeProfileId == profileId) {
      _snapshot.activeProfileId = _snapshot.profiles.keys.first;
      _normalizeToday();
    }
    _changed();
    return true;
  }

  bool setParentPin(String code) {
    if (!_isValidPin(code)) return false;
    _snapshot.parentPinCode = code;
    _parentSessionUnlocked = true;
    _changed();
    return true;
  }

  bool verifyParentPin(String code) {
    final valid = hasParentPin && code == _snapshot.parentPinCode;
    if (valid) {
      _parentSessionUnlocked = true;
      notifyListeners();
    }
    return valid;
  }

  void lockParentArea() {
    if (!_parentSessionUnlocked) return;
    _parentSessionUnlocked = false;
    notifyListeners();
  }

  bool clearParentPin(String currentCode) {
    if (!verifyParentPin(currentCode)) return false;
    _snapshot.parentPinCode = null;
    _parentSessionUnlocked = false;
    _changed();
    return true;
  }

  AnswerReward recordAnswer({
    required String gameId,
    required bool correct,
    String topicId = 'general',
    int difficulty = 1,
    double masteryGain = 0.05,
    int coinReward = 10,
    int xpReward = 10,
  }) {
    _normalizeToday();
    _touchActivity();

    final progress = statsFor(gameId);
    progress.attempts += 1;
    progress.lastPlayedIso = DateTime.now().toIso8601String();
    final topic = topicStatsFor(gameId, topicId);
    topic.attempts += 1;
    topic.lastDifficulty = difficulty.clamp(1, 3).toInt();
    _profile.totalAnswers += 1;
    _profile.answersToday += 1;

    var coinsAwarded = 0;
    var xpAwarded = 0;
    var starsAwarded = 0;

    if (correct) {
      progress.correctAnswers += 1;
      topic.correctAnswers += 1;
      _profile.correctAnswers += 1;
      _profile.correctToday += 1;
      coinsAwarded = coinReward < 0 ? 0 : coinReward;
      xpAwarded = xpReward < 0 ? 0 : xpReward;
      _profile.coins += coinsAwarded;
      _profile.xp += xpAwarded;
      _profile.xpToday += xpAwarded;

      final oldStars = progress.masteryStars;
      final safeMasteryGain = masteryGain.clamp(0.0, 1.0).toDouble();
      progress.mastery =
          (progress.mastery + safeMasteryGain).clamp(0.0, 1.0).toDouble();
      final newStars = (progress.mastery * 4).floor().clamp(0, 4).toInt();
      if (newStars > oldStars) {
        starsAwarded = newStars - oldStars;
        progress.masteryStars = newStars;
        _profile.stars += starsAwarded;
      }
    }

    final newAchievements = _evaluateAchievements();
    final achievementCoins = _achievementCoinReward(newAchievements);
    coinsAwarded += achievementCoins;
    _profile.coins += achievementCoins;

    _changed();
    return AnswerReward(
      correct: correct,
      coinsAwarded: coinsAwarded,
      xpAwarded: xpAwarded,
      starsAwarded: starsAwarded,
      newAchievementIds: newAchievements,
    );
  }

  MissionReward completeMission({
    required String gameId,
    required String missionId,
    required int score,
    required int maxScore,
  }) {
    if (maxScore <= 0) {
      return const MissionReward(
        firstCompletion: false,
        coinsAwarded: 0,
        xpAwarded: 0,
        starsAwarded: 0,
      );
    }

    _normalizeToday();
    _touchActivity();
    final progress = statsFor(gameId);
    progress.completedRuns += 1;
    final normalizedScore = score.clamp(0, maxScore).toInt();
    if (normalizedScore > progress.bestScore) progress.bestScore = normalizedScore;

    final ratio = (normalizedScore / maxScore).clamp(0.0, 1.0);
    var firstCompletion = false;
    var coinBonus = 0;
    var xpBonus = 0;
    var starBonus = 0;

    if (ratio >= 0.6) {
      _profile.missionsToday += 1;
      firstCompletion = _profile.completedMissionIds.add(missionId);
      if (firstCompletion) {
        coinBonus = 30;
        xpBonus = 40;
        starBonus = ratio >= 0.9 ? 2 : 1;
      } else {
        coinBonus = 5;
        xpBonus = 10;
      }
    }

    _profile.coins += coinBonus;
    _profile.xp += xpBonus;
    _profile.xpToday += xpBonus;
    _profile.stars += starBonus;

    final newAchievements = _evaluateAchievements();
    final achievementCoins = _achievementCoinReward(newAchievements);
    coinBonus += achievementCoins;
    _profile.coins += achievementCoins;
    _changed();

    return MissionReward(
      firstCompletion: firstCompletion,
      coinsAwarded: coinBonus,
      xpAwarded: xpBonus,
      starsAwarded: starBonus,
      newAchievementIds: newAchievements,
    );
  }

  MissionReward completeLearningLevel({
    required LearningLevel level,
    required int score,
    required int maxScore,
  }) {
    if (maxScore <= 0 ||
        level.classNumber != selectedClass ||
        !isLevelUnlocked(level)) {
      return MissionReward(
        firstCompletion: false,
        coinsAwarded: 0,
        xpAwarded: 0,
        starsAwarded: 0,
        levelId: level.id,
      );
    }

    _normalizeToday();
    _touchActivity();
    final levelProgress = levelStatsFor(level.id);
    final gameProgress = statsFor(level.gameId);
    final normalizedScore = score.clamp(0, maxScore).toInt();
    final ratio = (normalizedScore / maxScore).clamp(0.0, 1.0).toDouble();
    final wasCompleted = levelProgress.completed;

    levelProgress.attempts += 1;
    levelProgress.lastPlayedIso = DateTime.now().toIso8601String();
    if (normalizedScore > gameProgress.bestScore) {
      gameProgress.bestScore = normalizedScore;
    }
    if (ratio > levelProgress.bestRatio) {
      levelProgress.bestRatio = ratio;
      levelProgress.bestScore = normalizedScore;
      levelProgress.bestMaxScore = maxScore;
    }

    var coinBonus = 0;
    var xpBonus = 0;
    var levelStarsAwarded = 0;
    var levelStars = levelProgress.earnedStars;
    var passed = false;

    if (ratio >= level.passRatio) {
      passed = true;
      levelProgress.completedRuns += 1;
      gameProgress.completedRuns += 1;
      _profile.missionsToday += 1;

      final runStars = ratio >= 0.9
          ? 3
          : ratio >= 0.75
              ? 2
              : 1;
      if (runStars > levelProgress.earnedStars) {
        levelStarsAwarded = runStars - levelProgress.earnedStars;
        levelProgress.earnedStars = runStars;
        levelStars = runStars;
        _profile.stars += levelStarsAwarded;
      }

      if (!wasCompleted) {
        coinBonus = 20 + level.difficulty * 10 + (level.isMastery ? 20 : 0);
        xpBonus = 30 + level.difficulty * 15 + (level.isMastery ? 20 : 0);
      } else {
        coinBonus = 5 + levelStarsAwarded * 5;
        xpBonus = 10 + levelStarsAwarded * 5;
      }
    }

    _profile.coins += coinBonus;
    _profile.xp += xpBonus;
    _profile.xpToday += xpBonus;

    final next = _nextLevelInTrack(level);
    final unlockedNext = passed && next != null && isLevelUnlocked(next);
    final newAchievements = _evaluateAchievements();
    final achievementCoins = _achievementCoinReward(newAchievements);
    coinBonus += achievementCoins;
    _profile.coins += achievementCoins;
    _changed();

    return MissionReward(
      firstCompletion: passed && !wasCompleted,
      coinsAwarded: coinBonus,
      xpAwarded: xpBonus,
      starsAwarded: levelStarsAwarded,
      levelId: level.id,
      levelCompleted: passed,
      levelStars: levelStars,
      levelStarsAwarded: levelStarsAwarded,
      unlockedNextLevel: unlockedNext,
      newAchievementIds: newAchievements,
    );
  }

  MissionReward completeRun({
    required String gameId,
    required String fallbackMissionId,
    required int score,
    required int maxScore,
    LearningLevel? learningLevel,
  }) {
    if (learningLevel != null) {
      return completeLearningLevel(
        level: learningLevel,
        score: score,
        maxScore: maxScore,
      );
    }
    return completeMission(
      gameId: gameId,
      missionId: fallbackMissionId,
      score: score,
      maxScore: maxScore,
    );
  }

  bool useHint({required String gameId, int cost = 5}) {
    if (cost <= 0 || _profile.coins < cost) return false;
    _profile.coins -= cost;
    statsFor(gameId).hintsUsed += 1;
    _changed();
    return true;
  }

  bool spendCoins(int amount) {
    if (amount <= 0 || _profile.coins < amount) return false;
    _profile.coins -= amount;
    _changed();
    return true;
  }

  bool buyReward({required String rewardId, required int cost}) {
    if (cost <= 0 || _profile.unlockedRewards.contains(rewardId)) return false;
    if (_profile.coins < cost) return false;
    _profile.coins -= cost;
    _profile.unlockedRewards.add(rewardId);
    _changed();
    return true;
  }

  void addStudySeconds(int seconds) {
    if (seconds <= 0) return;
    _normalizeToday();
    _profile.studySecondsToday += seconds.clamp(1, 300).toInt();
    _changed();
  }

  Future<void> resetProgress() async {
    final current = _profile;
    final replacement = ChildProfileSnapshot(
      id: current.id,
      name: current.name,
      avatarEmoji: current.avatarEmoji,
      selectedClass: current.selectedClass,
      dailyMinutesGoal: current.dailyMinutesGoal,
      dailyTimeLimitMinutes: current.dailyTimeLimitMinutes,
      timeLimitEnabled: current.timeLimitEnabled,
      soundEnabled: current.soundEnabled,
      remindersEnabled: current.remindersEnabled,
    );
    await _waitForPendingSaves();
    _snapshot.profiles[current.id] = replacement;
    _normalizeToday();
    await _store.write(_snapshot.toJson());
    notifyListeners();
  }

  Future<void> flush() {
    _enqueueSave(_snapshot.toJson());
    return _saveTail;
  }

  LearningLevel? _nextLevelInTrack(LearningLevel level) {
    final track = levelsForGame(level.classNumber, level.gameId);
    final index = track.indexWhere((candidate) => candidate.id == level.id);
    if (index < 0 || index >= track.length - 1) return null;
    return track[index + 1];
  }

  List<String> _evaluateAchievements() {
    final newlyUnlocked = <String>[];

    void unlockIf(String id, bool condition) {
      if (condition && _profile.unlockedAchievementIds.add(id)) {
        newlyUnlocked.add(id);
      }
    }

    final completedAny = _profile.levelProgress.values.any((value) => value.completed);
    final hasPerfect = _profile.levelProgress.values.any((value) => value.earnedStars >= 3);
    final pathStars = _profile.levelProgress.values.fold<int>(
      0,
      (sum, value) => sum + value.earnedStars,
    );

    unlockIf('first_steps', completedAny);
    unlockIf('perfect_level', hasPerfect);
    unlockIf('star_collector_10', pathStars >= 10);
    unlockIf('answer_25', _profile.correctAnswers >= 25);
    unlockIf('streak_7', _profile.streak >= 7);
    unlockIf('maths_mastery', _subjectCompleted(SubjectWorld.maths));
    unlockIf('english_mastery', _subjectCompleted(SubjectWorld.english));
    unlockIf('science_mastery', _subjectCompleted(SubjectWorld.science));
    unlockIf('eco_mastery', _subjectCompleted(SubjectWorld.evs));
    unlockIf('social_mastery', _subjectCompleted(SubjectWorld.social));
    unlockIf('coding_mastery', _subjectCompleted(SubjectWorld.coding));

    return newlyUnlocked;
  }

  bool _subjectCompleted(SubjectWorld subject) {
    final levels = levelsForSubject(selectedClass, subject);
    return levels.isNotEmpty &&
        levels.every((level) => levelStatsFor(level.id).completed);
  }

  int _achievementCoinReward(List<String> ids) {
    var total = 0;
    for (final id in ids) {
      final definition = achievementById(id);
      if (definition != null) total += definition.rewardCoins;
    }
    return total;
  }

  void _normalizeToday() {
    final today = _dateKey(DateTime.now());
    if (_profile.todayDate != today) {
      _profile.todayDate = today;
      _profile.answersToday = 0;
      _profile.correctToday = 0;
      _profile.xpToday = 0;
      _profile.missionsToday = 0;
      _profile.studySecondsToday = 0;
      _profile.claimedDailyChallengeIds.clear();
    }
  }

  void _touchActivity() {
    _normalizeToday();
    final now = DateTime.now();
    final today = _dateKey(now);
    if (_profile.lastActivityDate == today) return;

    final last = _parseDateKey(_profile.lastActivityDate);
    if (last == null) {
      _profile.streak = 1;
    } else {
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
      _profile.streak = difference == 1 ? _profile.streak + 1 : 1;
    }
    _profile.lastActivityDate = today;
  }

  bool _isValidPin(String code) =>
      code.length == 4 &&
      code.codeUnits.every((unit) => unit >= 48 && unit <= 57);

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  DateTime? _parseDateKey(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  void _changed() {
    notifyListeners();
    _enqueueSave(_snapshot.toJson());
  }

  void _enqueueSave(Map<String, Object?> snapshot) {
    _saveTail = _saveTail
        .catchError((Object _, StackTrace __) {})
        .then((_) => _store.write(snapshot));
  }

  Future<void> _waitForPendingSaves() async {
    try {
      await _saveTail;
    } catch (_) {
      // A later explicit write can still recover from an earlier storage failure.
    }
  }
}
