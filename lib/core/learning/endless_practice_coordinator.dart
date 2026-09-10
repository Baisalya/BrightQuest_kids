import '../content/content_repository.dart';
import '../curriculum/curriculum_catalog.dart';
import '../curriculum/curriculum_models.dart';
import '../models/progress_models.dart';
import '../session/game_session_models.dart';
import 'learning_models.dart';
import 'mission_run_models.dart';
import 'mission_run_planner.dart';
import 'mission_run_session_coordinator.dart';
import 'mission_variety_intelligence.dart';
import 'mission_variety_models.dart';

/// Post-progression practice orchestration for the eight generated game
/// families. Endless Practice is deliberately not a [LearningLevel], so the
/// canonical 3-level progression and reward/unlock contract stay unchanged.
class EndlessPracticeCoordinator {
  const EndlessPracticeCoordinator({
    this.planner = const MissionRunPlanner(),
  });

  static const int itemsPerRound = 10;
  static const String levelIdPrefix = 'endless:c';

  final MissionRunPlanner planner;

  static bool isEndlessPlan(MissionRunPlan plan) =>
      plan.levelId == 'endless:c${plan.classNumber}:${plan.gameId}' &&
      plan.trainingItems.isEmpty &&
      plan.requestedTrainingItemCount == 0;

  static bool isEndlessSessionData(Map<String, Object?> data) {
    final raw = data[MissionRunSessionCoordinator.sessionDataKey];
    if (raw is! Map) return false;
    try {
      return isEndlessPlan(
        MissionRunPlan.fromJson(Map<String, Object?>.from(raw)),
      );
    } catch (_) {
      return false;
    }
  }

  MissionRunPlan createOrRestore({
    required ContentRepository repository,
    required int classNumber,
    required String gameId,
    GameSessionCheckpoint? checkpoint,
    MissionExposureHistory history = const MissionExposureHistory(),
    LearningProfileState? learningState,
    GameProgress? gameProgress,
    DateTime? now,
  }) {
    final restored = restore(
      repository: repository,
      classNumber: classNumber,
      gameId: gameId,
      data: checkpoint?.data ?? const <String, Object?>{},
    );
    if (restored != null && !restored.hasContentShortfall) return restored;

    final seed = _seedForRun(
      classNumber: classNumber,
      gameId: gameId,
      startedAtIso: checkpoint?.startedAtIso,
      now: now,
    );
    return _create(
      repository: repository,
      classNumber: classNumber,
      gameId: gameId,
      runSeed: seed,
      history: history,
      learningState: learningState,
      gameProgress: gameProgress,
      now: now,
    );
  }

  MissionRunPlan createNextRound({
    required ContentRepository repository,
    required MissionRunPlan previousPlan,
    MissionExposureHistory history = const MissionExposureHistory(),
    LearningProfileState? learningState,
    GameProgress? gameProgress,
    DateTime? now,
  }) {
    if (!isEndlessPlan(previousPlan)) {
      throw StateError('Cannot continue a non-endless mission plan.');
    }
    final recent = <PlannedMissionItem>[...previousPlan.gameItems.reversed];
    final mergedHistory = MissionExposureHistory(
      activityKeys: _dedupe(<String>[
        ...recent.map((item) => item.candidate.stableKey),
        ...history.activityKeys,
      ]),
      contentFingerprints: _dedupe(<String>[
        ...recent.map((item) => item.candidate.contentFingerprint),
        ...history.contentFingerprints,
      ]),
      topicIds: _dedupe(<String>[
        ...recent.map((item) => item.candidate.topicId),
        ...history.topicIds,
      ]),
      competencyIds: _dedupe(<String>[
        ...recent.expand((item) => item.candidate.allCompetencyIds),
        ...history.competencyIds,
      ]),
      archetypeIds: _dedupe(<String>[
        ...recent.map((item) => item.candidate.archetypeId),
        ...history.archetypeIds,
      ]),
      mechanics: _dedupe([
        ...recent.map((item) => item.candidate.mechanic),
        ...history.mechanics,
      ]),
    );
    final timestamp = now ?? DateTime.now();
    final nextSeed = _stableScore(
      '${previousPlan.levelId}|${previousPlan.runSeed}|${timestamp.toUtc().toIso8601String()}',
    );
    return _create(
      repository: repository,
      classNumber: previousPlan.classNumber,
      gameId: previousPlan.gameId,
      runSeed: nextSeed,
      history: mergedHistory,
      learningState: learningState,
      gameProgress: gameProgress,
      now: timestamp,
    );
  }

