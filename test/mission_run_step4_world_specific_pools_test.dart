import 'dart:collection';

import 'package:brightquest_kids/core/content/content_activity.dart';
import 'package:brightquest_kids/core/content/content_repository.dart';
import 'package:brightquest_kids/core/content/game_content.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_models.dart';
import 'package:brightquest_kids/core/gameplay/game_logic.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_resolver.dart';
import 'package:brightquest_kids/core/learning/mission_run_allocation_policy.dart';
import 'package:brightquest_kids/core/learning/mission_run_session_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const generatedFamilies = <String>[
    'story_builder',
    'science_lab',
    'coding_maze',
    'recycling_challenge',
  ];
  const allGeneratedFamilies = <String>[
    'math_market',
    'fraction_pizza',
    'story_builder',
    'grammar_puzzle',
    'science_lab',
    'map_quest',
    'coding_maze',
    'recycling_challenge',
  ];

  group('Step 4 world-specific mission pools', () {
    test(
        'every Class 3-5 world level now has a complete 5 Training + 5 Game run',
        () {
      final repository = buildContentRepository();
      const allocation = MissionRunAllocationPolicy();
      const coordinator = MissionRunSessionCoordinator();

      expect(learningLevels, hasLength(72));
      for (final level in learningLevels) {
        final profile = allocation.forLevel(
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
            14,
            level.classNumber * 10 + level.difficulty,
          ),
        );

        expect(profile.trainingItemCount, 5, reason: level.id);
        expect(profile.gameItemCount, 5, reason: level.id);
        expect(plan.trainingItems, hasLength(5), reason: level.id);
        expect(plan.gameItems, hasLength(5), reason: level.id);
        expect(plan.hasContentShortfall, isFalse, reason: level.id);
        expect(plan.hasTrainingGameOverlap, isFalse, reason: level.id);
        expect(plan.hasVisibleContentOverlap, isFalse, reason: level.id);
        expect(plan.hasInternalContentRepeat, isFalse, reason: level.id);
      }
    });

    test(
        'thin Step 3 families now expose twelve unique exact-tier generated missions',
        () {
      final repository = buildContentRepository();
      const resolver = GameplayActivityResolver();

      for (final classNumber in const <int>[3, 4, 5]) {
        for (final difficulty in const <int>[1, 2, 3]) {
          for (final gameId in generatedFamilies) {
            final activities =
                repository.generatedPracticeActivitiesForGameAtExactDifficulty(
              classNumber,
              gameId,
              difficulty: difficulty,
            );

            expect(
              activities,
              hasLength(ContentRepository.generatedPracticeVariantsPerFamily),
              reason: 'Class $classNumber $gameId d$difficulty',
            );
            expect(
              activities.map((item) => item.prompt).toSet(),
              hasLength(ContentRepository.generatedPracticeVariantsPerFamily),
              reason:
                  'visible uniqueness Class $classNumber $gameId d$difficulty',
            );

            for (final activity in activities) {
              expect(activity.classNumber, classNumber, reason: activity.id);
              expect(activity.gameId, gameId, reason: activity.id);
              expect(activity.difficulty, difficulty, reason: activity.id);
              expect(activity.generation.mode, 'generated',
                  reason: activity.id);
              expect(activity.status, 'needsReview', reason: activity.id);
              expect(resolver.resolve(activity).isSupported, isTrue,
                  reason: activity.id);

              final byId = repository.activityById(activity.id);
              final byLegacy = repository.activityForLegacyContent(
                classNumber: classNumber,
                gameId: gameId,
                legacyContentId: activity.legacyContentId,
              );
              expect(byId?.prompt, activity.prompt, reason: activity.id);
              expect(byLegacy?.prompt, activity.prompt, reason: activity.id);

              _expectFamilyPayloadValid(activity);
            }
          }
        }
      }
    });

    test(
        'same seed produces class-specific missions instead of copied Class 3 content',
        () {
      final repository = buildContentRepository();

      for (final gameId in allGeneratedFamilies) {
        for (final difficulty in const <int>[1, 2, 3]) {
          for (var seed = 0; seed < 12; seed += 1) {
            final signatures = <String>{};
            for (final classNumber in const <int>[3, 4, 5]) {
              final activity = repository.activityForLegacyContent(
                classNumber: classNumber,
                gameId: gameId,
                legacyContentId:
                    'gen_${_familyName(gameId)}_c${classNumber}_d${difficulty}_s$seed',
              );
              expect(activity, isNotNull);
              signatures.add(_missionSignature(activity!));
            }
            expect(
              signatures,
              hasLength(3),
              reason: '$gameId d$difficulty seed $seed must differ by class',
            );
          }
        }
      }
    });

    test(
        'planner archetypes include topic mission families and rotate multi-topic worlds',
        () {
      final repository = buildContentRepository();
      const coordinator = MissionRunSessionCoordinator();

      final story = learningLevels.firstWhere(
        (level) =>
            level.classNumber == 5 &&
            level.gameId == 'story_builder' &&
            level.difficulty == 2,
      );
      final science = learningLevels.firstWhere(
        (level) =>
            level.classNumber == 4 &&
            level.gameId == 'science_lab' &&
            level.difficulty == 3,
      );

      for (final level in <LearningLevel>[story, science]) {
        final plan = coordinator.createOrRestoreForWorldLevel(
          repository: repository,
          level: level,
          now: DateTime.utc(2026, 8, 23, 15, level.difficulty),
        );
        final items = [...plan.trainingItems, ...plan.gameItems];
        expect(
          items.every(
            (item) => item.candidate.archetypeId.contains(
              ':${item.candidate.topicId}:',
            ),
          ),
          isTrue,
          reason: level.id,
        );
        expect(
          items.map((item) => item.candidate.topicId).toSet().length,
          greaterThan(1),
          reason: '${level.id} should rotate conceptual mission families',
        );
      }
    });

    test('all generated Coding Maze boards have a valid route within budget',
        () {
      final repository = buildContentRepository();

      for (final classNumber in const <int>[3, 4, 5]) {
        for (final difficulty in const <int>[1, 2, 3]) {
          final activities =
              repository.generatedPracticeActivitiesForGameAtExactDifficulty(
            classNumber,
            'coding_maze',
            difficulty: difficulty,
          );
          for (final activity in activities) {
            final mission = _codingMission(activity);
            final route = _findRoute(mission);
            expect(route, isNotNull, reason: activity.id);
            expect(route!.length, lessThanOrEqualTo(mission.maxCommands));
            expect(runCodingMission(mission, route).success, isTrue);
          }
        }
      }
    });

    test(
        'fraction exact-tier generator no longer collapses Class 3 Challenge capacity',
        () {
      final repository = buildContentRepository();
      final level = learningLevels.firstWhere(
        (candidate) =>
            candidate.classNumber == 3 &&
            candidate.gameId == 'fraction_pizza' &&
            candidate.difficulty == 2,
      );
      final generated =
          repository.generatedPracticeActivitiesForGameAtExactDifficulty(
        3,
        'fraction_pizza',
        difficulty: 2,
      );
      final profile = const MissionRunAllocationPolicy().forLevel(
        repository: repository,
        level: level,
      );

      expect(generated.map((item) => item.prompt).toSet(), hasLength(12));
      expect(profile.trainingItemCount, 5);
      expect(profile.gameItemCount, 5);
    });
  });
}

