import '../entitlements/entitlement_models.dart';
import '../learning/learning_models.dart';

class TopicProgress {
  TopicProgress({
    this.attempts = 0,
    this.correctAnswers = 0,
    this.lastDifficulty = 1,
  });

  int attempts;
  int correctAnswers;
  int lastDifficulty;

  double get accuracy => attempts == 0 ? 0.0 : correctAnswers / attempts;

  Map<String, Object?> toJson() => <String, Object?>{
        'attempts': attempts,
        'correctAnswers': correctAnswers,
        'lastDifficulty': lastDifficulty,
      };

  factory TopicProgress.fromJson(Map<String, Object?> json) => TopicProgress(
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
        lastDifficulty: (json['lastDifficulty'] as num?)?.toInt() ?? 1,
      );
}

class LearningLevelProgress {
  LearningLevelProgress({
    this.attempts = 0,
    this.completedRuns = 0,
    this.bestScore = 0,
    this.bestMaxScore = 0,
    this.bestRatio = 0,
    this.earnedStars = 0,
    this.lastPlayedIso,
  });

  int attempts;
  int completedRuns;
  int bestScore;
  int bestMaxScore;
  double bestRatio;
  int earnedStars;
  String? lastPlayedIso;

  bool get completed => completedRuns > 0;

  Map<String, Object?> toJson() => <String, Object?>{
        'attempts': attempts,
        'completedRuns': completedRuns,
        'bestScore': bestScore,
        'bestMaxScore': bestMaxScore,
        'bestRatio': bestRatio,
        'earnedStars': earnedStars,
        'lastPlayedIso': lastPlayedIso,
      };

  factory LearningLevelProgress.fromJson(Map<String, Object?> json) =>
      LearningLevelProgress(
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        completedRuns: (json['completedRuns'] as num?)?.toInt() ?? 0,
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
        bestMaxScore: (json['bestMaxScore'] as num?)?.toInt() ?? 0,
        bestRatio: (json['bestRatio'] as num?)?.toDouble() ?? 0,
        earnedStars: (json['earnedStars'] as num?)?.toInt() ?? 0,
        lastPlayedIso: json['lastPlayedIso'] as String?,
      );
}

class GameProgress {
  GameProgress({
    this.mastery = 0,
    this.attempts = 0,
    this.correctAnswers = 0,
    this.completedRuns = 0,
    this.bestScore = 0,
    this.masteryStars = 0,
    this.hintsUsed = 0,
    this.lastPlayedIso,
    Map<String, TopicProgress>? topicProgress,
  }) : topicProgress = topicProgress ?? <String, TopicProgress>{};

  double mastery;
  int attempts;
  int correctAnswers;
  int completedRuns;
  int bestScore;
  int masteryStars;
  int hintsUsed;
  String? lastPlayedIso;
  Map<String, TopicProgress> topicProgress;

  double get accuracy => attempts == 0 ? 0.0 : correctAnswers / attempts;

  Map<String, Object?> toJson() => <String, Object?>{
        'mastery': mastery,
        'attempts': attempts,
        'correctAnswers': correctAnswers,
        'completedRuns': completedRuns,
        'bestScore': bestScore,
        'masteryStars': masteryStars,
        'hintsUsed': hintsUsed,
        'lastPlayedIso': lastPlayedIso,
        'topicProgress': topicProgress.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
      };

