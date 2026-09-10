import 'dart:io';

import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/mission_exposure_memory.dart';
import 'package:brightquest_kids/core/learning/mission_run_session_coordinator.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/persistence/progress_store.dart';
import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:brightquest_kids/core/session/game_session_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/games/game_router.dart';
import 'package:brightquest_kids/features/learning/lesson_flow_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';
import 'support/content_fixture.dart';

void main() {
  const coordinator = MissionRunSessionCoordinator();

  group('Step 9 persistence and longevity hardening', () {
    test(
        'mission exposure nested schema fails closed and valid data is sanitized',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      final plan = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        now: DateTime.utc(2026, 8, 23, 15),
      );
      final memory = MissionExposureMemory();
      expect(
        memory.recordPlan(
          plan: plan,
          runId: 'release-run-1',
          seenAt: DateTime.utc(2026, 8, 23, 15, 1),
        ),
        isTrue,
      );

      final json = memory.toJson();
      final byClass = Map<String, Object?>.from(json['byClass']! as Map);
      final class4 = Map<String, Object?>.from(byClass['4']! as Map);
      final recent = List<Object?>.from(class4['recent']! as List);
      recent.insert(0, recent.first);
      final runIds = List<Object?>.from(class4['recordedRunIds']! as List);
      runIds.insert(0, runIds.first);
      class4['recent'] = recent;
      class4['recordedRunIds'] = runIds;
      byClass['4'] = class4;
      json['byClass'] = byClass;

      final restored = MissionExposureMemory.fromJson(json);
      final restoredClass = restored.byClass[4]!;
      expect(
        restoredClass.recent.map((item) => item.activityKey).toSet().length,
        restoredClass.recent.length,
      );
      expect(restoredClass.recordedRunIds.toSet().length,
          restoredClass.recordedRunIds.length);

      final unsupported = MissionExposureMemory.fromJson(<String, Object?>{
        'schemaVersion': 99,
        'byClass': byClass,
      });
      expect(unsupported.byClass, isEmpty);

      final snapshotJson = PlayerSnapshot().toJson();
      final profiles =
          Map<String, Object?>.from(snapshotJson['profiles']! as Map);
      final child = Map<String, Object?>.from(profiles['child-1']! as Map)
        ..['coins'] = 321
        ..['missionExposureMemory'] = <String, Object?>{
          'schemaVersion': 99,
          'byClass': byClass,
        };
      profiles['child-1'] = child;
      snapshotJson['profiles'] = profiles;
      final restoredSnapshot = PlayerSnapshot.fromJson(snapshotJson);
      expect(restoredSnapshot.schemaVersion, 6);
      expect(restoredSnapshot.activeProfile.coins, 321);
      expect(restoredSnapshot.activeProfile.missionExposureMemory.byClass,
          isEmpty);
    });

    test('long multi-class rotation remains bounded and selection-safe', () {
      final repository = buildContentRepository();
      final memory = MissionExposureMemory();
      var runSerial = 0;

      for (final classNumber in <int>[3, 4, 5]) {
        for (final level in levelsForClass(classNumber)) {
          for (var replay = 0; replay < 3; replay++) {
            final now = DateTime.utc(2026, 8, 1).add(
              Duration(minutes: runSerial),
            );
            final plan = coordinator.createOrRestoreForWorldLevel(
              repository: repository,
              level: level,
              history: memory.historyFor(
                classNumber: classNumber,
                gameId: level.gameId,
              ),
              now: now,
            );
            expect(plan.trainingItems, hasLength(5), reason: level.id);
            expect(plan.gameItems, hasLength(5), reason: level.id);
            expect(plan.hasTrainingGameOverlap, isFalse, reason: level.id);
            expect(plan.hasVisibleContentOverlap, isFalse, reason: level.id);
            expect(plan.hasInternalContentRepeat, isFalse, reason: level.id);
            expect(
              memory.recordPlan(
                plan: plan,
                runId: 'release-$classNumber-$runSerial',
                seenAt: now,
              ),
              isTrue,
            );
            runSerial += 1;
          }
        }

        final classMemory = memory.byClass[classNumber]!;
        expect(
          classMemory.recent.length,
          lessThanOrEqualTo(MissionExposureMemory.maxRecentItemsPerClass),
        );
        expect(
          classMemory.recordedRunIds,
          hasLength(MissionExposureMemory.maxRecordedRunIdsPerClass),
        );
        expect(
          classMemory.recent.every((item) => item.classNumber == classNumber),
          isTrue,
        );
      }

      expect(runSerial, 216);
      expect(memory.byClass.keys.toSet(), <int>{3, 4, 5});
    });

    test(
        'eight-game completion survives reload and replay reward is idempotent',
        () async {
      final repository = buildContentRepository();
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      controller.setClass(4);

      final practiceLevels = levelsForClass(4)
          .where((level) => level.difficulty == 1)
          .toList(growable: false);
      expect(practiceLevels, hasLength(8));

      for (var index = 0; index < practiceLevels.length; index++) {
        final level = practiceLevels[index];
        final plan = coordinator.createOrRestoreForWorldLevel(
          repository: repository,
          level: level,
          history: controller.missionExposureHistoryFor(level),
          now: DateTime.utc(2026, 8, 23, 16, index),
        );
        controller.beginLessonSession(
          level: level,
          totalSteps: 5,
          sessionData: coordinator.sessionDataFor(plan),
        );
        controller.transitionActiveSessionToGame(level: level);
        await controller.completeRunSafely(
          gameId: level.gameId,
          fallbackMissionId: 'release:${level.id}',
          score: 5,
          maxScore: 5,
          learningLevel: level,
        );
      }
      await controller.flushAll();

      final attemptsBefore = <String, int>{
        for (final level in practiceLevels)
          level.id: controller.levelStatsFor(level.id).attempts,
      };
      final coinsBefore = controller.coins;
      final xpBefore = controller.xp;

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      expect(restored.selectedClass, 4);
      expect(restored.allResumableGameSessionsForActiveProfile, hasLength(8));

      for (final level in practiceLevels) {
        expect(restored.missionExposureHistoryFor(level).activityKeys,
            hasLength(10));
        await restored.completeRunSafely(
          gameId: level.gameId,
          fallbackMissionId: 'release:${level.id}',
          score: 5,
          maxScore: 5,
          learningLevel: level,
        );
        expect(restored.levelStatsFor(level.id).attempts,
            attemptsBefore[level.id]);
      }
      expect(restored.coins, coinsBefore);
      expect(restored.xp, xpBefore);
    });
  });

  group('Step 9 explicit World replay safety', () {
    test('completed result remains resumable but is not an in-progress run',
        () {
      final checkpoint = GameSessionCheckpoint(
        profileId: 'child',
        classNumber: 4,
        gameId: 'math_market',
        learningLevelId: 'c4_math_operations:math_market:l1',
        difficulty: 1,
        stage: GameSessionStage.result,
        cursor: 4,
        score: 5,
        maxScore: 5,
        startedAtIso: DateTime.utc(2026, 8, 23).toIso8601String(),
        updatedAtIso: DateTime.utc(2026, 8, 23).toIso8601String(),
        reward: const GameSessionRewardSnapshot(
          firstCompletion: true,
          coinsAwarded: 10,
          xpAwarded: 20,
          starsAwarded: 3,
        ),
      );
      expect(checkpoint.isResumable, isTrue);
      expect(checkpoint.isInProgress, isFalse);
      expect(
        checkpoint.copyWith(stage: GameSessionStage.completing).isInProgress,
        isTrue,
      );
    });

    testWidgets('World re-entry after result starts a fresh lesson checkpoint',
        (tester) async {
      final controller = GameController();
      await controller.load();
      controller.setClass(4);
      controller.setReducedMotionEnabled(true);
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      controller.beginOrResumeGameSession(
        gameId: level.gameId,
        classNumber: level.classNumber,
        difficulty: level.difficulty,
        maxScore: 5,
        learningLevel: level,
      );
      await controller.completeRunSafely(
        gameId: level.gameId,
        fallbackMissionId: 'release:fresh-world',
        score: 5,
        maxScore: 5,
        learningLevel: level,
      );
      expect(
        controller
            .gameSessionFor(
              gameId: level.gameId,
              classNumber: level.classNumber,
              learningLevelId: level.id,
            )
            ?.stage,
        GameSessionStage.result,
      );

      await tester.pumpWidget(
        buildTestScope(
          controller: controller,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => openLearningLevel(context, level),
                  child: const Text('Open mission'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open mission'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonFlowScreen), findsOneWidget);
      expect(
        controller
            .gameSessionFor(
              gameId: level.gameId,
              classNumber: level.classNumber,
              learningLevelId: level.id,
            )
            ?.stage,
        GameSessionStage.lesson,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Step 9 release-contract guards', () {
    test('shipping-sensitive schemas and Windows crash isolation remain frozen',
        () {
      expect(PlayerSnapshot().schemaVersion, 6);
      expect(MissionExposureMemory.schemaVersion, 1);

      final registrant = File('windows/flutter/generated_plugin_registrant.cc')
          .readAsStringSync()
          .toLowerCase();
      final main = File('lib/main.dart').readAsStringSync();
      expect(registrant, isNot(contains('flutter_tts')));
      expect(main, contains('BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY'));
      expect(main, contains('ExcludeSemantics'));
    });

    test('Step 9 runner is fail-closed and includes the Step 8 scale audit',
        () {
      final runner = File('tool/qa/run_step9.ps1').readAsStringSync();
      expect(runner, contains(r"$ErrorActionPreference = 'Stop'"));
      expect(runner, contains(r'$LASTEXITCODE'));
      expect(runner, contains('STEP8_SEEDS=128'));
      expect(runner,
          contains('mission_run_step9_production_release_gate_test.dart'));
      expect(runner, contains('flutter analyze'));
      expect(runner, contains('flutter test'));
    });
  });
}