void _expectFamilyPayloadValid(ContentActivity activity) {
  switch (activity.gameId) {
    case 'story_builder':
      final words = List<String>.from(activity.payload['words'] as List);
      expect(words, isNotEmpty, reason: activity.id);
      expect(activity.correctResponseRule['type'], 'orderedWords');
      expect(
        List<String>.from(activity.correctResponseRule['value'] as List),
        words,
        reason: activity.id,
      );
      break;
    case 'science_lab':
      final answer = activity.payload['answer'] as String;
      final choices = List<String>.from(activity.payload['choices'] as List);
      expect(choices.toSet(), hasLength(choices.length), reason: activity.id);
      expect(choices.where((value) => value == answer), hasLength(1));
      expect(activity.correctResponseRule['value'], answer);
      break;
    case 'coding_maze':
      expect(activity.correctResponseRule['type'], 'reachGridGoal');
      expect(activity.payload['width'], isA<int>());
      expect(activity.payload['height'], isA<int>());
      expect(activity.payload['obstacles'], isA<List>());
      break;
    case 'recycling_challenge':
      final bin = activity.payload['bin'] as String;
      expect(const <String>{'Paper', 'Plastic', 'Organic'}, contains(bin));
      expect(activity.correctResponseRule['value'], bin);
      break;
  }
}

