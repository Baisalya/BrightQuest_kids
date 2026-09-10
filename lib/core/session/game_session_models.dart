import '../models/progress_models.dart';

enum GameSessionStage { lesson, game, completing, result }

class GameSessionRewardSnapshot {
  const GameSessionRewardSnapshot({
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

  factory GameSessionRewardSnapshot.fromReward(MissionReward reward) =>
      GameSessionRewardSnapshot(
        firstCompletion: reward.firstCompletion,
        coinsAwarded: reward.coinsAwarded,
        xpAwarded: reward.xpAwarded,
        starsAwarded: reward.starsAwarded,
        levelId: reward.levelId,
        levelCompleted: reward.levelCompleted,
        levelStars: reward.levelStars,
        levelStarsAwarded: reward.levelStarsAwarded,
        unlockedNextLevel: reward.unlockedNextLevel,
        newAchievementIds: List<String>.unmodifiable(reward.newAchievementIds),
      );

  MissionReward toReward() => MissionReward(
        firstCompletion: firstCompletion,
        coinsAwarded: coinsAwarded,
        xpAwarded: xpAwarded,
        starsAwarded: starsAwarded,
        levelId: levelId,
        levelCompleted: levelCompleted,
        levelStars: levelStars,
        levelStarsAwarded: levelStarsAwarded,
        unlockedNextLevel: unlockedNextLevel,
        newAchievementIds: List<String>.unmodifiable(newAchievementIds),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'firstCompletion': firstCompletion,
        'coinsAwarded': coinsAwarded,
        'xpAwarded': xpAwarded,
        'starsAwarded': starsAwarded,
        'levelId': levelId,
        'levelCompleted': levelCompleted,
        'levelStars': levelStars,
        'levelStarsAwarded': levelStarsAwarded,
        'unlockedNextLevel': unlockedNextLevel,
        'newAchievementIds': newAchievementIds,
      };

  factory GameSessionRewardSnapshot.fromJson(Map<String, Object?> json) =>
      GameSessionRewardSnapshot(
        firstCompletion: json['firstCompletion'] as bool? ?? false,
        coinsAwarded: (json['coinsAwarded'] as num?)?.toInt() ?? 0,
        xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
        starsAwarded: (json['starsAwarded'] as num?)?.toInt() ?? 0,
        levelId: json['levelId'] as String?,
        levelCompleted: json['levelCompleted'] as bool? ?? false,
        levelStars: (json['levelStars'] as num?)?.toInt() ?? 0,
        levelStarsAwarded: (json['levelStarsAwarded'] as num?)?.toInt() ?? 0,
        unlockedNextLevel: json['unlockedNextLevel'] as bool? ?? false,
        newAchievementIds: (json['newAchievementIds'] as List?)
                ?.whereType<String>()
                .toList(growable: false) ??
            const <String>[],
      );
}

class GameSessionCheckpoint {
  const GameSessionCheckpoint({
    this.schemaVersion = 1,
    required this.profileId,
    required this.classNumber,
    required this.gameId,
    required this.difficulty,
    required this.stage,
    required this.cursor,
    required this.score,
    required this.maxScore,
    required this.startedAtIso,
    required this.updatedAtIso,
    this.learningLevelId,
    this.completedInteractiveStepIds = const <String>{},
    this.shownHintIndices = const <int>{},
    this.data = const <String, Object?>{},
    this.reward,
  });

  final int schemaVersion;
  final String profileId;
  final int classNumber;
  final String gameId;
  final String? learningLevelId;
  final int difficulty;
  final GameSessionStage stage;
  final int cursor;
  final int score;
  final int maxScore;
  final String startedAtIso;
  final String updatedAtIso;
  final Set<String> completedInteractiveStepIds;
  final Set<int> shownHintIndices;
  final Map<String, Object?> data;
  final GameSessionRewardSnapshot? reward;

  /// Stable persistence slot for one independently resumable mission.
  ///
  /// Learning missions are isolated by level id. Quick Play uses one slot per
  /// profile + class + game. This key is intentionally derived from checkpoint
  /// identity so legacy stores keyed only by profile can be canonicalized on
  /// read without changing the persisted payload schema.
  String get slotKey => gameSessionSlotKey(
        profileId: profileId,
        classNumber: classNumber,
        gameId: gameId,
        learningLevelId: learningLevelId,
      );

  bool matches({
    required String profileId,
    required int classNumber,
    required String gameId,
    String? learningLevelId,
  }) =>
      this.profileId == profileId &&
      this.classNumber == classNumber &&
      this.gameId == gameId &&
      this.learningLevelId == learningLevelId;

  bool get isResumable => stage != GameSessionStage.result || reward != null;

  /// True only while the child is actively inside a lesson/game transaction.
  ///
  /// Completed result checkpoints remain resumable from the dedicated resume
  /// surface so the reward/result screen can be restored after process death,
  /// but an explicit World-stage launch must treat them as finished and create
  /// a fresh encounter instead of reopening the previous result.
  bool get isInProgress => stage != GameSessionStage.result;

  GameSessionCheckpoint copyWith({
    int? classNumber,
    String? gameId,
    String? learningLevelId,
    bool clearLearningLevelId = false,
    int? difficulty,
    GameSessionStage? stage,
    int? cursor,
    int? score,
    int? maxScore,
    String? updatedAtIso,
    Set<String>? completedInteractiveStepIds,
    Set<int>? shownHintIndices,
    Map<String, Object?>? data,
    GameSessionRewardSnapshot? reward,
    bool clearReward = false,
  }) =>
      GameSessionCheckpoint(
        schemaVersion: schemaVersion,
        profileId: profileId,
        classNumber: classNumber ?? this.classNumber,
        gameId: gameId ?? this.gameId,
        learningLevelId: clearLearningLevelId
            ? null
            : learningLevelId ?? this.learningLevelId,
        difficulty: difficulty ?? this.difficulty,
        stage: stage ?? this.stage,
        cursor: cursor ?? this.cursor,
        score: score ?? this.score,
        maxScore: maxScore ?? this.maxScore,
        startedAtIso: startedAtIso,
        updatedAtIso: updatedAtIso ?? this.updatedAtIso,
        completedInteractiveStepIds:
            completedInteractiveStepIds ?? this.completedInteractiveStepIds,
        shownHintIndices: shownHintIndices ?? this.shownHintIndices,
        data: data ?? this.data,
        reward: clearReward ? null : reward ?? this.reward,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'profileId': profileId,
        'classNumber': classNumber,
        'gameId': gameId,
        'learningLevelId': learningLevelId,
        'difficulty': difficulty,
        'stage': stage.name,
        'cursor': cursor,
        'score': score,
        'maxScore': maxScore,
        'startedAtIso': startedAtIso,
        'updatedAtIso': updatedAtIso,
        'completedInteractiveStepIds': completedInteractiveStepIds.toList()
          ..sort(),
        'shownHintIndices': shownHintIndices.toList()..sort(),
        'data': data,
        'reward': reward?.toJson(),
      };

  factory GameSessionCheckpoint.fromJson(Map<String, Object?> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? -1;
    if (schemaVersion != 1) {
      throw FormatException('Unsupported game session schema $schemaVersion.');
    }
    final profileId = json['profileId'] as String? ?? '';
    final gameId = json['gameId'] as String? ?? '';
    final classNumber = (json['classNumber'] as num?)?.toInt() ?? 0;
    if (profileId.isEmpty ||
        gameId.isEmpty ||
        classNumber < 3 ||
        classNumber > 5) {
      throw const FormatException('Invalid game session identity.');
    }
    final rawStage = json['stage'] as String?;
    GameSessionStage? stage;
    for (final candidate in GameSessionStage.values) {
      if (candidate.name == rawStage) {
        stage = candidate;
        break;
      }
    }
    if (stage == null) {
      throw const FormatException('Invalid game session stage.');
    }
    final rawData = json['data'];
    final rawReward = json['reward'];
    return GameSessionCheckpoint(
      schemaVersion: schemaVersion,
      profileId: profileId,
      classNumber: classNumber,
      gameId: gameId,
      learningLevelId: json['learningLevelId'] as String?,
      difficulty:
          ((json['difficulty'] as num?)?.toInt() ?? 1).clamp(1, 5).toInt(),
      stage: stage,
      cursor: ((json['cursor'] as num?)?.toInt() ?? 0).clamp(0, 10000).toInt(),
      score: ((json['score'] as num?)?.toInt() ?? 0).clamp(0, 10000).toInt(),
      maxScore:
          ((json['maxScore'] as num?)?.toInt() ?? 0).clamp(0, 10000).toInt(),
      startedAtIso: json['startedAtIso'] as String? ??
          DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      updatedAtIso: json['updatedAtIso'] as String? ??
          DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      completedInteractiveStepIds:
          (json['completedInteractiveStepIds'] as List?)
                  ?.whereType<String>()
                  .toSet() ??
              const <String>{},
      shownHintIndices: (json['shownHintIndices'] as List?)
              ?.whereType<num>()
              .map((value) => value.toInt())
              .toSet() ??
          const <int>{},
      data: rawData is Map
          ? Map<String, Object?>.from(rawData)
          : const <String, Object?>{},
      reward: rawReward is Map
          ? GameSessionRewardSnapshot.fromJson(
              Map<String, Object?>.from(rawReward),
            )
          : null,
    );
  }
}

String gameSessionSlotKey({
  required String profileId,
  required int classNumber,
  required String gameId,
  String? learningLevelId,
}) {
  final missionId = learningLevelId == null || learningLevelId.trim().isEmpty
      ? '@quick'
      : learningLevelId.trim();
  return '$profileId::c$classNumber::$gameId::$missionId';
}