  factory GameProgress.fromJson(Map<String, Object?> json) {
    final topics = <String, TopicProgress>{};
    final rawTopics = json['topicProgress'];
    if (rawTopics is Map) {
      for (final entry in rawTopics.entries) {
        if (entry.key is String && entry.value is Map) {
          topics[entry.key as String] = TopicProgress.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
        }
      }
    }

    return GameProgress(
      mastery: (json['mastery'] as num?)?.toDouble() ?? 0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      completedRuns: (json['completedRuns'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      masteryStars: (json['masteryStars'] as num?)?.toInt() ?? 0,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      lastPlayedIso: json['lastPlayedIso'] as String?,
      topicProgress: topics,
    );
  }
}

class ChildProfileSnapshot {
  ChildProfileSnapshot({
    required this.id,
    required this.name,
    this.avatarEmoji = '🧒',
    this.selectedClass = 4,
    this.coins = 250,
    this.stars = 0,
    this.streak = 0,
    this.xp = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.dailyMinutesGoal = 30,
    this.dailyTimeLimitMinutes = 60,
    this.timeLimitEnabled = false,
    this.soundEnabled = true,
    this.remindersEnabled = false,
    this.lastActivityDate,
    this.todayDate,
    this.answersToday = 0,
    this.correctToday = 0,
    this.xpToday = 0,
    this.missionsToday = 0,
    this.studySecondsToday = 0,
    Map<String, GameProgress>? gameProgress,
    Map<String, LearningLevelProgress>? levelProgress,
    Set<String>? unlockedRewards,
    Set<String>? completedMissionIds,
    Set<String>? claimedDailyChallengeIds,
    Set<String>? unlockedAchievementIds,
    LearningProfileState? learning,
  })  : learning = learning ?? const LearningProfileState(),
        gameProgress = gameProgress ?? <String, GameProgress>{},
        levelProgress = levelProgress ?? <String, LearningLevelProgress>{},
        unlockedRewards = unlockedRewards ?? <String>{},
        completedMissionIds = completedMissionIds ?? <String>{},
        claimedDailyChallengeIds = claimedDailyChallengeIds ?? <String>{},
        unlockedAchievementIds = unlockedAchievementIds ?? <String>{};

  String id;
  String name;
  String avatarEmoji;
  int selectedClass;
  int coins;
  int stars;
  int streak;
  int xp;
  int correctAnswers;
  int totalAnswers;
  int dailyMinutesGoal;
  int dailyTimeLimitMinutes;
  bool timeLimitEnabled;
  bool soundEnabled;
  bool remindersEnabled;
  String? lastActivityDate;
  String? todayDate;
  int answersToday;
  int correctToday;
  int xpToday;
  int missionsToday;
  int studySecondsToday;
  Map<String, GameProgress> gameProgress;
  Map<String, LearningLevelProgress> levelProgress;
  Set<String> unlockedRewards;
  Set<String> completedMissionIds;
  Set<String> claimedDailyChallengeIds;
  Set<String> unlockedAchievementIds;
  LearningProfileState learning;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'selectedClass': selectedClass,
        'coins': coins,
        'stars': stars,
        'streak': streak,
        'xp': xp,
        'correctAnswers': correctAnswers,
        'totalAnswers': totalAnswers,
        'dailyMinutesGoal': dailyMinutesGoal,
        'dailyTimeLimitMinutes': dailyTimeLimitMinutes,
        'timeLimitEnabled': timeLimitEnabled,
        'soundEnabled': soundEnabled,
        'remindersEnabled': remindersEnabled,
        'lastActivityDate': lastActivityDate,
        'todayDate': todayDate,
        'answersToday': answersToday,
        'correctToday': correctToday,
        'xpToday': xpToday,
        'missionsToday': missionsToday,
        'studySecondsToday': studySecondsToday,
        'gameProgress': gameProgress.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
        'levelProgress': levelProgress.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
        'unlockedRewards': unlockedRewards.toList()..sort(),
        'completedMissionIds': completedMissionIds.toList()..sort(),
        'claimedDailyChallengeIds': claimedDailyChallengeIds.toList()..sort(),
        'unlockedAchievementIds': unlockedAchievementIds.toList()..sort(),
        'learning': learning.toJson(),
      };

  factory ChildProfileSnapshot.fromJson(Map<String, Object?> json) {
    final progress = <String, GameProgress>{};
    final rawProgress = json['gameProgress'];
    if (rawProgress is Map) {
      for (final entry in rawProgress.entries) {
        if (entry.key is String && entry.value is Map) {
          progress[entry.key as String] = GameProgress.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
        }
      }
    }

    final levels = <String, LearningLevelProgress>{};
    final rawLevels = json['levelProgress'];
    if (rawLevels is Map) {
      for (final entry in rawLevels.entries) {
        if (entry.key is String && entry.value is Map) {
          levels[entry.key as String] = LearningLevelProgress.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
        }
      }
    }

    return ChildProfileSnapshot(
      id: json['id'] as String? ?? 'child-1',
      name: json['name'] as String? ?? 'Explorer',
      avatarEmoji: json['avatarEmoji'] as String? ?? '🧒',
      selectedClass: (json['selectedClass'] as num?)?.toInt() ?? 4,
      coins: (json['coins'] as num?)?.toInt() ?? 250,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalAnswers: (json['totalAnswers'] as num?)?.toInt() ?? 0,
      dailyMinutesGoal: (json['dailyMinutesGoal'] as num?)?.toInt() ?? 30,
      dailyTimeLimitMinutes:
          (json['dailyTimeLimitMinutes'] as num?)?.toInt() ?? 60,
      timeLimitEnabled: json['timeLimitEnabled'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      remindersEnabled: json['remindersEnabled'] as bool? ?? false,
      lastActivityDate: json['lastActivityDate'] as String?,
      todayDate: json['todayDate'] as String?,
      answersToday: (json['answersToday'] as num?)?.toInt() ?? 0,
      correctToday: (json['correctToday'] as num?)?.toInt() ?? 0,
      xpToday: (json['xpToday'] as num?)?.toInt() ?? 0,
      missionsToday: (json['missionsToday'] as num?)?.toInt() ?? 0,
      studySecondsToday: (json['studySecondsToday'] as num?)?.toInt() ?? 0,
      gameProgress: progress,
      levelProgress: levels,
      unlockedRewards: _stringSet(json['unlockedRewards']),
      completedMissionIds: _stringSet(json['completedMissionIds']),
      claimedDailyChallengeIds: _stringSet(json['claimedDailyChallengeIds']),
      unlockedAchievementIds: _stringSet(json['unlockedAchievementIds']),
      learning: json['learning'] is Map
          ? LearningProfileState.fromJson(
              Map<String, Object?>.from(json['learning'] as Map),
            )
          : const LearningProfileState(),
    );
  }

  factory ChildProfileSnapshot.fromLegacyJson(Map<String, Object?> json) {
    final copy = Map<String, Object?>.from(json)
      ..['id'] = 'child-1'
      ..['name'] = 'Explorer'
      ..['avatarEmoji'] = '🧒';
    return ChildProfileSnapshot.fromJson(copy);
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }
}

class PlayerSnapshot {
  PlayerSnapshot({
    this.schemaVersion = 5,
    this.activeProfileId = 'child-1',
    Map<String, ChildProfileSnapshot>? profiles,
    Map<int, ClassEntitlement>? entitlementCache,
    this.parentPinCode,
    this.highContrastEnabled = false,
    this.reducedMotionEnabled = false,
    this.hapticsEnabled = true,
    this.textScale = 1.0,
  })  : entitlementCache = entitlementCache ?? <int, ClassEntitlement>{},
        profiles = profiles ??
            <String, ChildProfileSnapshot>{
              'child-1': ChildProfileSnapshot(id: 'child-1', name: 'Explorer'),
            };

  int schemaVersion;
  String activeProfileId;
  Map<String, ChildProfileSnapshot> profiles;
  Map<int, ClassEntitlement> entitlementCache;
  String? parentPinCode;
  bool highContrastEnabled;
  bool reducedMotionEnabled;
  bool hapticsEnabled;
  double textScale;

  ChildProfileSnapshot get activeProfile {
    final direct = profiles[activeProfileId];
    if (direct != null) return direct;
    if (profiles.isEmpty) {
      final fallback = ChildProfileSnapshot(id: 'child-1', name: 'Explorer');
      profiles[fallback.id] = fallback;
      activeProfileId = fallback.id;
      return fallback;
    }
    final fallback = profiles.values.first;
    activeProfileId = fallback.id;
    return fallback;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'activeProfileId': activeProfileId,
        'profiles': profiles.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
        'entitlementCache': entitlementCache.map(
          (key, value) =>
              MapEntry<String, Object?>(key.toString(), value.toJson()),
        ),
        'parentPinCode': parentPinCode,
        'highContrastEnabled': highContrastEnabled,
        'reducedMotionEnabled': reducedMotionEnabled,
        'hapticsEnabled': hapticsEnabled,
        'textScale': textScale,
      };

  factory PlayerSnapshot.fromJson(Map<String, Object?> json) {
    final rawProfiles = json['profiles'];
    if (rawProfiles is Map) {
      final profiles = <String, ChildProfileSnapshot>{};
      for (final entry in rawProfiles.entries) {
        if (entry.key is String && entry.value is Map) {
          final profile = ChildProfileSnapshot.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
          profiles[entry.key as String] = profile;
        }
      }
      final entitlements = <int, ClassEntitlement>{};
      final rawEntitlements = json['entitlementCache'];
      if (rawEntitlements is Map) {
        for (final entry in rawEntitlements.entries) {
          final classNumber = int.tryParse(entry.key.toString());
          if (classNumber != null && entry.value is Map) {
            entitlements[classNumber] = ClassEntitlement.fromJson(
              Map<String, Object?>.from(entry.value as Map),
            );
          }
        }
      }
      final snapshot = PlayerSnapshot(
        schemaVersion: 5,
        activeProfileId: json['activeProfileId'] as String? ?? 'child-1',
        profiles: profiles,
        entitlementCache: entitlements,
        parentPinCode: json['parentPinCode'] as String?,
        highContrastEnabled: json['highContrastEnabled'] as bool? ?? false,
        reducedMotionEnabled: json['reducedMotionEnabled'] as bool? ?? false,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        textScale: ((json['textScale'] as num?)?.toDouble() ?? 1.0)
            .clamp(0.9, 1.3)
            .toDouble(),
      );
      snapshot.activeProfile;
      return snapshot;
    }

    // Phase 2 migration: the root object was the single child's snapshot.
    final legacy = ChildProfileSnapshot.fromLegacyJson(json);
    return PlayerSnapshot(
      schemaVersion: 5,
      activeProfileId: legacy.id,
      profiles: <String, ChildProfileSnapshot>{legacy.id: legacy},
    );
  }
}

class AnswerReward {
  const AnswerReward({
    required this.correct,
    required this.coinsAwarded,
    required this.xpAwarded,
    required this.starsAwarded,
    this.newAchievementIds = const <String>[],
  });

  final bool correct;
  final int coinsAwarded;
  final int xpAwarded;
  final int starsAwarded;
  final List<String> newAchievementIds;
}

class MissionReward {
  const MissionReward({
    required this.firstCompletion,
    required this.coinsAwarded,
    required this.xpAwarded,
    required this.starsAwarded,
    this.levelId,
    this.levelCompleted = false,
    this.levelStars = 0,
    this.levelStarsAwarded = 0,
    this.unlockedNextLevel = false,
    this.newAchievementIds = const <String>[],
  });

  final bool firstCompletion;
  final int coinsAwarded;
  final int xpAwarded;
  final int starsAwarded;
  final String? levelId;
  final bool levelCompleted;
  final int levelStars;
  final int levelStarsAwarded;
  final bool unlockedNextLevel;
  final List<String> newAchievementIds;
}

enum DailyChallengeMetric { answers, xp, missions, studyMinutes }

class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
    required this.rewardCoins,
  });

  final String id;
  final String title;
  final DailyChallengeMetric metric;
  final int target;
  final int rewardCoins;
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.rewardCoins = 20,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final int rewardCoins;
}
