import 'dart:convert';

import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/lesson_engine.dart';
import 'package:brightquest_kids/core/learning/mission_run_planner.dart';
import 'package:brightquest_kids/core/learning/mission_run_session_coordinator.dart';
import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/games/math_market_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';
import 'support/content_fixture.dart';

void main() {
  const planner = MissionRunPlanner();
  const coordinator = MissionRunSessionCoordinator();

  group('Step 2 mission allocation integration', () {
    test('every Class 3-5 Math World tier has a full 5 + 5 allocation', () {
      final repository = buildContentRepository();
      final mathLevels = learningLevels
          .where((level) => level.gameId == 'math_market')
          .toList(growable: false);

      expect(mathLevels, hasLength(9));
      for (final level in mathLevels) {
        final plan = coordinator.createOrRestore(
          repository: repository,
          level: level,
          trainingItemCount: 5,
          gameItemCount: 5,
          now:
              DateTime.utc(2026, 8, 23, 8, level.classNumber, level.difficulty),
        );

        expect(plan.hasContentShortfall, isFalse, reason: level.id);
        expect(plan.hasTrainingGameOverlap, isFalse, reason: level.id);
        expect(plan.hasVisibleContentOverlap, isFalse, reason: level.id);
        expect(plan.hasInternalContentRepeat, isFalse, reason: level.id);
        expect(plan.trainingItems, hasLength(5), reason: level.id);
        expect(plan.gameItems, hasLength(5), reason: level.id);
      }
    });

    test(
        'Math World can allocate five unique training and five unique game items',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l2')!;

      final plan = coordinator.createOrRestore(
        repository: repository,
        level: level,
        trainingItemCount: 5,
        gameItemCount: 5,
        now: DateTime.utc(2026, 8, 23, 9, 0),
      );

      expect(plan.trainingItems, hasLength(5));
      expect(plan.gameItems, hasLength(5));
      expect(plan.hasContentShortfall, isFalse);
      expect(plan.hasTrainingGameOverlap, isFalse);
      expect(plan.hasVisibleContentOverlap, isFalse);
      expect(plan.hasInternalContentRepeat, isFalse);
      expect(plan.trainingActivityKeys, hasLength(5));
      expect(plan.gameActivityKeys, hasLength(5));
      expect(
        <String>{...plan.trainingActivityKeys, ...plan.gameActivityKeys},
        hasLength(10),
      );
      expect(
        <String>{
          ...plan.trainingItems
              .map((item) => item.candidate.contentFingerprint),
          ...plan.gameItems.map((item) => item.candidate.contentFingerprint),
        },
        hasLength(10),
      );
      expect(
        [...plan.trainingItems, ...plan.gameItems].every(
          (item) =>
              item.candidate.classNumber == 4 &&
              item.candidate.gameId == 'math_market' &&
              item.candidate.difficulty == 2,
        ),
        isTrue,
      );
    });

    test('LessonEngine binds the five planned training items one-by-one', () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      final plan = coordinator.createOrRestore(
        repository: repository,
        level: level,
        trainingItemCount: 5,
        gameItemCount: 5,
        now: DateTime.utc(2026, 8, 23, 9, 5),
      );

      final flow = const LessonEngine().buildForLevel(
        repository: repository,
        level: level,
        missionRunPlan: plan,
      );
      const allocatedKinds = <LessonStepKind>{
        LessonStepKind.workedExample,
        LessonStepKind.guidedTry,
        LessonStepKind.independentPractice,
        LessonStepKind.transfer,
        LessonStepKind.exitTicket,
      };
      final allocatedSteps = flow.steps
          .where((step) => allocatedKinds.contains(step.kind))
          .toList(growable: false);
      final allocatedIds = allocatedSteps
          .map((step) => step.activityId)
          .whereType<String>()
          .toList(growable: false);
      final expectedTrainingIds = plan.trainingItems
          .take(5)
          .map((item) => item.candidate.activityId)
          .toList(growable: false);

      final topic = curriculumTopics.firstWhere(
        (candidate) => candidate.id == level.curriculumTopicId,
      );

      expect(flow.objective, topic.summary);
      expect(
        flow.steps
            .firstWhere((step) => step.kind == LessonStepKind.objective)
            .body,
        topic.summary,
      );
      expect(allocatedSteps, hasLength(5));
      expect(allocatedIds, expectedTrainingIds);
      expect(allocatedIds.toSet(), hasLength(5));
      expect(
        allocatedIds.toSet().intersection(
              plan.gameItems.map((item) => item.candidate.activityId).toSet(),
            ),
        isEmpty,
      );
      for (final activityId in allocatedIds) {
        expect(repository.activityById(activityId), isNotNull);
      }
    });

    test('mission framing preserves authored teaching roles', () {
      final repository = buildContentRepository();
      final level = learningLevelById('c3_math_operations:math_market:l1')!;
      const engine = LessonEngine();
      final base = engine.buildForLevel(
        repository: repository,
        level: level,
      );
      final plan = coordinator.createOrRestore(
        repository: repository,
        level: level,
        trainingItemCount: 5,
        gameItemCount: 5,
        now: DateTime.utc(2026, 9, 13, 10, 0),
      );
      final flow = engine.buildForLevel(
        repository: repository,
        level: level,
        missionRunPlan: plan,
      );
      final topic = curriculumTopics.firstWhere(
        (candidate) => candidate.id == level.curriculumTopicId,
      );
      final baseExplanation = base.steps.firstWhere(
        (step) => step.kind == LessonStepKind.explanation,
      );
      final objective = flow.steps.firstWhere(
        (step) => step.kind == LessonStepKind.objective,
      );
      final explanation = flow.steps.firstWhere(
        (step) => step.kind == LessonStepKind.explanation,
      );

      expect(flow.objective, topic.summary);
      expect(objective.body, topic.summary);
      expect(explanation.body, baseExplanation.body);
      expect(explanation.body, isNot(topic.summary));
      expect(explanation.body, isNot(objective.body));

      const allocatedKinds = <LessonStepKind>[
        LessonStepKind.workedExample,
        LessonStepKind.guidedTry,
        LessonStepKind.independentPractice,
        LessonStepKind.transfer,
        LessonStepKind.exitTicket,
      ];
      for (var index = 0; index < allocatedKinds.length; index += 1) {
        final activity = repository.activityById(
          plan.trainingItems[index].candidate.activityId,
        )!;
        final step = flow.steps.firstWhere(
          (candidate) => candidate.kind == allocatedKinds[index],
        );
        expect(step.activityId, activity.id);
        final expectedBody = switch (step.kind) {
          LessonStepKind.workedExample =>
            '${activity.prompt} ${activity.explanation}'.trim(),
          LessonStepKind.guidedTry ||
          LessonStepKind.independentPractice ||
          LessonStepKind.exitTicket =>
            activity.prompt,
          LessonStepKind.transfer =>
            'Solve this fresh mission without a clue, then explain why your method works: ${activity.prompt}',
          LessonStepKind.objective ||
          LessonStepKind.explanation ||
          LessonStepKind.reteach ||
          LessonStepKind.review =>
            throw StateError('Unexpected allocated teaching kind ${step.kind}.'),
        };
        expect(step.body, expectedBody);
      }
    });

    test('all Learning World missions keep framing separate from teaching', () {
      final repository = buildContentRepository();
      const engine = LessonEngine();

      for (final level in learningLevels) {
        final base = engine.buildForLevel(
          repository: repository,
          level: level,
        );
        final plan = coordinator.createOrRestoreForWorldLevel(
          repository: repository,
          level: level,
          now: DateTime.utc(2026, 9, 13, 10, 2),
        );
        final flow = engine.buildForLevel(
          repository: repository,
          level: level,
          missionRunPlan: plan,
        );
        final topic = curriculumTopics.firstWhere(
          (candidate) => candidate.id == level.curriculumTopicId,
        );
        final baseExplanation = base.steps.firstWhere(
          (step) => step.kind == LessonStepKind.explanation,
        );
        final explanation = flow.steps.firstWhere(
          (step) => step.kind == LessonStepKind.explanation,
        );

        expect(flow.objective, topic.summary, reason: level.id);
        expect(explanation.body, baseExplanation.body, reason: level.id);
        if (baseExplanation.body.trim() != topic.summary.trim()) {
          expect(explanation.body, isNot(topic.summary), reason: level.id);
        }
        expect(
          flow.steps.map((step) => step.kind).toList(growable: false),
          base.steps.map((step) => step.kind).toList(growable: false),
          reason: level.id,
        );
      }
    });

    test('reduced training allocation does not repeat the topic summary', () {
      final repository = buildContentRepository();
      final level = learningLevelById('c3_math_operations:math_market:l1')!;
      const engine = LessonEngine();
      final base = engine.buildForLevel(
        repository: repository,
        level: level,
      );
      final plan = coordinator.createOrRestore(
        repository: repository,
        level: level,
        trainingItemCount: 1,
        gameItemCount: 5,
        now: DateTime.utc(2026, 9, 13, 10, 5),
      );
      final flow = engine.buildForLevel(
        repository: repository,
        level: level,
        missionRunPlan: plan,
      );
      final topic = curriculumTopics.firstWhere(
        (candidate) => candidate.id == level.curriculumTopicId,
      );

      final objective = flow.steps.firstWhere(
        (step) => step.kind == LessonStepKind.objective,
      );
      final explanation = flow.steps.firstWhere(
        (step) => step.kind == LessonStepKind.explanation,
      );
      final baseExplanation = base.steps.firstWhere(
        (step) => step.kind == LessonStepKind.explanation,
      );
      final reteach = flow.steps.firstWhere(
        (step) => step.kind == LessonStepKind.reteach,
      );
      final baseReteach = base.steps.firstWhere(
        (step) => step.kind == LessonStepKind.reteach,
      );

      expect(objective.body, topic.summary);
      expect(explanation.body, baseExplanation.body);
      expect(reteach.body, baseReteach.body);
      expect(
        flow.steps
            .where(
              (step) =>
                  step.kind != LessonStepKind.objective &&
                  step.kind != LessonStepKind.review,
            )
            .where((step) => step.body == topic.summary),
        isEmpty,
      );

      expect(
        flow.steps
            .firstWhere((step) => step.kind == LessonStepKind.guidedTry)
            .body,
        'Explain one small example of this idea in your own words.',
      );
      expect(
        flow.steps
            .firstWhere(
              (step) => step.kind == LessonStepKind.independentPractice,
            )
            .body,
        'Use the idea independently on a fresh example.',
      );
      expect(
        flow.steps
            .firstWhere((step) => step.kind == LessonStepKind.transfer)
            .body,
        'Tell where this idea could be useful outside this lesson.',
      );
      expect(
        flow.steps
            .firstWhere((step) => step.kind == LessonStepKind.exitTicket)
            .body,
        'Finish one independent check without a clue.',
      );
    });

    test('serialized plan restores after a session JSON round trip', () {
      final repository = buildContentRepository();
      final level = learningLevelById('c5_math_operations:math_market:l3')!;
      final plan = coordinator.createOrRestore(
        repository: repository,
        level: level,
        trainingItemCount: 5,
        gameItemCount: 5,
        now: DateTime.utc(2026, 8, 23, 9, 10),
      );
      final persistedData = Map<String, Object?>.from(
        jsonDecode(jsonEncode(coordinator.sessionDataFor(plan))) as Map,
      );
      final checkpoint = GameSessionCheckpoint(
        profileId: 'child-1',
        classNumber: level.classNumber,
        gameId: level.gameId,
        learningLevelId: level.id,
        difficulty: level.difficulty,
        stage: GameSessionStage.lesson,
        cursor: 2,
        score: 0,
        maxScore: 7,
        startedAtIso: '2026-08-23T09:10:00.000Z',
        updatedAtIso: '2026-08-23T09:11:00.000Z',
        data: persistedData,
      );

      final restored = coordinator.createOrRestore(
        repository: repository,
        level: level,
        trainingItemCount: 5,
        gameItemCount: 5,
        checkpoint: checkpoint,
        now: DateTime.utc(2030),
      );

      expect(restored.runSeed, plan.runSeed);
      expect(
        restored.trainingItems.map((item) => item.candidate.stableKey).toList(),
        plan.trainingItems.map((item) => item.candidate.stableKey).toList(),
      );
      expect(
        restored.gameItems.map((item) => item.candidate.stableKey).toList(),
        plan.gameItems.map((item) => item.candidate.stableKey).toList(),
      );
    });

    test(
        'session plan survives lesson checkpoint and lesson-to-game transition',
        () async {
      final repository = buildContentRepository();
      final controller = GameController();
      await controller.load();
      controller.setClass(4);
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      final plan = coordinator.createOrRestore(
        repository: repository,
        level: level,
        trainingItemCount: 5,
        gameItemCount: 5,
        now: DateTime.utc(2026, 8, 23, 9, 15),
      );

      controller.beginLessonSession(
        level: level,
        totalSteps: 7,
        sessionData: coordinator.sessionDataFor(plan),
      );
      controller.checkpointLessonSession(
        level: level,
        stepIndex: 3,
        totalSteps: 7,
        completedInteractiveStepIds: const <String>{'guided'},
        shownHintIndices: const <int>{0},
      );
      expect(
        controller
            .gameSessionFor(
              gameId: level.gameId,
              classNumber: level.classNumber,
              learningLevelId: level.id,
            )
            ?.data[MissionRunSessionCoordinator.sessionDataKey],
        isNotNull,
      );

      controller.transitionActiveSessionToGame(level: level);
      final gameSession = controller.gameSessionFor(
        gameId: level.gameId,
        classNumber: level.classNumber,
        learningLevelId: level.id,
      )!;
      expect(gameSession.stage, GameSessionStage.game);
      final restored = coordinator.restore(
        repository: repository,
        level: level,
        data: gameSession.data,
      );
      expect(restored, isNotNull);
      expect(restored!.runSeed, plan.runSeed);

      controller.checkpointGameSession(
        gameId: level.gameId,
        classNumber: level.classNumber,
        difficulty: level.difficulty,
        cursor: 1,
        score: 1,
        maxScore: 5,
        learningLevel: level,
        data: const <String, Object?>{'selected': 42},
      );
      final afterGameCheckpoint = controller.gameSessionFor(
        gameId: level.gameId,
        classNumber: level.classNumber,
        learningLevelId: level.id,
      )!;
      expect(
        afterGameCheckpoint.data[MissionRunSessionCoordinator.sessionDataKey],
        isNotNull,
      );
      expect(afterGameCheckpoint.data['selected'], 42);
    });

    test(
        'canonical generated activity ids rehydrate beyond the legacy four seeds',
        () {
      final repository = buildContentRepository();
      final generated = repository.activityForLegacyContent(
        classNumber: 4,
        gameId: 'math_market',
        legacyContentId: 'gen_math_c4_d2_s11',
      );

      expect(generated, isNotNull);
      expect(generated!.id, 'c4_generated_math_d2_s11');
      final rehydrated = repository.activityById(generated.id);
      expect(rehydrated, isNotNull);
      expect(rehydrated!.legacyContentId, generated.legacyContentId);
      expect(rehydrated.payload['answer'], generated.payload['answer']);
    });

    testWidgets(
        'Math Market renders the persisted game allocation, not the legacy cumulative list',
        (
      tester,
    ) async {
      final repository = buildContentRepository();
      final controller = GameController();
      await controller.load();
      controller.setClass(4);
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      final plan = coordinator.createOrRestore(
        repository: repository,
        level: level,
        trainingItemCount: 5,
        gameItemCount: 5,
        now: DateTime.utc(2026, 8, 23, 9, 20),
      );
      controller.beginLessonSession(
        level: level,
        totalSteps: 7,
        sessionData: coordinator.sessionDataFor(plan),
      );
      controller.transitionActiveSessionToGame(level: level);
      final firstActivity = planner.resolveCandidateActivity(
        repository: repository,
        candidate: plan.gameItems.first.candidate,
      );

      await tester.pumpWidget(
        buildTestScope(
          controller: controller,
          contentRepository: repository,
          child: MaterialApp(
            home: MathMarketScreen(learningLevel: level),
          ),
        ),
      );
      await tester.pump();

      final boardPrompt = tester.widget<Text>(
        find.byKey(const Key('math_market_question_prompt')),
      );
      expect(boardPrompt.data, firstActivity.prompt);
      expect(find.text('Step 1 of 5'), findsOneWidget);
    });
  });
}
