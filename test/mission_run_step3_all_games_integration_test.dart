import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_models.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_models.dart';
import 'package:brightquest_kids/core/learning/lesson_engine.dart';
import 'package:brightquest_kids/core/learning/mission_run_allocation_policy.dart';
import 'package:brightquest_kids/core/learning/mission_run_game_content.dart';
import 'package:brightquest_kids/core/learning/mission_run_session_coordinator.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/games/coding_maze_screen.dart';
import 'package:brightquest_kids/features/games/fraction_pizza_screen.dart';
import 'package:brightquest_kids/features/games/grammar_puzzle_screen.dart';
import 'package:brightquest_kids/features/games/map_quest_screen.dart';
import 'package:brightquest_kids/features/games/recycling_challenge_screen.dart';
import 'package:brightquest_kids/features/games/science_lab_screen.dart';
import 'package:brightquest_kids/features/games/story_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';
import 'support/content_fixture.dart';

void main() {
  const coordinator = MissionRunSessionCoordinator();
  const allocationPolicy = MissionRunAllocationPolicy();
  const gameContent = MissionRunGameContent();

  group('Step 3 app-wide mission-run integration', () {
    test(
        'every Class 3-5 Learning World level gets a complete non-repeating allocation',
        () {
      final repository = buildContentRepository();

      expect(learningLevels, hasLength(72));
      for (final level in learningLevels) {
        final profile = allocationPolicy.forLevel(
          repository: repository,
          level: level,
        );
        final plan = coordinator.createOrRestoreForWorldLevel(
          repository: repository,
          level: level,
          now: DateTime.utc(
            2026,
            8,
            23,
            level.classNumber,
            level.difficulty,
          ),
        );

        expect(plan.hasContentShortfall, isFalse, reason: level.id);
        expect(plan.hasTrainingGameOverlap, isFalse, reason: level.id);
        expect(plan.hasVisibleContentOverlap, isFalse, reason: level.id);
        expect(plan.hasInternalContentRepeat, isFalse, reason: level.id);
        expect(
          plan.trainingItems,
          hasLength(profile.trainingItemCount),
          reason: level.id,
        );
        expect(
          plan.gameItems,
          hasLength(profile.gameItemCount),
          reason: level.id,
        );
        expect(plan.gameItems, isNotEmpty, reason: level.id);
        expect(
          [...plan.trainingItems, ...plan.gameItems].every(
            (item) =>
                item.candidate.classNumber == level.classNumber &&
                item.candidate.gameId == level.gameId &&
                item.candidate.difficulty == level.difficulty,
          ),
          isTrue,
          reason: level.id,
        );
        expect(
          plan.gameItems.every(
            (item) => profile.allowsGameCandidate(item.candidate),
          ),
          isTrue,
          reason: level.id,
        );
      }
    });

    test(
        'Step 4 generated pools lift every world level to a full 5 + 5 allocation',
        () {
      final repository = buildContentRepository();

      for (final level in learningLevels) {
        final profile = allocationPolicy.forLevel(
          repository: repository,
          level: level,
        );
        expect(profile.trainingItemCount, 5, reason: level.id);
        expect(profile.gameItemCount, 5, reason: level.id);
      }
    });

    test(
        'full Training pools map distinct planned activities into lesson phases',
        () {
      final repository = buildContentRepository();
      final level = learningLevels.firstWhere(
        (candidate) =>
            candidate.classNumber == 4 &&
            candidate.gameId == 'story_builder' &&
            candidate.difficulty == 2,
      );
      final plan = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        now: DateTime.utc(2026, 8, 23, 10, 0),
      );
      final flow = const LessonEngine().buildForLevel(
        repository: repository,
        level: level,
        missionRunPlan: plan,
      );
      const allocatableKinds = <LessonStepKind>{
        LessonStepKind.workedExample,
        LessonStepKind.guidedTry,
        LessonStepKind.independentPractice,
        LessonStepKind.transfer,
        LessonStepKind.exitTicket,
      };
      final activityIds = flow.steps
          .where((step) => allocatableKinds.contains(step.kind))
          .map((step) => step.activityId)
          .whereType<String>()
          .toList(growable: false);

      expect(plan.trainingItems, hasLength(5));
      expect(activityIds, hasLength(5));
      expect(
        activityIds,
        plan.trainingItems
            .map((item) => item.candidate.activityId)
            .toList(growable: false),
      );
      expect(
        activityIds.toSet().intersection(
              plan.gameItems.map((item) => item.candidate.activityId).toSet(),
            ),
        isEmpty,
      );
    });

    test('Science Lab reserves quiz-compatible decisions for the real game',
        () {
      final repository = buildContentRepository();
      final level = learningLevels.firstWhere(
        (candidate) =>
            candidate.classNumber == 4 &&
            candidate.gameId == 'science_lab' &&
            candidate.difficulty == 1,
      );
      final plan = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        now: DateTime.utc(2026, 8, 23, 10, 5),
      );

      expect(plan.trainingItems, hasLength(5));
      expect(
        plan.trainingItems.any(
          (item) => item.candidate.mechanic == LearningGameMechanic.simulation,
        ),
        isTrue,
      );
      expect(
        plan.gameItems.every(
          (item) => item.candidate.mechanic == LearningGameMechanic.decision,
        ),
        isTrue,
      );
      final questions = gameContent.scienceQuestions(
        repository: repository,
        plan: plan,
      );
      expect(questions, hasLength(5));
    });

    test(
        'typed game adapters preserve the planned legacy content order for all families',
        () {
      final repository = buildContentRepository();

      for (final level in learningLevels) {
        final plan = coordinator.createOrRestoreForWorldLevel(
          repository: repository,
          level: level,
          now: DateTime.utc(
            2026,
            8,
            23,
            11,
            level.classNumber,
            level.difficulty,
          ),
        );
        final expected = plan.gameItems
            .map((item) => item.candidate.legacyContentId)
            .toList(growable: false);
        final actual = switch (level.gameId) {
          'math_market' => gameContent
              .mathQuestions(repository: repository, plan: plan)
              .map((item) => item.id)
              .toList(),
          'fraction_pizza' => gameContent
              .fractionMissions(repository: repository, plan: plan)
              .map((item) => item.id)
              .toList(),
          'story_builder' => gameContent
              .storyMissions(repository: repository, plan: plan)
              .map((item) => item.id)
              .toList(),
          'grammar_puzzle' => gameContent
              .grammarMissions(repository: repository, plan: plan)
              .map((item) => item.id)
              .toList(),
          'science_lab' => gameContent
              .scienceQuestions(repository: repository, plan: plan)
              .map((item) => item.id)
              .toList(),
          'map_quest' => gameContent
              .mapQuestions(repository: repository, plan: plan)
              .map((item) => item.id)
              .toList(),
          'coding_maze' => gameContent
              .codingMissions(repository: repository, plan: plan)
              .map((item) => item.id)
              .toList(),
          'recycling_challenge' => gameContent
              .recyclingItems(repository: repository, plan: plan)
              .map((item) => item.id)
              .toList(),
          _ => <String>[],
        };

        expect(actual, expected, reason: level.id);
      }
    });

    test(
        'world replay keeps role constraints and does not introduce Training/Game overlap',
        () {
      final repository = buildContentRepository();
      final level = learningLevels.firstWhere(
        (candidate) =>
            candidate.classNumber == 5 &&
            candidate.gameId == 'grammar_puzzle' &&
            candidate.difficulty == 3,
      );
      final first = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        now: DateTime.utc(2026, 8, 23, 11, 10),
      );
      final replay = coordinator.createWorldReplay(
        repository: repository,
        level: level,
        previousPlan: first,
        now: DateTime.utc(2026, 8, 23, 11, 11),
      );

      expect(replay.hasContentShortfall, isFalse);
      expect(replay.hasTrainingGameOverlap, isFalse);
      expect(replay.hasVisibleContentOverlap, isFalse);
      expect(replay.hasInternalContentRepeat, isFalse);
      expect(replay.trainingItems, hasLength(first.trainingItems.length));
      expect(replay.gameItems, hasLength(first.gameItems.length));
    });

    testWidgets(
        'the seven Step 3 game screens render their persisted planned run length',
        (
      tester,
    ) async {
      final repository = buildContentRepository();
      const gameIds = <String>[
        'fraction_pizza',
        'story_builder',
        'grammar_puzzle',
        'science_lab',
        'map_quest',
        'coding_maze',
        'recycling_challenge',
      ];

      for (var index = 0; index < gameIds.length; index += 1) {
        final gameId = gameIds[index];
        final controller = GameController();
        await controller.load();
        controller.setClass(4);
        final level = learningLevels.firstWhere(
          (candidate) =>
              candidate.classNumber == 4 &&
              candidate.gameId == gameId &&
              candidate.difficulty == 2,
        );
        final plan = coordinator.createOrRestoreForWorldLevel(
          repository: repository,
          level: level,
          now: DateTime.utc(2026, 8, 23, 12, index),
        );
        controller.beginLessonSession(
          level: level,
          totalSteps: 7,
          sessionData: coordinator.sessionDataFor(plan),
        );
        controller.transitionActiveSessionToGame(level: level);

        await tester.pumpWidget(
          buildTestScope(
            controller: controller,
            contentRepository: repository,
            child: MaterialApp(home: _screenFor(level)),
          ),
        );
        await tester.pump();

        expect(
          find.text('Step 1 of ${plan.gameItems.length}'),
          findsOneWidget,
          reason: gameId,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}

Widget _screenFor(LearningLevel level) => switch (level.gameId) {
      'fraction_pizza' => FractionPizzaScreen(learningLevel: level),
      'story_builder' => StoryBuilderScreen(learningLevel: level),
      'grammar_puzzle' => GrammarPuzzleScreen(learningLevel: level),
      'science_lab' => ScienceLabScreen(learningLevel: level),
      'map_quest' => MapQuestScreen(learningLevel: level),
      'coding_maze' => CodingMazeScreen(learningLevel: level),
      'recycling_challenge' => RecyclingChallengeScreen(learningLevel: level),
      _ => throw StateError('Unsupported Step 3 game ${level.gameId}.'),
    };
