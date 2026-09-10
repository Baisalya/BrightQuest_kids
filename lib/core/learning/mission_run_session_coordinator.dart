import '../content/content_repository.dart';
import '../curriculum/curriculum_models.dart';
import '../models/progress_models.dart';
import '../session/game_session_models.dart';
import 'mission_run_allocation_policy.dart';
import 'mission_run_models.dart';
import 'learning_models.dart';
import 'mission_run_planner.dart';
import 'mission_variety_intelligence.dart';
import 'mission_variety_models.dart';

/// Owns the persistence boundary between a planned Learning World run and the
/// existing resumable game-session checkpoint.
///
/// The plan is stored under an `_session.` key so generic lesson/game
/// checkpoint updates preserve it without mixing mission selection into player
/// progress or mastery evidence.
class MissionRunSessionCoordinator {
  const MissionRunSessionCoordinator({
    this.planner = const MissionRunPlanner(),
  });

  static const String sessionDataKey = '_session.missionRunPlan';

  final MissionRunPlanner planner;

  /// Creates or restores the capacity-aware allocation used by every Learning
  /// World family. Step 4 normally supplies a full 5 Training + 5 Game run for
  /// all Class 3-5 levels; the allocation policy still fails safe if a future
  /// content change reduces valid exact-tier capacity.
  MissionRunPlan createOrRestoreForWorldLevel({
    required ContentRepository repository,
    required LearningLevel level,
    GameSessionCheckpoint? checkpoint,
    MissionExposureHistory history = const MissionExposureHistory(),
    LearningProfileState? learningState,
    LearningLevelProgress? levelProgress,
    GameProgress? gameProgress,
    DateTime? now,
  }) {
    final profile = const MissionRunAllocationPolicy().forLevel(
      repository: repository,
      level: level,
      planner: planner,
    );
    final restored = restore(
      repository: repository,
      level: level,
      data: checkpoint?.data ?? const <String, Object?>{},
    );
    if (restored != null && _matchesProfile(restored, profile)) {
      return restored;
    }

    final selectionProfile = _adaptiveSelectionProfile(
      repository: repository,
      level: level,
      learningState: learningState,
      levelProgress: levelProgress,
      gameProgress: gameProgress,
      now: now,
    );
    final seed = seedForRun(
      level: level,
      startedAtIso: checkpoint?.startedAtIso,
      now: now,
    );
    return planner.planForLevel(
      repository: repository,
      level: level,
      request: MissionRunRequest(
        runSeed: seed,
        trainingItemCount: profile.trainingItemCount,
        gameItemCount: profile.gameItemCount,
        history: history,
        gameMechanics: profile.gameMechanics,
        selectionProfile: selectionProfile,
      ),
    );
  }

  MissionRunPlan createOrRestore({
    required ContentRepository repository,
    required LearningLevel level,
    required int trainingItemCount,
    required int gameItemCount,
    GameSessionCheckpoint? checkpoint,
    MissionExposureHistory history = const MissionExposureHistory(),
    DateTime? now,
  }) {
    final restored = restore(
      repository: repository,
      level: level,
      data: checkpoint?.data ?? const <String, Object?>{},
    );
    if (restored != null) return restored;

    final startedAt = checkpoint?.startedAtIso;
    final seed = seedForRun(
      level: level,
      startedAtIso: startedAt,
      now: now,
    );
    return planner.planForLevel(
      repository: repository,
      level: level,
      request: MissionRunRequest(
        runSeed: seed,
        trainingItemCount: trainingItemCount,
        gameItemCount: gameItemCount,
        history: history,
      ),
    );
  }

  MissionRunPlan? restore({
    required ContentRepository repository,
    required LearningLevel level,
    required Map<String, Object?> data,
  }) {
    final raw = data[sessionDataKey];
    if (raw is! Map) return null;
    try {
      final plan = MissionRunPlan.fromJson(Map<String, Object?>.from(raw));
      if (!_matchesLevel(plan, level) ||
          plan.hasTrainingGameOverlap ||
          plan.hasVisibleContentOverlap ||
          plan.hasInternalContentRepeat) {
        return null;
      }
      final currentCandidates = <String, MissionCandidate>{
        for (final candidate in planner.candidatesForLevel(
          repository: repository,
          level: level,
        ))
          candidate.stableKey: candidate,
      };
      for (final item in <PlannedMissionItem>[
        ...plan.trainingItems,
        ...plan.gameItems,
      ]) {
        final current = currentCandidates[item.candidate.stableKey];
        if (current == null ||
            current.contentFingerprint != item.candidate.contentFingerprint ||
            current.activityId != item.candidate.activityId) {
          return null;
        }
      }
      return plan;
    } catch (_) {
      // Corrupt/stale session metadata must never make the whole profile or
      // lesson checkpoint unreadable. The caller will create a fresh plan.
      return null;
    }
  }

  Map<String, Object?> sessionDataFor(MissionRunPlan plan) =>
      <String, Object?>{sessionDataKey: plan.toJson()};

