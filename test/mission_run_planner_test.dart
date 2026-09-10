import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/mission_run_models.dart';
import 'package:brightquest_kids/core/learning/mission_run_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const planner = MissionRunPlanner();

  group('MissionRunPlanner foundation', () {
    test('every Learning World candidate stays in its exact class/game/tier',
        () {
      final repository = buildContentRepository();

      for (final level in learningLevels) {
        final candidates = planner.candidatesForLevel(
          repository: repository,
          level: level,
        );

        expect(candidates, isNotEmpty, reason: level.id);
        for (final candidate in candidates) {
          expect(candidate.classNumber, level.classNumber, reason: level.id);
          expect(candidate.gameId, level.gameId, reason: level.id);
          expect(candidate.difficulty, level.difficulty, reason: level.id);
        }
      }
    });

    test('Challenge and Mastery do not inherit lower-difficulty activities',
        () {
      final repository = buildContentRepository();
      final challenge = learningLevelById(
        'c4_math_operations:math_market:l2',
      )!;
      final mastery = learningLevelById(
        'c4_math_operations:math_market:l3',
      )!;

      final challengeCandidates = planner.candidatesForLevel(
        repository: repository,
        level: challenge,
      );
      final masteryCandidates = planner.candidatesForLevel(
        repository: repository,
        level: mastery,
      );

      expect(
        challengeCandidates.every((candidate) => candidate.difficulty == 2),
        isTrue,
      );
      expect(
        masteryCandidates.every((candidate) => candidate.difficulty == 3),
        isTrue,
      );
      expect(
        challengeCandidates
            .map((candidate) => candidate.stableKey)
            .toSet()
            .intersection(
              masteryCandidates.map((candidate) => candidate.stableKey).toSet(),
            ),
        isEmpty,
      );
    });

    test('training allocation is excluded from the real game when possible',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById(
        'c4_math_operations:math_market:l1',
      )!;

      final plan = planner.planForLevel(
        repository: repository,
        level: level,
        request: const MissionRunRequest(
          runSeed: 42,
          trainingItemCount: 2,
          gameItemCount: 4,
        ),
      );

      expect(plan.trainingItems, hasLength(2));
      expect(plan.gameItems, hasLength(4));
      expect(plan.hasTrainingGameOverlap, isFalse);
      expect(plan.hasContentShortfall, isFalse);
    });

    test('same seed produces the same complete allocation', () {
      final repository = buildContentRepository();
      final level = learningLevelById(
        'c5_math_operations:math_market:l2',
      )!;
      const request = MissionRunRequest(
        runSeed: 9182,
        trainingItemCount: 1,
        gameItemCount: 4,
      );

      final first = planner.planForLevel(
        repository: repository,
        level: level,
        request: request,
      );
      final second = planner.planForLevel(
        repository: repository,
        level: level,
        request: request,
      );

      expect(
        first.trainingItems.map((item) => item.candidate.stableKey).toList(),
        second.trainingItems.map((item) => item.candidate.stableKey).toList(),
      );
      expect(
        first.gameItems.map((item) => item.candidate.stableKey).toList(),
        second.gameItems.map((item) => item.candidate.stableKey).toList(),
      );
    });

    test('run seed can produce multiple deterministic mission orders', () {
      final repository = buildContentRepository();
      final level = learningLevelById(
        'c4_math_operations:math_market:l2',
      )!;
      final orders = <String>{};

      for (var seed = 1; seed <= 12; seed += 1) {
        final plan = planner.planForLevel(
          repository: repository,
          level: level,
          request: MissionRunRequest(
            runSeed: seed,
            trainingItemCount: 1,
            gameItemCount: 3,
          ),
        );
        orders.add(
          plan.gameItems.map((item) => item.candidate.stableKey).join('|'),
        );
      }

      expect(orders.length, greaterThan(1));
    });

    test('recent activities are avoided while fresh alternatives exist', () {
      final repository = buildContentRepository();
      final level = learningLevelById(
        'c3_math_operations:math_market:l1',
      )!;
      final first = planner.planForLevel(
        repository: repository,
        level: level,
        request: const MissionRunRequest(
          runSeed: 77,
          trainingItemCount: 0,
          gameItemCount: 3,
        ),
      );
      final recentKeys = first.gameItems
          .map((item) => item.candidate.stableKey)
          .toList(growable: false);

      final second = planner.planForLevel(
        repository: repository,
        level: level,
        request: MissionRunRequest(
          runSeed: 77,
          trainingItemCount: 0,
          gameItemCount: 3,
          history: MissionExposureHistory(activityKeys: recentKeys),
        ),
      );

      expect(
        first.gameActivityKeys.intersection(second.gameActivityKeys),
        isEmpty,
      );
    });

    test('generated mission families expand only their exact class and tier',
        () {
      final repository = buildContentRepository();
      final mathsLevel = learningLevelById(
        'c4_math_operations:math_market:l2',
      )!;
      final storyLevel = learningLevelById(
        'c4_english_story:story_builder:l2',
      )!;

      final maths = planner.candidatesForLevel(
        repository: repository,
        level: mathsLevel,
      );
      final story = planner.candidatesForLevel(
        repository: repository,
        level: storyLevel,
      );

      expect(maths.any((candidate) => candidate.isGenerated), isTrue);
      expect(
        maths.where((candidate) => candidate.isGenerated).every(
              (candidate) =>
                  candidate.classNumber == 4 && candidate.difficulty == 2,
            ),
        isTrue,
      );
      expect(story.any((candidate) => candidate.isGenerated), isTrue);
      expect(
        story.where((candidate) => candidate.isGenerated).every(
              (candidate) =>
                  candidate.classNumber == 4 && candidate.difficulty == 2,
            ),
        isTrue,
      );
    });

    test('planned authored and generated references can be rehydrated safely',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById(
        'c5_math_operations:math_market:l3',
      )!;
      final candidates = planner.candidatesForLevel(
        repository: repository,
        level: level,
      );
      final authored = candidates.firstWhere(
        (candidate) => !candidate.isGenerated,
      );
      final generated = candidates.firstWhere(
        (candidate) => candidate.isGenerated,
      );

      for (final candidate in <MissionCandidate>[authored, generated]) {
        final activity = planner.resolveCandidateActivity(
          repository: repository,
          candidate: candidate,
        );
        expect(activity.classNumber, candidate.classNumber);
        expect(activity.gameId, candidate.gameId);
        expect(activity.difficulty, candidate.difficulty);
        expect(activity.legacyContentId, candidate.legacyContentId);
      }
    });

    test('small authored pools report a shortfall instead of forced repeat',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById(
        'c4_english_story:story_builder:l1',
      )!;

      final plan = planner.planForLevel(
        repository: repository,
        level: level,
        request: const MissionRunRequest(
          runSeed: 5,
          trainingItemCount: 1,
          gameItemCount: 2,
          includeGeneratedPractice: false,
        ),
      );

      expect(plan.trainingItems, hasLength(1));
      expect(plan.gameItems, hasLength(1));
      expect(plan.gameShortfall, 1);
      expect(plan.hasContentShortfall, isTrue);
      expect(plan.hasTrainingGameOverlap, isFalse);
    });

    test('Class 3/4/5 mission references remain isolated', () {
      final repository = buildContentRepository();
      final keysByClass = <int, Set<String>>{};

      for (final classNumber in <int>[3, 4, 5]) {
        final level = learningLevelById(
          'c${classNumber}_math_operations:math_market:l1',
        )!;
        keysByClass[classNumber] = planner
            .candidatesForLevel(repository: repository, level: level)
            .map((candidate) => candidate.stableKey)
            .toSet();
      }

      expect(keysByClass[3]!.intersection(keysByClass[4]!), isEmpty);
      expect(keysByClass[4]!.intersection(keysByClass[5]!), isEmpty);
      expect(keysByClass[3]!.intersection(keysByClass[5]!), isEmpty);
    });
  });
}