  MissionRunPlan? restore({
    required ContentRepository repository,
    required int classNumber,
    required String gameId,
    required Map<String, Object?> data,
  }) {
    final raw = data[MissionRunSessionCoordinator.sessionDataKey];
    if (raw is! Map) return null;
    try {
      final plan = MissionRunPlan.fromJson(Map<String, Object?>.from(raw));
      if (!isEndlessPlan(plan) ||
          plan.classNumber != classNumber ||
          plan.gameId != gameId ||
          plan.difficulty < 1 ||
          plan.difficulty > 3 ||
          plan.gameItems.isEmpty ||
          plan.gameItems.length != itemsPerRound ||
          plan.hasInternalContentRepeat ||
          plan.hasVisibleContentOverlap) {
        return null;
      }
      for (final item in plan.gameItems) {
        final resolved = planner.resolveCandidateActivity(
          repository: repository,
          candidate: item.candidate,
        );
        if (resolved.id != item.candidate.activityId ||
            resolved.legacyContentId != item.candidate.legacyContentId) {
          return null;
        }
      }
      return plan;
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> sessionDataFor(MissionRunPlan plan) {
    if (!isEndlessPlan(plan)) {
      throw StateError('Expected an Endless Practice mission plan.');
    }
    return const MissionRunSessionCoordinator().sessionDataFor(plan);
  }

  MissionRunPlan _create({
    required ContentRepository repository,
    required int classNumber,
    required String gameId,
    required int runSeed,
    required MissionExposureHistory history,
    required LearningProfileState? learningState,
    required GameProgress? gameProgress,
    DateTime? now,
  }) {
    const maxDifficulty = 3;
    var selectionProfile = AdaptiveMissionSelectionProfile.neutral;
    if (learningState != null && gameProgress != null) {
      final sourceLevels = levelsForGame(classNumber, gameId);
      if (sourceLevels.isNotEmpty) {
        final source = sourceLevels.last;
        final synthetic = LearningLevel(
          id: 'endless:c$classNumber:$gameId',
          classNumber: classNumber,
          subject: source.subject,
          gameId: gameId,
          curriculumTopicId: source.curriculumTopicId,
          title: 'Endless Practice',
          summary: 'Fresh mixed practice after the main mission path.',
          order: source.order + 1,
          difficulty: maxDifficulty,
          type: LearningLevelType.practice,
        );
        final candidates = planner.candidatesForEndlessPractice(
          repository: repository,
          classNumber: classNumber,
          gameId: gameId,
          maxDifficulty: maxDifficulty,
          runSeed: runSeed,
        );
        final competencies = <String>{
          for (final candidate in candidates) ...candidate.allCompetencyIds,
        };
        selectionProfile = const MissionVarietyIntelligence().forLevel(
          level: synthetic,
          levelProgress: LearningLevelProgress(),
          gameProgress: gameProgress,
          learningState: learningState,
          candidateCompetencyIds: competencies,
          now: now,
        );
      }
    }

    final plan = planner.planEndlessPractice(
      repository: repository,
      classNumber: classNumber,
      gameId: gameId,
      maxDifficulty: maxDifficulty,
      request: MissionRunRequest(
        runSeed: runSeed,
        trainingItemCount: 0,
        gameItemCount: itemsPerRound,
        history: history,
        selectionProfile: selectionProfile,
      ),
    );
    if (plan.gameItems.length != itemsPerRound ||
        plan.hasInternalContentRepeat ||
        plan.hasContentShortfall) {
      throw StateError(
        'Endless Practice could not allocate $itemsPerRound safe missions for $gameId.',
      );
    }
    return plan;
  }

  int _seedForRun({
    required int classNumber,
    required String gameId,
    String? startedAtIso,
    DateTime? now,
  }) {
    final source = startedAtIso?.trim().isNotEmpty == true
        ? startedAtIso!.trim()
        : (now ?? DateTime.now()).toUtc().toIso8601String();
    return _stableScore('endless:c$classNumber:$gameId|$source');
  }

  List<T> _dedupe<T>(Iterable<T> values) {
    final seen = <T>{};
    return <T>[
      for (final value in values)
        if (seen.add(value)) value,
    ];
  }

  int _stableScore(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
