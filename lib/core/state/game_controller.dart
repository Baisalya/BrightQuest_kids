import 'package:flutter/foundation.dart';

import '../content/achievement_catalog.dart';
import '../content/content_repository.dart';
import '../entitlements/entitlement_models.dart';
import '../learning/learning_models.dart';
import '../learning/learning_progress_engine.dart';
import '../curriculum/curriculum_catalog.dart';
import '../curriculum/curriculum_models.dart';
import '../models/game_models.dart';
import '../models/progress_models.dart';
import '../nursery/nursery_learning_models.dart';
import '../nursery/nursery_progress_engine.dart';
import '../persistence/progress_store.dart';
import '../session/game_session_models.dart';
import '../session/game_session_store.dart';

class GameController extends ChangeNotifier {
  GameController({ProgressStore? store, GameSessionStore? sessionStore})
      : _store = store ?? MemoryProgressStore(),
        _sessionStore = sessionStore ?? MemoryGameSessionStore(),
        _snapshot = PlayerSnapshot();

  final ProgressStore _store;
  final GameSessionStore _sessionStore;
  PlayerSnapshot _snapshot;
  bool _loaded = false;
  bool _parentSessionUnlocked = false;
  Future<void> _saveTail = Future<void>.value();
  Future<void> _sessionSaveTail = Future<void>.value();
  Map<String, GameSessionCheckpoint> _gameSessions =
      <String, GameSessionCheckpoint>{};
  final Map<String, String> _foregroundSessionKeys = <String, String>{};
  final Map<String, Future<AnswerReward>> _answerTransactions =
      <String, Future<AnswerReward>>{};
  final Map<String, Future<bool>> _hintTransactions = <String, Future<bool>>{};
  final Map<String, Future<MissionReward>> _completionTransactions =
      <String, Future<MissionReward>>{};

