import 'package:brightquest_kids/core/content/content_activity.dart';
import 'package:brightquest_kids/core/content/skill_studio_generators.dart';
import 'package:brightquest_kids/core/learning/activity_response_evaluator.dart';
import 'package:brightquest_kids/core/learning/diagnostic_engine.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_resolver.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/learning/mission_content_signature.dart';
import 'package:brightquest_kids/core/learning/mission_exposure_memory.dart';
import 'package:brightquest_kids/core/learning/skill_studio_practice_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  group('Step 14 logical unlimited practice', () {
    test('all dedicated Maths gaps expose deterministic generated drills', () {
      final repository = buildContentRepository();
      const evaluator = ActivityResponseEvaluator();
      const resolver = GameplayActivityResolver();

      expect(SkillStudioPracticeGenerators.supportedCompetencyIds, hasLength(16));
      for (final competencyId
          in SkillStudioPracticeGenerators.supportedCompetencyIds) {
        final classNumber = int.parse(competencyId.substring(1, 2));
        expect(
          repository.supportsGeneratedSkillStudioPractice(
            classNumber,
            competencyId,
          ),
          isTrue,
          reason: competencyId,
        );
        final generated = repository.generatedSkillStudioPracticeForCompetency(
          classNumber,
          competencyId,
          seedBase: 17041,
          candidateCount: 64,
        );
        expect(generated, hasLength(64), reason: competencyId);
        expect(
          generated.map((activity) => activity.id).toSet(),
          hasLength(64),
          reason: '$competencyId generated ids',
        );
        expect(
          generated.map(missionActivityFingerprint).toSet().length,
          greaterThanOrEqualTo(40),
          reason: '$competencyId should expose a broad visible drill bank',
        );

        for (final activity in generated) {
          expect(activity.classNumber, classNumber);
          expect(activity.competencyId, competencyId);
          expect(activity.gameId, 'skill_studio');
          expect(activity.generation.mode, 'generated');
          expect(activity.status, 'needsReview');
          expect(resolver.resolve(activity).isSupported, isTrue);
          final answer = activity.correctResponseRule['value'];
          expect(evaluator.evaluate(activity, answer).correct, isTrue);
          final choices = evaluator.choicesFor(activity);
          expect(choices.length, greaterThanOrEqualTo(2));
          expect(choices.toSet(), hasLength(choices.length));
          expect(choices, contains(answer));

          final rehydrated = repository.activityById(activity.id);
          expect(rehydrated, isNotNull, reason: activity.id);
          expect(rehydrated!.prompt, activity.prompt);
          expect(rehydrated.correctResponseRule, activity.correctResponseRule);
        }
      }
    });

    test('Skill Studio reuses audited World generation only for the exact competency', () {
      final repository = buildContentRepository();
      const competencyId = 'c3_math_multiplication_facts';
      expect(
        repository.supportsGeneratedSkillStudioPractice(3, competencyId),
        isTrue,
      );
      final generated = repository.generatedSkillStudioPracticeForCompetency(
        3,
        competencyId,
        seedBase: 991,
        candidateCount: 8,
      );
      expect(generated, isNotEmpty);
      expect(
        generated.every(
          (activity) =>
              activity.classNumber == 3 &&
              activity.allCompetencyIds.contains(competencyId) &&
              activity.generation.mode == 'generated',
        ),
        isTrue,
      );
      expect(
        generated.any((activity) => activity.competencyId != competencyId),
        isFalse,
      );
    });

    test('generated Skill Studio runs stay fresh across 200 response items', () {
      final repository = buildContentRepository();
      const planner = SkillStudioPracticePlanner();
      final memory = MissionExposureMemory();
      const competencyId = 'c5_math_factors_multiples';
      Set<String> previousFingerprints = <String>{};
      var responseItemCount = 0;

      for (var round = 0; round < 50; round += 1) {
        final plan = planner.plan(
          repository: repository,
          classNumber: 5,
          competencyId: competencyId,
          history: memory.historyFor(
            classNumber: 5,
            gameId: 'skill_studio',
          ),
          learningState: const LearningProfileState(),
        );
        expect(plan.activityIds, hasLength(4));
        final activities = plan.activityIds
            .map(repository.activityById)
            .whereType<ContentActivity>()
            .toList(growable: false);
        expect(activities, hasLength(4));
        final fingerprints = activities.map(missionActivityFingerprint).toSet();
        expect(fingerprints, hasLength(4));
        if (previousFingerprints.isNotEmpty) {
          expect(
            fingerprints.intersection(previousFingerprints),
            isEmpty,
            reason: 'Immediate Skill Studio repeat in round ${round + 1}',
          );
        }
        expect(
          memory.recordRecords(
            classNumber: 5,
            runId: plan.runId,
            records: planner.exposureRecords(
              repository: repository,
              plan: plan,
              seenAt: DateTime.utc(2026, 8, 23).add(Duration(minutes: round)),
            ),
          ),
          isTrue,
        );
        previousFingerprints = fingerprints;
        responseItemCount += activities.length;
      }
      expect(responseItemCount, 200);
      expect(
        memory.historyForClass(5).activityKeys.length,
        lessThanOrEqualTo(MissionExposureMemory.maxRecentItemsPerClass),
      );
    });

    test('knowledge-heavy authored-only skill uses honest spaced review', () {
      final repository = buildContentRepository();
      const planner = SkillStudioPracticePlanner();
      const competencyId = 'c3_eng_literal_comprehension';
      expect(
        repository.supportsGeneratedSkillStudioPractice(3, competencyId),
        isFalse,
      );
      final memory = MissionExposureMemory();
      final first = planner.plan(
        repository: repository,
        classNumber: 3,
        competencyId: competencyId,
        history: memory.historyFor(
          classNumber: 3,
          gameId: 'skill_studio',
        ),
        learningState: const LearningProfileState(),
      );
      expect(first.activityIds, hasLength(4));
      expect(
        memory.recordRecords(
          classNumber: 3,
          runId: first.runId,
          records: planner.exposureRecords(
            repository: repository,
            plan: first,
            seenAt: DateTime.utc(2026, 8, 23, 12),
          ),
        ),
        isTrue,
      );
      final second = planner.plan(
        repository: repository,
        classNumber: 3,
        competencyId: competencyId,
        history: memory.historyFor(
          classNumber: 3,
          gameId: 'skill_studio',
        ),
        learningState: const LearningProfileState(),
      );
      expect(second.freshCandidateCount, 0);
      expect(second.activityIds.toSet(), first.activityIds.toSet());
      expect(second.activityIds.first, isNot(first.activityIds.first));
      expect(second.selectionReason, contains('pool exhausted'));
    });

    test('Discovery re-checks stay short, class-specific and recent-aware', () {
      final repository = buildContentRepository();
      const engine = DiagnosticEngine(targetItemCount: 12);
      var recentIds = <String>[];
      var recentFingerprints = <String>[];
      List<String>? previous;

      for (var round = 0; round < 5; round += 1) {
        final progress = engine.start(
          repository: repository,
          classNumber: 4,
          now: DateTime.utc(2026, 8, 23, 13 + round),
          recentItemIds: recentIds,
          recentContentFingerprints: recentFingerprints,
        );
        expect(progress.itemIds, hasLength(12));
        expect(progress.itemIds.toSet(), hasLength(12));
        expect(
          progress.itemIds.every(
            (id) => repository.activityById(id)?.classNumber == 4,
          ),
          isTrue,
        );
        if (previous != null) {
          expect(progress.itemIds, isNot(previous));
          expect(
            progress.itemIds.toSet().intersection(previous.toSet()).length,
            lessThan(12),
          );
        }
        previous = progress.itemIds;
        final roundActivities = progress.itemIds
            .map(repository.activityById)
            .whereType<ContentActivity>()
            .toList(growable: false);
        recentIds = <String>[...progress.itemIds, ...recentIds];
        recentFingerprints = <String>[
          ...roundActivities.map(missionActivityFingerprint),
          ...recentFingerprints,
        ];
      }
    });
  });
}