  /// Creates a fresh replay plan while treating the just-played run as recent
  /// exposure. This prevents the replay button from simply rebuilding the same
  /// five Math Market questions when fresh exact-tier variants are available.
  MissionRunPlan createReplay({
    required ContentRepository repository,
    required LearningLevel level,
    required MissionRunPlan previousPlan,
    required int trainingItemCount,
    required int gameItemCount,
    MissionExposureHistory history = const MissionExposureHistory(),
    LearningProfileState? learningState,
    LearningLevelProgress? levelProgress,
    GameProgress? gameProgress,
    DateTime? now,
  }) {
    final recentItems = <PlannedMissionItem>[
      ...previousPlan.gameItems.reversed,
      ...previousPlan.trainingItems.reversed,
    ];
    final selectionProfile = _adaptiveSelectionProfile(
      repository: repository,
      level: level,
      learningState: learningState,
      levelProgress: levelProgress,
      gameProgress: gameProgress,
      now: now,
    );
    return planner.planForLevel(
      repository: repository,
      level: level,
      request: MissionRunRequest(
        runSeed: seedForRun(level: level, now: now),
        trainingItemCount: trainingItemCount,
        gameItemCount: gameItemCount,
        history: _mergeRecentHistory(recentItems, history),
        selectionProfile: selectionProfile,
      ),
    );
  }

  MissionRunPlan createWorldReplay({
    required ContentRepository repository,
    required LearningLevel level,
    required MissionRunPlan previousPlan,
    MissionExposureHistory history = const MissionExposureHistory(),
    LearningProfileState? learningState,
    LearningLevelProgress? levelProgress,
    GameProgress? gameProgress,
    DateTime? now,
  }) {
    final profile = const MissionRunAllocationPolicy().forLevel(
      repository: repository,
      level: level,
      planner: planner,
    );
    final recentItems = <PlannedMissionItem>[
      ...previousPlan.gameItems.reversed,
      ...previousPlan.trainingItems.reversed,
    ];
    final selectionProfile = _adaptiveSelectionProfile(
      repository: repository,
      level: level,
      learningState: learningState,
      levelProgress: levelProgress,
      gameProgress: gameProgress,
      now: now,
    );
    return planner.planForLevel(
      repository: repository,
      level: level,
      request: MissionRunRequest(
        runSeed: seedForRun(level: level, now: now),
        trainingItemCount: profile.trainingItemCount,
        gameItemCount: profile.gameItemCount,
        gameMechanics: profile.gameMechanics,
        history: _mergeRecentHistory(recentItems, history),
        selectionProfile: selectionProfile,
      ),
    );
  }

  AdaptiveMissionSelectionProfile _adaptiveSelectionProfile({
    required ContentRepository repository,
    required LearningLevel level,
    required LearningProfileState? learningState,
    required LearningLevelProgress? levelProgress,
    required GameProgress? gameProgress,
    DateTime? now,
  }) {
    if (learningState == null ||
        levelProgress == null ||
        gameProgress == null) {
      return AdaptiveMissionSelectionProfile.neutral;
    }
    final competencyIds = <String>{};
    for (final candidate
        in planner.candidatesForLevel(repository: repository, level: level)) {
      competencyIds.addAll(candidate.allCompetencyIds);
    }
    return const MissionVarietyIntelligence().forLevel(
      level: level,
      levelProgress: levelProgress,
      gameProgress: gameProgress,
      learningState: learningState,
      candidateCompetencyIds: competencyIds,
      now: now,
    );
  }

  MissionExposureHistory _mergeRecentHistory(
    List<PlannedMissionItem> currentRun,
    MissionExposureHistory persisted,
  ) {
    final activityKeys = <String>[
      ...currentRun.map((item) => item.candidate.stableKey),
      ...persisted.activityKeys,
    ];
    final contentFingerprints = <String>[
      ...currentRun.map((item) => item.candidate.contentFingerprint),
      ...persisted.contentFingerprints,
    ];
    final topicIds = <String>[
      ...currentRun.map((item) => item.candidate.topicId),
      ...persisted.topicIds,
    ];
    final competencyIds = <String>[
      ...currentRun.expand((item) => item.candidate.allCompetencyIds),
      ...persisted.competencyIds,
    ];
    final archetypeIds = <String>[
      ...currentRun.map((item) => item.candidate.archetypeId),
      ...persisted.archetypeIds,
    ];
    final mechanics = [
      ...currentRun.map((item) => item.candidate.mechanic),
      ...persisted.mechanics,
    ];
    return MissionExposureHistory(
      activityKeys: _dedupe(activityKeys),
      contentFingerprints: _dedupe(contentFingerprints),
      topicIds: _dedupe(topicIds),
      competencyIds: _dedupe(competencyIds),
      archetypeIds: _dedupe(archetypeIds),
      mechanics: _dedupe(mechanics),
    );
  }

  List<T> _dedupe<T>(Iterable<T> values) {
    final seen = <T>{};
    return <T>[
      for (final value in values)
        if (seen.add(value)) value,
    ];
  }

  int seedForRun({
    required LearningLevel level,
    String? startedAtIso,
    DateTime? now,
  }) {
    final source = startedAtIso?.trim().isNotEmpty == true
        ? startedAtIso!.trim()
        : (now ?? DateTime.now()).toUtc().toIso8601String();
    return _stableScore('${level.id}|$source');
  }

  bool _matchesProfile(
    MissionRunPlan plan,
    MissionRunAllocationProfile profile,
  ) =>
      !plan.hasContentShortfall &&
      plan.requestedTrainingItemCount == profile.trainingItemCount &&
      plan.requestedGameItemCount == profile.gameItemCount &&
      plan.gameItems.every(
        (item) => profile.allowsGameCandidate(item.candidate),
      );

  bool _matchesLevel(MissionRunPlan plan, LearningLevel level) =>
      plan.levelId == level.id &&
      plan.classNumber == level.classNumber &&
      plan.gameId == level.gameId &&
      plan.difficulty == level.difficulty;

  int _stableScore(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
