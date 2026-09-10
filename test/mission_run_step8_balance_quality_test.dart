import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/mission_balance_policy.dart';
import 'package:brightquest_kids/core/learning/mission_run_models.dart';
import 'package:brightquest_kids/core/learning/mission_run_planner.dart';
import 'package:brightquest_kids/core/learning/mission_variety_models.dart';
import 'package:brightquest_kids/core/qa/mission_content_quality_audit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const planner = MissionRunPlanner();

  group('Step 8 mission balance and content quality hardening', () {
    test('all 72 levels pass deterministic content-quality and balance gates',
        () {
      final repository = buildContentRepository();
      final report = const MissionContentQualityAudit(
        simulationSeedsPerLevel: 16,
      ).audit(repository);

      expect(report.levelsAudited, 72);
      expect(report.generatedActivitiesAudited, greaterThanOrEqualTo(864));
      expect(report.simulationRuns, 72 * 16);
      expect(report.checksRun, greaterThan(10000));
      expect(
        report.releaseBlockingFindings,
        isEmpty,
        reason: report.releaseBlockingFindings.join('\n'),
      );
      expect(
        report.snapshots.every((snapshot) => snapshot.candidateCount >= 10),
        isTrue,
      );
      expect(
        report.snapshots
            .every((snapshot) => snapshot.uniquePlanSignatures >= 8),
        isTrue,
      );
    });

    test('neutral multi-topic runs rotate topics inside Training and Game', () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l2')!;

      for (var seed = 0; seed < 64; seed += 1) {
        final plan = planner.planForLevel(
          repository: repository,
          level: level,
          request: MissionRunRequest(
            runSeed: 8000 + seed,
            trainingItemCount: 5,
            gameItemCount: 5,
          ),
        );
        final trainingTopics =
            plan.trainingItems.map((item) => item.candidate.topicId).toSet();
        final gameTopics =
            plan.gameItems.map((item) => item.candidate.topicId).toSet();

        expect(trainingTopics.length, greaterThanOrEqualTo(3),
            reason: 'seed $seed');
        expect(gameTopics.length, greaterThanOrEqualTo(3),
            reason: 'seed $seed');
        expect(plan.hasTrainingGameOverlap, isFalse);
        expect(plan.hasVisibleContentOverlap, isFalse);
        expect(plan.hasInternalContentRepeat, isFalse);
      }
    });

    test('Training preserves minority topic capacity for the Real Game', () {
      final repository = buildContentRepository();
      final levels = <String>[
        'c3_math_fractions:fraction_pizza:l1',
        'c3_math_fractions:fraction_pizza:l2',
        'c4_math_fractions:fraction_pizza:l3',
        'c5_math_fractions:fraction_pizza:l3',
        'c5_social_india:map_quest:l1',
      ];

      for (final levelId in levels) {
        final level = learningLevelById(levelId)!;
        for (var seed = 0; seed < 32; seed += 1) {
          final plan = planner.planForLevel(
            repository: repository,
            level: level,
            request: MissionRunRequest(
              runSeed: 91000 + seed,
              trainingItemCount: 5,
              gameItemCount: 5,
            ),
          );
          expect(
            plan.gameItems.map((item) => item.candidate.topicId).toSet().length,
            greaterThanOrEqualTo(2),
            reason: '$levelId seed $seed lost its minority topic in Training',
          );
          expect(plan.hasTrainingGameOverlap, isFalse);
          expect(plan.hasVisibleContentOverlap, isFalse);
        }
      }
    });

    test(
        'generated bank stays unique across Math, Fraction tiers and Coding classes',
        () {
      final repository = buildContentRepository();

      for (final classNumber in const <int>[3, 4, 5]) {
        for (final difficulty in const <int>[1, 2, 3]) {
          final mathPrompts = <String>{};
          final fractionPrompts = <String>{};
          for (var seed = 0; seed < 12; seed += 1) {
            final math = repository.activityForLegacyContent(
              classNumber: classNumber,
              gameId: 'math_market',
              legacyContentId: 'gen_math_c${classNumber}_d${difficulty}_s$seed',
            )!;
            final fraction = repository.activityForLegacyContent(
              classNumber: classNumber,
              gameId: 'fraction_pizza',
              legacyContentId:
                  'gen_fraction_c${classNumber}_d${difficulty}_s$seed',
            )!;
            expect(mathPrompts.add(math.prompt), isTrue,
                reason: 'duplicate Math c$classNumber d$difficulty seed $seed');
            expect(fractionPrompts.add(fraction.prompt), isTrue,
                reason:
                    'duplicate Fraction c$classNumber d$difficulty seed $seed');
          }
        }
      }

      for (final classNumber in const <int>[3, 4, 5]) {
        for (var seed = 0; seed < 12; seed += 1) {
          final fractionPrompts = <String>{};
          final mathPrompts = <String>{};
          for (final difficulty in const <int>[1, 2, 3]) {
            final fraction = repository.activityForLegacyContent(
              classNumber: classNumber,
              gameId: 'fraction_pizza',
              legacyContentId:
                  'gen_fraction_c${classNumber}_d${difficulty}_s$seed',
            )!;
            final math = repository.activityForLegacyContent(
              classNumber: classNumber,
              gameId: 'math_market',
              legacyContentId: 'gen_math_c${classNumber}_d${difficulty}_s$seed',
            )!;
            fractionPrompts.add(fraction.prompt);
            mathPrompts.add(math.prompt);
          }
          expect(fractionPrompts, hasLength(3),
              reason: 'Fraction tiers collapsed for c$classNumber seed $seed');
          expect(mathPrompts, hasLength(3),
              reason: 'Math tiers collapsed for c$classNumber seed $seed');
        }
      }

      for (final difficulty in const <int>[1, 2, 3]) {
        for (var seed = 0; seed < 12; seed += 1) {
          final codingPrompts = <String>{};
          final mathPrompts = <String>{};
          for (final classNumber in const <int>[3, 4, 5]) {
            final coding = repository.activityForLegacyContent(
              classNumber: classNumber,
              gameId: 'coding_maze',
              legacyContentId:
                  'gen_coding_c${classNumber}_d${difficulty}_s$seed',
            )!;
            final math = repository.activityForLegacyContent(
              classNumber: classNumber,
              gameId: 'math_market',
              legacyContentId: 'gen_math_c${classNumber}_d${difficulty}_s$seed',
            )!;
            codingPrompts.add(coding.prompt);
            mathPrompts.add(math.prompt);
          }
          expect(codingPrompts, hasLength(3),
              reason: 'Coding classes collapsed for d$difficulty seed $seed');
          expect(mathPrompts, hasLength(3),
              reason: 'Math classes collapsed for d$difficulty seed $seed');
        }
      }
    });

    test('strong adaptive reinforcement cannot monopolize a multi-topic run',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      const target = 'c4_math_division';
      const profile = AdaptiveMissionSelectionProfile(
        demand: AdaptiveMissionDemandBand.reinforce,
        trainingCompetencyPriorities: <String, int>{target: 120},
        gameCompetencyPriorities: <String, int>{target: 120},
        reason: 'Step 8 overtraining guard test',
      );

      for (var seed = 0; seed < 32; seed += 1) {
        final plan = planner.planForLevel(
          repository: repository,
          level: level,
          request: MissionRunRequest(
            runSeed: 8800 + seed,
            trainingItemCount: 5,
            gameItemCount: 5,
            selectionProfile: profile,
          ),
        );
        for (final items in <List<PlannedMissionItem>>[
          plan.trainingItems,
          plan.gameItems,
        ]) {
          final targetCount = items
              .where((item) => item.candidate.allCompetencyIds.contains(target))
              .length;
          expect(targetCount, lessThanOrEqualTo(3), reason: 'seed $seed');
          expect(
            items.map((item) => item.candidate.topicId).toSet().length,
            greaterThanOrEqualTo(2),
            reason: 'seed $seed',
          );
        }
      }
    });

    test('balance penalties disappear when a world has no real alternative',
        () {
      const policy = MissionBalancePolicy();
      final singleFamily = policy.neutralMaxOccurrences(
        itemCount: 5,
        distinctFamilies: 1,
      );
      final twoFamilies = policy.neutralMaxOccurrences(
        itemCount: 5,
        distinctFamilies: 2,
      );

      expect(singleFamily, 5);
      expect(twoFamilies, 4);
    });

    test('same seed remains deterministic after balance hardening', () {
      final repository = buildContentRepository();
      final level = learningLevelById('c5_science_life:science_lab:l3')!;
      const request = MissionRunRequest(
        runSeed: 808080,
        trainingItemCount: 5,
        gameItemCount: 5,
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
  });
}