String _familyName(String gameId) => switch (gameId) {
      'math_market' => 'math',
      'fraction_pizza' => 'fraction',
      'story_builder' => 'story',
      'grammar_puzzle' => 'grammar',
      'science_lab' => 'science',
      'map_quest' => 'map',
      'coding_maze' => 'coding',
      'recycling_challenge' => 'recycling',
      _ => throw StateError('Unsupported generated family $gameId'),
    };

String _missionSignature(ContentActivity activity) {
  if (activity.gameId == 'coding_maze') {
    final obstacles = List<String>.from(activity.payload['obstacles'] as List)
      ..sort();
    return <Object?>[
      activity.prompt,
      activity.payload['width'],
      activity.payload['height'],
      activity.payload['startX'],
      activity.payload['startY'],
      activity.payload['goalX'],
      activity.payload['goalY'],
      activity.payload['startDirection'],
      obstacles.join(';'),
      activity.payload['maxCommands'],
    ].join('|');
  }
  return activity.prompt;
}

CodingMission _codingMission(ContentActivity activity) {
  final payload = activity.payload;
  return CodingMission(
    id: activity.legacyContentId,
    width: payload['width'] as int,
    height: payload['height'] as int,
    startX: payload['startX'] as int,
    startY: payload['startY'] as int,
    goalX: payload['goalX'] as int,
    goalY: payload['goalY'] as int,
    startDirection: FacingDirection.values.firstWhere(
      (value) => value.name == payload['startDirection'],
    ),
    obstacles: Set<String>.from(payload['obstacles'] as List),
    maxCommands: payload['maxCommands'] as int,
    topicId: activity.topicId,
    difficulty: activity.difficulty,
  );
}

List<CodingCommand>? _findRoute(CodingMission mission) {
  final queue = Queue<List<CodingCommand>>()..add(const <CodingCommand>[]);
  final seen = <String>{
    '${mission.startX},${mission.startY},${mission.startDirection.name}',
  };

  while (queue.isNotEmpty) {
    final path = queue.removeFirst();
    final result = runCodingMission(mission, path);
    if (result.success) return path;
    if (!result.valid || path.length >= mission.maxCommands) continue;

    for (final command in const <CodingCommand>[
      CodingCommand.move,
      CodingCommand.turnLeft,
      CodingCommand.turnRight,
    ]) {
      final next = <CodingCommand>[...path, command];
      final nextResult = runCodingMission(mission, next);
      if (!nextResult.valid) continue;
      final direction = _directionAfter(mission.startDirection, next);
      final key = '${nextResult.finalX},${nextResult.finalY},${direction.name}';
      if (seen.add(key)) queue.add(next);
    }
  }
  return null;
}

FacingDirection _directionAfter(
  FacingDirection start,
  List<CodingCommand> commands,
) {
  var direction = start;
  CodingCommand? previous;
  for (final command in commands) {
    final effective = command == CodingCommand.repeatLast ? previous : command;
    if (effective == null) continue;
    if (effective == CodingCommand.turnLeft) direction = direction.turnLeft;
    if (effective == CodingCommand.turnRight) direction = direction.turnRight;
    if (effective != CodingCommand.repeatLast) previous = effective;
  }
  return direction;
}
