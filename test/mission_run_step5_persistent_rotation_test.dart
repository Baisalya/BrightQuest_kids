import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_models.dart';
import 'package:brightquest_kids/core/learning/mission_exposure_memory.dart';
import 'package:brightquest_kids/core/learning/mission_run_models.dart';
import 'package:brightquest_kids/core/learning/mission_run_planner.dart';
import 'package:brightquest_kids/core/learning/mission_run_session_coordinator.dart';
import 'package:brightquest_kids/core/learning/world_progression_policy.dart';
import 'package:brightquest_kids/core/models/game_models.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/persistence/progress_store.dart';
import 'package:brightquest_kids/core/session/game_session_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const coordinator = MissionRunSessionCoordinator();
  const planner = MissionRunPlanner();

  group('Step 5 persistent anti-repeat memory', () {
    test('memory is JSON-safe, class-isolated and bounded', () {
      final memory = MissionExposureMemory();
      for (var index = 0;
          index < MissionExposureMemory.maxRecentItemsPerClass + 20;
          index += 1) {
        final plan = _singleItemPlan(
          classNumber: 4,
          runSeed: index,
          activityId: 'activity-$index',
        );
        expect(
          memory.recordPlan(
            plan: plan,
            runId: 'run-$index',
            seenAt:
                DateTime.utc(2026, 8, 23, 10, 0).add(Duration(seconds: index)),
          ),
          isTrue,
        );
      }

      final restored = MissionExposureMemory.fromJson(memory.toJson());
      final class4 = restored.byClass[4]!;
      expect(
        class4.recent,
        hasLength(MissionExposureMemory.maxRecentItemsPerClass),
      );
      expect(
        class4.recordedRunIds,
        hasLength(MissionExposureMemory.maxRecordedRunIdsPerClass),
      );
      expect(restored.byClass[3], isNull);
      expect(restored.byClass[5], isNull);
      expect(
          restored
              .historyFor(classNumber: 3, gameId: 'math_market')
              .activityKeys,
          isEmpty);
      expect(
        restored.historyFor(classNumber: 4, gameId: 'math_market').activityKeys,
        isNotEmpty,
      );
    });

    test('recording the same run twice is idempotent', () {
      final memory = MissionExposureMemory();
      final plan = _singleItemPlan(
        classNumber: 4,
        runSeed: 44,
        activityId: 'same-activity',
      );
      final first = memory.recordPlan(
        plan: plan,
        runId: 'same-run',
        seenAt: DateTime.utc(2026, 8, 23, 10, 30),
      );
      final second = memory.recordPlan(
        plan: plan,
        runId: 'same-run',
        seenAt: DateTime.utc(2026, 8, 23, 10, 31),
      );

      expect(first, isTrue);
      expect(second, isFalse);
      expect(memory.byClass[4]!.recent, hasLength(1));
      expect(memory.byClass[4]!.recordedRunIds, ['same-run']);
    });

    test('persisted history makes the next run least-recently-seen', () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      final first = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        now: DateTime.utc(2026, 8, 23, 11),
      );
      final memory = MissionExposureMemory();
      memory.recordPlan(
        plan: first,
        runId: 'first-run',
        seenAt: DateTime.utc(2026, 8, 23, 11, 5),
      );
      final history = memory.historyFor(
        classNumber: level.classNumber,
        gameId: level.gameId,
      );
      final second = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        history: history,
        now: DateTime.utc(2026, 8, 23, 12),
      );

      final candidates = planner.candidatesForLevel(
        repository: repository,
        level: level,
      );
      final firstKeys = <String>{
        ...first.trainingActivityKeys,
        ...first.gameActivityKeys,
      };
      final secondKeys = <String>{
        ...second.trainingActivityKeys,
        ...second.gameActivityKeys,
      };
      final freshAvailable = candidates
          .where((candidate) => !firstKeys.contains(candidate.stableKey))
          .length;
      final expectedFresh = freshAvailable.clamp(0, secondKeys.length).toInt();
      final selectedFresh =
          secondKeys.where((key) => !firstKeys.contains(key)).length;

      expect(selectedFresh, expectedFresh);
      expect(second.hasTrainingGameOverlap, isFalse);
      expect(second.hasVisibleContentOverlap, isFalse);
    });

    test(
        'completed world run persists anti-repeat history across controller reload',
        () async {
      final repository = buildContentRepository();
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      final plan = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        history: controller.missionExposureHistoryFor(level),
        now: DateTime.utc(2026, 8, 23, 13),
      );
      controller.beginLessonSession(
        level: level,
        totalSteps: 5,
        sessionData: coordinator.sessionDataFor(plan),
      );
      controller.transitionActiveSessionToGame(level: level);
      await controller.completeRunSafely(
        gameId: level.gameId,
        fallbackMissionId: 'step5:${level.id}',
        score: 5,
        maxScore: 5,
        learningLevel: level,
      );
      await controller.flushAll();

      final beforeReload = controller.missionExposureHistoryFor(level);
      expect(beforeReload.activityKeys, hasLength(10));

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      final afterReload = restored.missionExposureHistoryFor(level);
      expect(afterReload.activityKeys, beforeReload.activityKeys);
      expect(afterReload.archetypeIds, beforeReload.archetypeIds);
      expect(afterReload.mechanics, beforeReload.mechanics);
    });

    test('new child profile starts with independent mission memory', () async {
      final repository = buildContentRepository();
      final controller = GameController();
      await controller.load();
      final originalProfileId = controller.activeProfileId;
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      final plan = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        now: DateTime.utc(2026, 8, 23, 14),
      );
      controller.beginLessonSession(
        level: level,
        totalSteps: 5,
        sessionData: coordinator.sessionDataFor(plan),
      );
      controller.transitionActiveSessionToGame(level: level);
      await controller.completeRunSafely(
        gameId: level.gameId,
        fallbackMissionId: 'profile:${level.id}',
        score: 5,
        maxScore: 5,
        learningLevel: level,
      );
      expect(
          controller.missionExposureHistoryFor(level).activityKeys, isNotEmpty);

      controller.createProfile(
        name: 'Second Explorer',
        classNumber: 4,
        avatarEmoji: '🧒',
      );
      expect(controller.missionExposureHistoryFor(level).activityKeys, isEmpty);

      expect(controller.switchProfile(originalProfileId), isTrue);
      expect(
          controller.missionExposureHistoryFor(level).activityKeys, isNotEmpty);
    });
  });

  group('Step 5 smarter World progression', () {
    test(
        'recommendation asks for fresh encounters without changing unlock rules',
        () async {
      final controller = GameController();
      await controller.load();
      final track = levelsForGame(4, 'math_market');
      final practice = track[0];
      final challenge = track[1];

      expect(controller.recommendedEncountersFor(practice), 2);
      expect(controller.recommendedEncountersFor(challenge), 2);
      expect(controller.recommendedEncountersFor(track[2]), 1);
      expect(
        controller.nextRecommendedWorldLevelForSubject(SubjectWorld.maths)?.id,
        practice.id,
      );

      controller.completeLearningLevel(
        level: practice,
        score: 4,
        maxScore: 4,
      );
      expect(controller.isLevelUnlocked(challenge), isTrue);
      expect(controller.completedRecommendedEncountersFor(practice), 1);
      expect(
        controller.nextRecommendedWorldLevelForSubject(SubjectWorld.maths)?.id,
        practice.id,
      );

      controller.completeLearningLevel(
        level: practice,
        score: 4,
        maxScore: 4,
      );
      expect(controller.completedRecommendedEncountersFor(practice), 2);
      expect(
        controller.nextRecommendedWorldLevelForSubject(SubjectWorld.maths)?.id,
        challenge.id,
      );
    });

    test('encounter progress is bounded by the recommendation target', () {
      const policy = WorldProgressionPolicy();
      final levels = levelsForGame(4, 'math_market');
      final progress = <String, LearningLevelProgress>{
        levels[0].id: LearningLevelProgress(completedRuns: 7),
        levels[1].id: LearningLevelProgress(completedRuns: 1),
        levels[2].id: LearningLevelProgress(completedRuns: 0),
      };
      final summary = policy.progressForLevels(
        levels: levels,
        progressFor: (id) => progress[id] ?? LearningLevelProgress(),
      );

      expect(summary.totalEncounters, 5);
      expect(summary.completedEncounters, 3);
      expect(summary.completionRatio, closeTo(0.6, 0.0001));
    });

    test('legacy profile JSON without mission memory remains readable', () {
      final snapshot = PlayerSnapshot.fromJson(<String, Object?>{
        'schemaVersion': 6,
        'activeProfileId': 'child-1',
        'profiles': <String, Object?>{
          'child-1': <String, Object?>{
            'id': 'child-1',
            'name': 'Explorer',
            'selectedClass': 4,
            'levelProgress': <String, Object?>{},
          },
        },
      });

      expect(snapshot.schemaVersion, 6);
      expect(snapshot.activeProfile.missionExposureMemory.byClass, isEmpty);
      expect(snapshot.toJson()['schemaVersion'], 6);
    });
  });
}

MissionRunPlan _singleItemPlan({
  required int classNumber,
  required int runSeed,
  required String activityId,
}) {
  final candidate = MissionCandidate(
    activityId: activityId,
    legacyContentId: activityId,
    classNumber: classNumber,
    gameId: 'math_market',
    topicId: 'topic',
    competencyId: 'competency',
    difficulty: 1,
    activityType: 'multipleChoice',
    responseRuleType: 'choice',
    source: MissionContentSource.generated,
    mechanic: LearningGameMechanic.decision,
    archetypeId: 'math_market:topic:decision',
    contentFingerprint: 'prompt-$activityId',
  );
  return MissionRunPlan(
    levelId: 'level-$classNumber',
    classNumber: classNumber,
    gameId: 'math_market',
    difficulty: 1,
    runSeed: runSeed,
    requestedTrainingItemCount: 0,
    requestedGameItemCount: 1,
    trainingItems: const <PlannedMissionItem>[],
    gameItems: <PlannedMissionItem>[
      PlannedMissionItem(
        candidate: candidate,
        role: MissionRunRole.game,
        position: 0,
      ),
    ],
    availableCandidateCount: 1,
  );
}