  static const LearningProgressEngine _learningProgress =
      LearningProgressEngine();
  static const NurseryProgressEngine _nurseryProgress = NurseryProgressEngine();

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
  double get accuracy =>
      totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;
  double get dailyAccuracy =>
      answersToday == 0 ? 0.0 : correctToday / answersToday;
  Set<String> get unlockedRewards =>
      Set<String>.unmodifiable(_profile.unlockedRewards);
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
  LearningProfileState get learningState => _profile.learning;
  DiagnosticProgress get diagnosticProgress => _profile.learning.diagnostic;
  Map<String, SkillMastery> get skillMastery =>
      Map<String, SkillMastery>.unmodifiable(_profile.learning.skillMastery);
  List<AttemptEvidence> get attemptEvidence =>
      List<AttemptEvidence>.unmodifiable(_profile.learning.attemptEvidence);
  List<ReviewTask> get reviewTasks =>
      List<ReviewTask>.unmodifiable(_profile.learning.reviewTasks);
  List<ProjectEvidence> get projectEvidence =>
      List<ProjectEvidence>.unmodifiable(_profile.learning.projectEvidence);
  String get learningLocaleCode => _profile.learning.localeCode;
  bool get dyslexiaFriendlySpacing => _profile.learning.dyslexiaFriendlySpacing;
  bool get readingFocusEnabled => _profile.learning.readingFocusEnabled;
  bool get captionsEnabled => _profile.learning.captionsEnabled;
  NurseryLearningState get nurseryLearningState => _profile.nurseryLearning;
  Map<String, NurserySkillMastery> get nurserySkillMastery =>
      Map<String, NurserySkillMastery>.unmodifiable(
        _profile.nurseryLearning.skillMastery,
      );
  List<NurseryAttemptEvidence> get nurseryAttemptEvidence =>
      List<NurseryAttemptEvidence>.unmodifiable(
        _profile.nurseryLearning.attemptEvidence,
      );
  Map<int, ClassEntitlement> get entitlementCache =>
      Map<int, ClassEntitlement>.unmodifiable(_snapshot.entitlementCache);
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
    _gameSessions = await _sessionStore.readAll();
    _foregroundSessionKeys.clear();
    final discardedInvalidSessions = _discardInvalidSessionCheckpoints();
    if (discardedInvalidSessions) {
      await _sessionStore.writeAll(
        Map<String, GameSessionCheckpoint>.from(_gameSessions),
      );
    }
    _snapshot.schemaVersion = 6;
    _normalizeToday();
    _profile.learning = _learningProgress.refreshReviewStates(
        _profile.learning, DateTime.now());
    _profile.nurseryLearning = _nurseryProgress.refreshReviewStates(
      _profile.nurseryLearning,
      DateTime.now(),
    );
    _loaded = true;
    notifyListeners();
  }

  GameProgress statsFor(String gameId) =>
      _profile.gameProgress.putIfAbsent(gameId, GameProgress.new);

  TopicProgress topicStatsFor(String gameId, String topicId) =>
      statsFor(gameId).topicProgress.putIfAbsent(topicId, TopicProgress.new);

  LearningLevelProgress levelStatsFor(String levelId) =>
      _profile.levelProgress.putIfAbsent(levelId, LearningLevelProgress.new);

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
        .where((level) =>
            isLevelUnlocked(level) && !levelStatsFor(level.id).completed)
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

  int dailyChallengeValue(DailyChallenge challenge) =>
      switch (challenge.metric) {
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

  void startOrRestartDiagnostic(
    ContentRepository repository, {
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final progress = _learningProgress.startDiagnostic(
      repository: repository,
      classNumber: selectedClass,
      now: timestamp,
    );
    _profile.learning = _profile.learning.copyWith(diagnostic: progress);
    _changed();
  }

  bool recordDiagnosticEvidence({
    required ContentRepository repository,
    required bool correct,
    required int responseTimeMs,
    required double confidence,
    int hintLevel = 0,
    int retries = 0,
    String? misconceptionId,
    DateTime? now,
  }) {
    final progress = diagnosticProgress;
    if (!progress.started || progress.completed) return false;
    final activity = _learningProgress.currentDiagnosticActivity(
      repository: repository,
      progress: progress,
    );
    if (activity == null || activity.classNumber != selectedClass) return false;
    final timestamp = now ?? DateTime.now();
    recordLearningEvidence(
      AttemptEvidence(
        id: 'e:${activeProfileId}:${timestamp.microsecondsSinceEpoch}',
        profileId: activeProfileId,
        classNumber: selectedClass,
        competencyId: activity.competencyId,
        itemId: activity.id,
        kind: LearningAttemptKind.diagnostic,
        correct: correct,
        hintLevel: hintLevel.clamp(0, 2).toInt(),
        retries: retries.clamp(0, 99).toInt(),
        responseTimeMs: responseTimeMs.clamp(0, 3600000).toInt(),
        confidence: confidence.clamp(0.0, 1.0).toDouble(),
        recordedAtIso: timestamp.toIso8601String(),
        misconceptionId: misconceptionId,
        sourceGameId: activity.gameId,
      ),
      saveImmediately: false,
    );
    _profile.learning = _profile.learning.copyWith(
      diagnostic: _learningProgress.advanceDiagnostic(
        progress: progress,
        now: timestamp,
      ),
    );
    _changed();
    return true;
  }

  void recordLearningEvidence(
    AttemptEvidence evidence, {
    bool saveImmediately = true,
  }) {
    if (evidence.profileId != activeProfileId ||
        evidence.classNumber != selectedClass) {
      return;
    }
    _profile.learning =
        _learningProgress.recordEvidence(_profile.learning, evidence);
    if (saveImmediately) _changed();
  }

  Future<void> recordLearningEvidenceSafely(AttemptEvidence evidence) async {
    if (!_hasLearningEvidenceId(evidence.id)) {
      recordLearningEvidence(evidence);
    }
    await flush();
  }

  bool _hasLearningEvidenceId(String evidenceId) =>
      _profile.learning.attemptEvidence.any((item) => item.id == evidenceId);

  List<ReviewTask> dueReviewTasks({DateTime? now, int limit = 10}) {
    final timestamp = now ?? DateTime.now();
    _profile.learning =
        _learningProgress.refreshReviewStates(_profile.learning, timestamp);
    return _learningProgress.dueReviewTasks(
      _profile.learning,
      classNumber: selectedClass,
      now: timestamp,
      limit: limit,
    );
  }

  List<LearningRecommendation> learningRecommendations({int limit = 5}) =>
      _learningProgress.recommendations(
        _profile.learning,
        limit: limit,
      );

  void recordProjectEvidence(ProjectEvidence evidence) {
    if (evidence.classNumber != selectedClass) return;
    final values = <ProjectEvidence>[
      ..._profile.learning.projectEvidence,
      evidence
    ];
    if (values.length > 100) {
      values.removeRange(0, values.length - 100);
    }
    _profile.learning = _profile.learning.copyWith(
      projectEvidence: List<ProjectEvidence>.unmodifiable(values),
    );
    _changed();
  }

  void recordNurseryEvidence(NurseryAttemptEvidence evidence) {
    if (evidence.profileId != activeProfileId ||
        evidence.packId != 'brightquest_nursery') {
      return;
    }
    _profile.nurseryLearning = _nurseryProgress.record(
      _profile.nurseryLearning,
      evidence,
    );
    _changed();
  }

  List<NurseryReviewTask> dueNurseryReviewTasks({
    DateTime? now,
    int limit = 10,
  }) {
    final timestamp = now ?? DateTime.now();
    _profile.nurseryLearning = _nurseryProgress.refreshReviewStates(
      _profile.nurseryLearning,
      timestamp,
    );
    return _nurseryProgress.dueTasks(
      _profile.nurseryLearning,
      now: timestamp,
      limit: limit,
    );
  }

  NurserySkillMastery nurseryMasteryFor(String skillId) =>
      _profile.nurseryLearning.skillMastery[skillId] ??
      NurserySkillMastery(skillId: skillId);

  void setLearningLocale(String localeCode) {
    if (localeCode != 'en-IN') return;
    if (_profile.learning.localeCode == localeCode) return;
    _profile.learning = _profile.learning.copyWith(localeCode: localeCode);
    _changed();
  }

  void setDyslexiaFriendlySpacing(bool value) {
    if (_profile.learning.dyslexiaFriendlySpacing == value) return;
    _profile.learning =
        _profile.learning.copyWith(dyslexiaFriendlySpacing: value);
    _changed();
  }

  void setReadingFocusEnabled(bool value) {
    if (_profile.learning.readingFocusEnabled == value) return;
    _profile.learning = _profile.learning.copyWith(readingFocusEnabled: value);
    _changed();
  }

  void setCaptionsEnabled(bool value) {
    if (_profile.learning.captionsEnabled == value) return;
    _profile.learning = _profile.learning.copyWith(captionsEnabled: value);
    _changed();
  }

  void cacheEntitlement(ClassEntitlement entitlement) {
    _snapshot.entitlementCache[entitlement.classNumber] = entitlement;
    _changed();
  }

  void setClass(int value) {
    if (value < 3 || value > 5 || value == _profile.selectedClass) return;
    _foregroundSessionKeys.remove(activeProfileId);
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
    _foregroundSessionKeys.remove(profileId);
    final beforeSessionCount = _gameSessions.length;
    _gameSessions
        .removeWhere((_, checkpoint) => checkpoint.profileId == profileId);
    if (_gameSessions.length != beforeSessionCount) {
      _enqueueSessionSave();
    }
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
    String? itemId,
    String? competencyId,
    LearningAttemptKind evidenceKind = LearningAttemptKind.independent,
    int hintLevel = 0,
    int retries = 0,
    int responseTimeMs = 0,
    String? misconceptionId,
    double confidence = 0.75,
    String? evidenceId,
  }) {
    if (evidenceId != null && _hasLearningEvidenceId(evidenceId)) {
      return AnswerReward(
        correct: correct,
        coinsAwarded: 0,
        xpAwarded: 0,
        starsAwarded: 0,
      );
    }
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

    if (itemId != null && competencyId != null) {
      final now = DateTime.now();
      recordLearningEvidence(
        AttemptEvidence(
          id: evidenceId ??
              'e:${activeProfileId}:${now.microsecondsSinceEpoch}',
          profileId: activeProfileId,
          classNumber: selectedClass,
          competencyId: competencyId,
          itemId: itemId,
          kind: evidenceKind,
          correct: correct,
          hintLevel: hintLevel.clamp(0, 2).toInt(),
          retries: retries.clamp(0, 99).toInt(),
          responseTimeMs: responseTimeMs.clamp(0, 3600000).toInt(),
          confidence: confidence.clamp(0.0, 1.0).toDouble(),
          recordedAtIso: now.toIso8601String(),
          misconceptionId: misconceptionId,
          sourceGameId: gameId,
        ),
        saveImmediately: false,
      );
    }

    _changed();
    return AnswerReward(
      correct: correct,
      coinsAwarded: coinsAwarded,
      xpAwarded: xpAwarded,
      starsAwarded: starsAwarded,
      newAchievementIds: newAchievements,
    );
  }

  Future<AnswerReward> recordAnswerSafely({
    required String gameId,
    required bool correct,
    required String attemptMarker,
    String topicId = 'general',
    int difficulty = 1,
    double masteryGain = 0.05,
    int coinReward = 10,
    int xpReward = 10,
    String? itemId,
    String? competencyId,
    LearningAttemptKind evidenceKind = LearningAttemptKind.independent,
    int hintLevel = 0,
    int retries = 0,
    int responseTimeMs = 0,
    String? misconceptionId,
    double confidence = 0.75,
    LearningLevel? learningLevel,
  }) {
    final current = _sessionForAction(
      gameId: gameId,
      learningLevel: learningLevel,
    );
    if (current == null ||
        current.profileId != activeProfileId ||
        current.classNumber != selectedClass ||
        current.gameId != gameId) {
      return _recordAnswerSafelyTransaction(
        gameId: gameId,
        correct: correct,
        attemptMarker: attemptMarker,
        topicId: topicId,
        difficulty: difficulty,
        masteryGain: masteryGain,
        coinReward: coinReward,
        xpReward: xpReward,
        itemId: itemId,
        competencyId: competencyId,
        evidenceKind: evidenceKind,
        hintLevel: hintLevel,
        retries: retries,
        responseTimeMs: responseTimeMs,
        misconceptionId: misconceptionId,
        confidence: confidence,
        learningLevel: learningLevel,
      );
    }

    final key =
        '${current.profileId}|${current.startedAtIso}|$gameId|$attemptMarker';
    final existing = _answerTransactions[key];
    if (existing != null) return existing;
    final transaction = _recordAnswerSafelyTransaction(
      gameId: gameId,
      correct: correct,
      attemptMarker: attemptMarker,
      topicId: topicId,
      difficulty: difficulty,
      masteryGain: masteryGain,
      coinReward: coinReward,
      xpReward: xpReward,
      itemId: itemId,
      competencyId: competencyId,
      evidenceKind: evidenceKind,
      hintLevel: hintLevel,
      retries: retries,
      responseTimeMs: responseTimeMs,
      misconceptionId: misconceptionId,
      confidence: confidence,
      learningLevel: learningLevel,
    );
    _answerTransactions[key] = transaction;
    return transaction.whenComplete(() {
      if (identical(_answerTransactions[key], transaction)) {
        _answerTransactions.remove(key);
      }
    });
  }

  Future<AnswerReward> _recordAnswerSafelyTransaction({
    required String gameId,
    required bool correct,
    required String attemptMarker,
    String topicId = 'general',
    int difficulty = 1,
    double masteryGain = 0.05,
    int coinReward = 10,
    int xpReward = 10,
    String? itemId,
    String? competencyId,
    LearningAttemptKind evidenceKind = LearningAttemptKind.independent,
    int hintLevel = 0,
    int retries = 0,
    int responseTimeMs = 0,
    String? misconceptionId,
    double confidence = 0.75,
    LearningLevel? learningLevel,
  }) async {
    final current = _sessionForAction(
      gameId: gameId,
      learningLevel: learningLevel,
    );
    if (current == null ||
        current.profileId != activeProfileId ||
        current.classNumber != selectedClass ||
        current.gameId != gameId) {
      final reward = recordAnswer(
        gameId: gameId,
        correct: correct,
        topicId: topicId,
        difficulty: difficulty,
        masteryGain: masteryGain,
        coinReward: coinReward,
        xpReward: xpReward,
        itemId: itemId,
        competencyId: competencyId,
        evidenceKind: evidenceKind,
        hintLevel: hintLevel,
        retries: retries,
        responseTimeMs: responseTimeMs,
        misconceptionId: misconceptionId,
        confidence: confidence,
      );
      await flush();
      return reward;
    }

    final committedMarkers = (current.data['_session.answerMarkers'] as List?)
            ?.whereType<String>()
            .toSet() ??
        <String>{};
    if (committedMarkers.contains(attemptMarker)) {
      return AnswerReward(
        correct: correct,
        coinsAwarded: 0,
        xpAwarded: 0,
        starsAwarded: 0,
      );
    }

    final pendingMarker = current.data['_session.pendingAnswer'] as String?;
    final baselineAttempts =
        (current.data['_session.pendingAnswerBaseAttempts'] as num?)?.toInt();
    final hasMatchingPending =
        pendingMarker == attemptMarker && baselineAttempts != null;

    var working = current;
    if (!hasMatchingPending) {
      final sortedCommittedMarkers = committedMarkers.toList()..sort();
      final data = Map<String, Object?>.from(current.data)
        ..['_session.pendingAnswer'] = attemptMarker
        ..['_session.pendingAnswerBaseAttempts'] = statsFor(gameId).attempts
        ..['_session.answerMarkers'] = sortedCommittedMarkers;
      working = current.copyWith(
        data: Map<String, Object?>.unmodifiable(data),
        updatedAtIso: DateTime.now().toIso8601String(),
      );
      _putGameSession(working);
      _enqueueSessionSave();
      await flushGameSession();
    }

    final baseAttempts =
        (working.data['_session.pendingAnswerBaseAttempts'] as num?)?.toInt() ??
            statsFor(gameId).attempts;
    final alreadyApplied = statsFor(gameId).attempts > baseAttempts;
    late AnswerReward reward;
    if (alreadyApplied) {
      await flush();
      reward = AnswerReward(
        correct: correct,
        coinsAwarded: 0,
        xpAwarded: 0,
        starsAwarded: 0,
      );
    } else {
      reward = recordAnswer(
        gameId: gameId,
        correct: correct,
        topicId: topicId,
        difficulty: difficulty,
        masteryGain: masteryGain,
        coinReward: coinReward,
        xpReward: xpReward,
        itemId: itemId,
        competencyId: competencyId,
        evidenceKind: evidenceKind,
        hintLevel: hintLevel,
        retries: retries,
        responseTimeMs: responseTimeMs,
        misconceptionId: misconceptionId,
        confidence: confidence,
        evidenceId: activeSessionEvidenceId(
          gameId: gameId,
          marker: attemptMarker,
          learningLevel: learningLevel,
        ),
      );
      await flush();
    }

    committedMarkers.add(attemptMarker);
    final live = _gameSessions[current.slotKey];
    if (live != null && live.startedAtIso == current.startedAtIso) {
      final sortedCommittedMarkers = committedMarkers.toList()..sort();
      final finalData = Map<String, Object?>.from(live.data)
        ..remove('_session.pendingAnswer')
        ..remove('_session.pendingAnswerBaseAttempts')
        ..['_session.answerMarkers'] = sortedCommittedMarkers;
      _putGameSession(live.copyWith(
        data: Map<String, Object?>.unmodifiable(finalData),
        updatedAtIso: DateTime.now().toIso8601String(),
      ));
      _enqueueSessionSave();
      await flushGameSession();
    }
    return reward;
  }

  String? activeSessionEvidenceId({
    required String gameId,
    required String marker,
    LearningLevel? learningLevel,
  }) {
    final session = _sessionForAction(
      gameId: gameId,
      learningLevel: learningLevel,
    );
    if (session == null ||
        session.profileId != activeProfileId ||
        session.classNumber != selectedClass ||
        session.gameId != gameId) {
      return null;
    }
    return 'session:${session.profileId}:${session.startedAtIso}:$gameId:$marker';
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
    if (normalizedScore > progress.bestScore)
      progress.bestScore = normalizedScore;

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

  GameSessionCheckpoint? get activeGameSession {
    final foregroundKey = _foregroundSessionKeys[activeProfileId];
    final foreground =
        foregroundKey == null ? null : _gameSessions[foregroundKey];
    if (foreground != null &&
        foreground.profileId == activeProfileId &&
        foreground.classNumber == selectedClass &&
        foreground.isResumable) {
      return foreground;
    }
    final sessions = resumableGameSessions;
    return sessions.isEmpty ? null : sessions.first;
  }

  List<GameSessionCheckpoint> get resumableGameSessions =>
      resumableGameSessionsForClass(selectedClass);

  List<GameSessionCheckpoint> resumableGameSessionsForClass(int classNumber) {
    final sessions = _gameSessions.values
        .where(
          (checkpoint) =>
              checkpoint.profileId == activeProfileId &&
              checkpoint.classNumber == classNumber &&
              checkpoint.isResumable,
        )
        .toList(growable: false);
    sessions.sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
    return List<GameSessionCheckpoint>.unmodifiable(sessions);
  }

  List<GameSessionCheckpoint> get allResumableGameSessionsForActiveProfile {
    final sessions = _gameSessions.values
        .where(
          (checkpoint) =>
              checkpoint.profileId == activeProfileId && checkpoint.isResumable,
        )
        .toList(growable: false);
    sessions.sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
    return List<GameSessionCheckpoint>.unmodifiable(sessions);
  }

  GameSessionCheckpoint? gameSessionFor({
    required String gameId,
    required int classNumber,
    String? learningLevelId,
  }) =>
      _gameSessions[gameSessionSlotKey(
        profileId: activeProfileId,
        classNumber: classNumber,
        gameId: gameId,
        learningLevelId: learningLevelId,
      )];

  void activateGameSession(GameSessionCheckpoint checkpoint) {
    if (checkpoint.profileId != activeProfileId) return;
    final live = _gameSessions[checkpoint.slotKey];
    if (live == null) return;
    _foregroundSessionKeys[activeProfileId] = live.slotKey;
  }

  void _putGameSession(
    GameSessionCheckpoint checkpoint, {
    bool activate = true,
  }) {
    _gameSessions[checkpoint.slotKey] = checkpoint;
    if (activate && checkpoint.profileId == activeProfileId) {
      _foregroundSessionKeys[activeProfileId] = checkpoint.slotKey;
    }
  }

  GameSessionCheckpoint? _sessionForAction({
    required String gameId,
    LearningLevel? learningLevel,
  }) {
    final exact = gameSessionFor(
      gameId: gameId,
      classNumber: learningLevel?.classNumber ?? selectedClass,
      learningLevelId: learningLevel?.id,
    );
    if (exact != null) return exact;
    final foreground = activeGameSession;
    if (foreground != null && foreground.gameId == gameId) return foreground;
    return null;
  }

  int resumableDifficulty({
    required String gameId,
    required int classNumber,
    required int fallbackDifficulty,
    String? learningLevelId,
  }) {
    final current = gameSessionFor(
      gameId: gameId,
      classNumber: classNumber,
      learningLevelId: learningLevelId,
    );
    return current?.difficulty ?? fallbackDifficulty.clamp(1, 5).toInt();
  }

  bool get hasResumableGameSession => resumableGameSessions.isNotEmpty;

  GameSessionCheckpoint beginLessonSession({
    required LearningLevel level,
    required int totalSteps,
  }) {
    final current = gameSessionFor(
      gameId: level.gameId,
      classNumber: level.classNumber,
      learningLevelId: level.id,
    );
    if (current != null && current.stage == GameSessionStage.lesson) {
      activateGameSession(current);
      return current;
    }
    final now = DateTime.now().toIso8601String();
    final checkpoint = GameSessionCheckpoint(
      profileId: activeProfileId,
      classNumber: level.classNumber,
      gameId: level.gameId,
      learningLevelId: level.id,
      difficulty: level.difficulty,
      stage: GameSessionStage.lesson,
      cursor: 0,
      score: 0,
      maxScore: totalSteps,
      startedAtIso: current?.startedAtIso ?? now,
      updatedAtIso: now,
    );
    _putGameSession(checkpoint);
    _enqueueSessionSave();
    return checkpoint;
  }

  void checkpointLessonSession({
    required LearningLevel level,
    required int stepIndex,
    required int totalSteps,
    required Set<String> completedInteractiveStepIds,
    required Set<int> shownHintIndices,
    int attemptSerial = 0,
  }) {
    var current = gameSessionFor(
      gameId: level.gameId,
      classNumber: level.classNumber,
      learningLevelId: level.id,
    );
    current ??= beginLessonSession(level: level, totalSteps: totalSteps);
    final updated = current.copyWith(
      stage: GameSessionStage.lesson,
      cursor: stepIndex.clamp(0, totalSteps > 0 ? totalSteps - 1 : 0).toInt(),
      maxScore: totalSteps,
      completedInteractiveStepIds:
          Set<String>.unmodifiable(completedInteractiveStepIds),
      shownHintIndices: Set<int>.unmodifiable(shownHintIndices),
      data: <String, Object?>{
        'attemptSerial': attemptSerial.clamp(0, 1000000).toInt(),
      },
      clearReward: true,
      updatedAtIso: DateTime.now().toIso8601String(),
    );
    _putGameSession(updated);
    _enqueueSessionSave();
  }

  GameSessionCheckpoint beginOrResumeGameSession({
    required String gameId,
    required int classNumber,
    required int difficulty,
    required int maxScore,
    LearningLevel? learningLevel,
  }) {
    final levelId = learningLevel?.id;
    final current = gameSessionFor(
      gameId: gameId,
      classNumber: classNumber,
      learningLevelId: levelId,
    );
    if (current != null && current.stage != GameSessionStage.lesson) {
      activateGameSession(current);
      return current;
    }
    final now = DateTime.now().toIso8601String();
    final checkpoint = GameSessionCheckpoint(
      profileId: activeProfileId,
      classNumber: classNumber,
      gameId: gameId,
      learningLevelId: levelId,
      difficulty: difficulty,
      stage: GameSessionStage.game,
      cursor: 0,
      score: 0,
      maxScore: maxScore,
      startedAtIso: current?.startedAtIso ?? now,
      updatedAtIso: now,
    );
    _putGameSession(checkpoint);
    _enqueueSessionSave();
    return checkpoint;
  }

  void transitionActiveSessionToGame({required LearningLevel level}) {
    final current = gameSessionFor(
      gameId: level.gameId,
      classNumber: level.classNumber,
      learningLevelId: level.id,
    );
    if (current == null) return;
    final updated = current.copyWith(
      stage: GameSessionStage.game,
      cursor: 0,
      score: 0,
      maxScore: 0,
      data: const <String, Object?>{},
      shownHintIndices: const <int>{},
      clearReward: true,
      updatedAtIso: DateTime.now().toIso8601String(),
    );
    _putGameSession(updated);
    _enqueueSessionSave();
  }

  void checkpointGameSession({
    required String gameId,
    required int classNumber,
    required int difficulty,
    required int cursor,
    required int score,
    required int maxScore,
    LearningLevel? learningLevel,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    var current = gameSessionFor(
      gameId: gameId,
      classNumber: classNumber,
      learningLevelId: learningLevel?.id,
    );
    current ??= beginOrResumeGameSession(
      gameId: gameId,
      classNumber: classNumber,
      difficulty: difficulty,
      maxScore: maxScore,
      learningLevel: learningLevel,
    );
    final preservedSessionData = <String, Object?>{
      for (final entry in current.data.entries)
        if (entry.key.startsWith('_session.')) entry.key: entry.value,
    };
    final updated = current.copyWith(
      stage: GameSessionStage.game,
      cursor: cursor.clamp(0, maxScore > 0 ? maxScore - 1 : 0).toInt(),
      score: score.clamp(0, maxScore).toInt(),
      maxScore: maxScore,
      data: Map<String, Object?>.unmodifiable(
        <String, Object?>{...preservedSessionData, ...data},
      ),
      clearReward: true,
      updatedAtIso: DateTime.now().toIso8601String(),
    );
    _putGameSession(updated);
    _enqueueSessionSave();
  }

  Future<bool> useHintSafely({
    required String gameId,
    required int cost,
    required String marker,
    LearningLevel? learningLevel,
  }) {
    final current = _sessionForAction(
      gameId: gameId,
      learningLevel: learningLevel,
    );
    if (current == null || cost <= 0) {
      return Future<bool>.value(false);
    }
    activateGameSession(current);
    final key = '${current.profileId}|${current.startedAtIso}|$gameId|$marker';
    final existing = _hintTransactions[key];
    if (existing != null) return existing;
    final transaction = _useHintSafelyTransaction(
      gameId: gameId,
      cost: cost,
      marker: marker,
      learningLevel: learningLevel,
    );
    _hintTransactions[key] = transaction;
    return transaction.whenComplete(() {
      if (identical(_hintTransactions[key], transaction)) {
        _hintTransactions.remove(key);
      }
    });
  }

  Future<bool> _useHintSafelyTransaction({
    required String gameId,
    required int cost,
    required String marker,
    LearningLevel? learningLevel,
  }) async {
    final current = _sessionForAction(
      gameId: gameId,
      learningLevel: learningLevel,
    );
    if (current == null || cost <= 0) return false;
    final paidMarkers = (current.data['_session.paidHints'] as List?)
            ?.whereType<String>()
            .toSet() ??
        <String>{};
    if (paidMarkers.contains(marker)) return true;

    final pendingMarker = current.data['_session.pendingHint'] as String?;
    final baselineHints =
        (current.data['_session.pendingHintBaseCount'] as num?)?.toInt();
    final hasMatchingPending = pendingMarker == marker && baselineHints != null;

    var working = current;
    if (!hasMatchingPending) {
      final sortedPaidMarkers = paidMarkers.toList()..sort();
      final data = Map<String, Object?>.from(current.data)
        ..['_session.pendingHint'] = marker
        ..['_session.pendingHintBaseCount'] = statsFor(gameId).hintsUsed
        ..['_session.paidHints'] = sortedPaidMarkers;
      working = current.copyWith(
        data: Map<String, Object?>.unmodifiable(data),
        updatedAtIso: DateTime.now().toIso8601String(),
      );
      _putGameSession(working);
      _enqueueSessionSave();
      await flushGameSession();
    }

    final baseCount =
        (working.data['_session.pendingHintBaseCount'] as num?)?.toInt() ??
            statsFor(gameId).hintsUsed;
    final alreadyApplied = statsFor(gameId).hintsUsed > baseCount;
    if (alreadyApplied) {
      await flush();
    } else {
      if (!useHint(gameId: gameId, cost: cost)) {
        final cleared = Map<String, Object?>.from(working.data)
          ..remove('_session.pendingHint')
          ..remove('_session.pendingHintBaseCount');
        _putGameSession(
          working.copyWith(
            data: Map<String, Object?>.unmodifiable(cleared),
            updatedAtIso: DateTime.now().toIso8601String(),
          ),
        );
        _enqueueSessionSave();
        await flushGameSession();
        return false;
      }
      await flush();
    }

    paidMarkers.add(marker);
    final sortedPaidMarkers = paidMarkers.toList()..sort();
    final committed = Map<String, Object?>.from(working.data)
      ..remove('_session.pendingHint')
      ..remove('_session.pendingHintBaseCount')
      ..['_session.paidHints'] = sortedPaidMarkers;
    _putGameSession(
      working.copyWith(
        data: Map<String, Object?>.unmodifiable(committed),
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
    _enqueueSessionSave();
    await flushGameSession();
    return true;
  }

  Future<MissionReward> completeRunSafely({
    required String gameId,
    required String fallbackMissionId,
    required int score,
    required int maxScore,
    LearningLevel? learningLevel,
  }) {
    final current = beginOrResumeGameSession(
      gameId: gameId,
      classNumber: learningLevel?.classNumber ?? selectedClass,
      difficulty: learningLevel?.difficulty ?? recommendedDifficulty(gameId),
      maxScore: maxScore,
      learningLevel: learningLevel,
    );
    final key =
        '${current.profileId}|${current.startedAtIso}|$gameId|${learningLevel?.id ?? 'quick'}';
    final existing = _completionTransactions[key];
    if (existing != null) return existing;
    final transaction = _completeRunSafelyTransaction(
      gameId: gameId,
      fallbackMissionId: fallbackMissionId,
      score: score,
      maxScore: maxScore,
      learningLevel: learningLevel,
    );
    _completionTransactions[key] = transaction;
    return transaction.whenComplete(() {
      if (identical(_completionTransactions[key], transaction)) {
        _completionTransactions.remove(key);
      }
    });
  }

  Future<MissionReward> _completeRunSafelyTransaction({
    required String gameId,
    required String fallbackMissionId,
    required int score,
    required int maxScore,
    LearningLevel? learningLevel,
  }) async {
    final current = beginOrResumeGameSession(
      gameId: gameId,
      classNumber: learningLevel?.classNumber ?? selectedClass,
      difficulty: learningLevel?.difficulty ?? recommendedDifficulty(gameId),
      maxScore: maxScore,
      learningLevel: learningLevel,
    );
    if (current.stage == GameSessionStage.result && current.reward != null) {
      return current.reward!.toReward();
    }

    GameSessionCheckpoint pending = current;
    if (current.stage != GameSessionStage.completing) {
      final levelProgress =
          learningLevel == null ? null : levelStatsFor(learningLevel.id);
      final baseline = <String, Object?>{
        'fallbackMissionId': fallbackMissionId,
        'score': score,
        'maxScore': maxScore,
        'baseCoins': coins,
        'baseXp': xp,
        'baseStars': stars,
        'baseGameCompletedRuns': statsFor(gameId).completedRuns,
        'baseLevelAttempts': levelProgress?.attempts ?? -1,
        'baseLevelCompletedRuns': levelProgress?.completedRuns ?? -1,
        'baseLevelStars': levelProgress?.earnedStars ?? -1,
        'baseMissionCompleted':
            _profile.completedMissionIds.contains(fallbackMissionId),
        'baseAchievementIds': unlockedAchievementIds.toList()..sort(),
      };
      pending = current.copyWith(
        stage: GameSessionStage.completing,
        score: score.clamp(0, maxScore).toInt(),
        maxScore: maxScore,
        data: baseline,
        clearReward: true,
        updatedAtIso: DateTime.now().toIso8601String(),
      );
      _putGameSession(pending);
      _enqueueSessionSave();
      await flushGameSession();
    }

    final baseGameRuns =
        (pending.data['baseGameCompletedRuns'] as num?)?.toInt() ??
            statsFor(gameId).completedRuns;
    final baseLevelAttempts =
        (pending.data['baseLevelAttempts'] as num?)?.toInt() ?? -1;
    final alreadyApplied = learningLevel != null
        ? levelStatsFor(learningLevel.id).attempts > baseLevelAttempts
        : statsFor(gameId).completedRuns > baseGameRuns;

    late MissionReward reward;
    if (alreadyApplied) {
      await flush();
      reward = _recoverMissionReward(
        checkpoint: pending,
        fallbackMissionId: fallbackMissionId,
        learningLevel: learningLevel,
      );
    } else {
      reward = completeRun(
        gameId: gameId,
        fallbackMissionId: fallbackMissionId,
        score: score,
        maxScore: maxScore,
        learningLevel: learningLevel,
      );
      await flush();
    }

    _putGameSession(pending.copyWith(
      stage: GameSessionStage.result,
      score: score.clamp(0, maxScore).toInt(),
      maxScore: maxScore,
      reward: GameSessionRewardSnapshot.fromReward(reward),
      data: const <String, Object?>{},
      updatedAtIso: DateTime.now().toIso8601String(),
    ));
    _enqueueSessionSave();
    await flushGameSession();
    return reward;
  }

  MissionReward _recoverMissionReward({
    required GameSessionCheckpoint checkpoint,
    required String fallbackMissionId,
    required LearningLevel? learningLevel,
  }) {
    final baseCoins = (checkpoint.data['baseCoins'] as num?)?.toInt() ?? coins;
    final baseXp = (checkpoint.data['baseXp'] as num?)?.toInt() ?? xp;
    final baseStars = (checkpoint.data['baseStars'] as num?)?.toInt() ?? stars;
    final beforeAchievements = (checkpoint.data['baseAchievementIds'] as List?)
            ?.whereType<String>()
            .toSet() ??
        const <String>{};
    final newAchievements = unlockedAchievementIds
        .where((id) => !beforeAchievements.contains(id))
        .toList(growable: false);
    if (learningLevel != null) {
      final progress = levelStatsFor(learningLevel.id);
      final baseCompletedRuns =
          (checkpoint.data['baseLevelCompletedRuns'] as num?)?.toInt() ??
              progress.completedRuns;
      final baseLevelStars =
          (checkpoint.data['baseLevelStars'] as num?)?.toInt() ??
              progress.earnedStars;
      final next = _nextLevelInTrack(learningLevel);
      final ratio = checkpoint.maxScore <= 0
          ? 0.0
          : checkpoint.score / checkpoint.maxScore;
      return MissionReward(
        firstCompletion: baseCompletedRuns == 0 && progress.completedRuns > 0,
        coinsAwarded: (coins - baseCoins).clamp(0, 1000000).toInt(),
        xpAwarded: (xp - baseXp).clamp(0, 1000000).toInt(),
        starsAwarded: (stars - baseStars).clamp(0, 1000000).toInt(),
        levelId: learningLevel.id,
        levelCompleted: ratio >= learningLevel.passRatio,
        levelStars: progress.earnedStars,
        levelStarsAwarded:
            (progress.earnedStars - baseLevelStars).clamp(0, 3).toInt(),
        unlockedNextLevel: ratio >= learningLevel.passRatio &&
            next != null &&
            isLevelUnlocked(next),
        newAchievementIds: newAchievements,
      );
    }
    final baseMissionCompleted =
        checkpoint.data['baseMissionCompleted'] as bool? ?? false;
    final nowCompleted =
        _profile.completedMissionIds.contains(fallbackMissionId);
    return MissionReward(
      firstCompletion: !baseMissionCompleted && nowCompleted,
      coinsAwarded: (coins - baseCoins).clamp(0, 1000000).toInt(),
      xpAwarded: (xp - baseXp).clamp(0, 1000000).toInt(),
      starsAwarded: (stars - baseStars).clamp(0, 1000000).toInt(),
      newAchievementIds: newAchievements,
    );
  }

  void discardGameSession(GameSessionCheckpoint checkpoint) {
    final removed = _gameSessions.remove(checkpoint.slotKey);
    if (removed == null) return;
    if (_foregroundSessionKeys[checkpoint.profileId] == checkpoint.slotKey) {
      _foregroundSessionKeys.remove(checkpoint.profileId);
    }
    _enqueueSessionSave();
    notifyListeners();
  }

  void discardGameSessionFor({
    required String gameId,
    required int classNumber,
    String? learningLevelId,
  }) {
    final checkpoint = gameSessionFor(
      gameId: gameId,
      classNumber: classNumber,
      learningLevelId: learningLevelId,
    );
    if (checkpoint != null) discardGameSession(checkpoint);
  }

  void discardActiveGameSession() {
    final current = activeGameSession;
    if (current != null) discardGameSession(current);
  }

  void discardAllGameSessionsForActiveProfile() {
    final profileId = activeProfileId;
    final before = _gameSessions.length;
    _gameSessions
        .removeWhere((_, checkpoint) => checkpoint.profileId == profileId);
    _foregroundSessionKeys.remove(profileId);
    if (_gameSessions.length == before) return;
    _enqueueSessionSave();
    notifyListeners();
  }

  void restartActiveGameSession({
    required String gameId,
    required int classNumber,
    required int difficulty,
    required int maxScore,
    LearningLevel? learningLevel,
  }) {
    final now = DateTime.now().toIso8601String();
    final checkpoint = GameSessionCheckpoint(
      profileId: activeProfileId,
      classNumber: classNumber,
      gameId: gameId,
      learningLevelId: learningLevel?.id,
      difficulty: difficulty,
      stage: GameSessionStage.game,
      cursor: 0,
      score: 0,
      maxScore: maxScore,
      startedAtIso: now,
      updatedAtIso: now,
    );
    _putGameSession(checkpoint);
    _enqueueSessionSave();
  }

  Future<void> flushGameSession() {
    _enqueueSessionSave();
    return _sessionSaveTail;
  }

  bool _discardInvalidSessionCheckpoints() {
    final knownGameIds = games
        .where((game) => game.id != 'rewards_room')
        .map((game) => game.id)
        .toSet();
    var removed = false;
    _gameSessions.removeWhere((slotKey, checkpoint) {
      final profile = _snapshot.profiles[checkpoint.profileId];
      if (profile == null) {
        removed = true;
        return true;
      }
      var invalid = slotKey != checkpoint.slotKey ||
          !checkpoint.isResumable ||
          !knownGameIds.contains(checkpoint.gameId);
      if (!invalid && checkpoint.stage == GameSessionStage.completing) {
        final fallbackMissionId =
            checkpoint.data['fallbackMissionId'] as String?;
        final achievementIds = checkpoint.data['baseAchievementIds'];
        final validAchievementIds = achievementIds is List &&
            achievementIds.every((value) => value is String);
        invalid = fallbackMissionId == null ||
            fallbackMissionId.isEmpty ||
            checkpoint.maxScore <= 0 ||
            checkpoint.score < 0 ||
            checkpoint.score > checkpoint.maxScore ||
            checkpoint.data['baseCoins'] is! num ||
            checkpoint.data['baseXp'] is! num ||
            checkpoint.data['baseStars'] is! num ||
            checkpoint.data['baseGameCompletedRuns'] is! num ||
            !validAchievementIds;
        if (!invalid && checkpoint.learningLevelId != null) {
          invalid = checkpoint.data['baseLevelAttempts'] is! num ||
              checkpoint.data['baseLevelCompletedRuns'] is! num ||
              checkpoint.data['baseLevelStars'] is! num;
        }
        if (!invalid && checkpoint.learningLevelId == null) {
          invalid = checkpoint.data['baseMissionCompleted'] is! bool;
        }
      }
      final learningLevelId = checkpoint.learningLevelId;
      if (!invalid && learningLevelId != null) {
        final level = learningLevelById(learningLevelId);
        invalid = level == null ||
            level.classNumber != checkpoint.classNumber ||
            level.gameId != checkpoint.gameId ||
            level.difficulty != checkpoint.difficulty;
      }
      final updated = DateTime.tryParse(checkpoint.updatedAtIso);
      if (!invalid && updated == null) invalid = true;
      if (!invalid && updated != null) {
        final age = DateTime.now().difference(updated);
        invalid = age.inDays > 14 || age < const Duration(minutes: -5);
      }
      removed = removed || invalid;
      return invalid;
    });
    return removed;
  }

  void _enqueueSessionSave() {
    final snapshot = Map<String, GameSessionCheckpoint>.from(_gameSessions);
    _sessionSaveTail = _sessionSaveTail
        .catchError((Object _, StackTrace __) {})
        .then((_) => _sessionStore.writeAll(snapshot));
  }

  Future<void> resetProgress() async {
    final current = _profile;
    discardAllGameSessionsForActiveProfile();
    await flushGameSession();
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
      learning: LearningProfileState(
        localeCode: current.learning.localeCode,
        dyslexiaFriendlySpacing: current.learning.dyslexiaFriendlySpacing,
        readingFocusEnabled: current.learning.readingFocusEnabled,
        captionsEnabled: current.learning.captionsEnabled,
      ),
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

  /// Flushes both authoritative progress and resumable game-session state.
  ///
  /// This is used by the root lifecycle boundary so backgrounding, desktop
  /// window hiding and memory pressure cannot leave one persistence stream
  /// newer than the other merely because the child was outside a game route.
  Future<void> flushAll() async {
    await Future.wait<void>(<Future<void>>[
      flush(),
      flushGameSession(),
    ]);
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

    final completedAny =
        _profile.levelProgress.values.any((value) => value.completed);
    final hasPerfect =
        _profile.levelProgress.values.any((value) => value.earnedStars >= 3);
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
