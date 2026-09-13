import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/diagnostic_engine.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/learning/mission_content_signature.dart';
import 'package:brightquest_kids/core/learning/mission_exposure_memory.dart';
import 'package:brightquest_kids/core/learning/mission_run_models.dart';
import 'package:brightquest_kids/core/learning/mission_run_session_coordinator.dart';
import 'package:brightquest_kids/core/learning/skill_studio_practice_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  group('Step 13 adaptive non-repeat engine', () {
    test('schema-v1 legacy exposure remains readable with new advisory fields',
        () {
      final restored = MissionExposureMemory.fromJson(<String, Object?>{
        'schemaVersion': 1,
        'byClass': <String, Object?>{
          '4': <String, Object?>{
            'recent': <Object?>[
              <String, Object?>{
                'classNumber': 4,
                'levelId': 'legacy-level',
                'gameId': 'math_market',
                'activityKey': '4|math_market|legacy',
                'archetypeId': 'legacy-archetype',
                'mechanicName': 'decision',
                'roleName': 'game',
                'runSeed': 4,
                'seenAtIso': DateTime.utc(2026, 8, 23).toIso8601String(),
              },
            ],
            'recordedRunIds': <Object?>['legacy-run'],
          },
        },
      });

      final record = restored.byClass[4]!.recent.single;
      expect(record.contentFingerprint, isEmpty);
      expect(record.topicId, isEmpty);
      expect(record.competencyId, isEmpty);
      expect(record.difficulty, 0);
      expect(restored.historyForClass(4).activityKeys, hasLength(1));
    });

    test('visible fingerprint memory is class-isolated and round-trips', () {
      final memory = MissionExposureMemory();
      final timestamp = DateTime.utc(2026, 8, 23, 10);
      expect(
        memory.recordRecords(
          classNumber: 3,
          runId: 'skill-c3',
          records: <MissionExposureRecord>[
            MissionExposureRecord(
              classNumber: 3,
              levelId: 'skill:c3_test',
              gameId: 'skill_studio',
              activityKey: '3|skill_studio|a',
              archetypeId: 'skill:a',
              mechanicName: 'decision',
              roleName: MissionRunRole.training.name,
              runSeed: 1,
              seenAtIso: timestamp.toIso8601String(),
              contentFingerprint: 'same visible prompt',
              topicId: 'topic-a',
              competencyId: 'c3_test',
              difficulty: 4,
            ),
          ],
        ),
        isTrue,
      );
      final restored = MissionExposureMemory.fromJson(memory.toJson());
      expect(
        restored.historyForClass(3).contentFingerprints,
        contains('same visible prompt'),
      );
      expect(restored.historyForClass(4).contentFingerprints, isEmpty);
    });

    test('world planner treats same visible prompt as recent across IDs', () {
      final repository = buildContentRepository();
      const coordinator = MissionRunSessionCoordinator();
      final level = coordinator.planner.candidatesForLevel(
        repository: repository,
        level: learningLevelById(
          'c4_math_operations:math_market:l2',
        )!,
      );
      expect(level.length, greaterThan(10));
      final recentFingerprint = level.first.contentFingerprint;
      final learningLevel = learningLevelById(
        'c4_math_operations:math_market:l2',
      )!;
      final plan = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: learningLevel,
        history: MissionExposureHistory(
          contentFingerprints: <String>[recentFingerprint],
        ),
        now: DateTime.utc(2026, 8, 23, 11),
      );
      final selected = <String>{
        ...plan.trainingItems.map((item) => item.candidate.contentFingerprint),
        ...plan.gameItems.map((item) => item.candidate.contentFingerprint),
      };
      expect(selected, isNot(contains(recentFingerprint)));
    });

    test('Skill Studio rotates the same competency before spaced reuse', () {
      final repository = buildContentRepository();
      const planner = SkillStudioPracticePlanner();
      const competencyId = 'c4_eng_comprehend_main_infer';
      final memory = MissionExposureMemory();
      final first = planner.plan(
        repository: repository,
        classNumber: 4,
        competencyId: competencyId,
        history: memory.historyFor(
          classNumber: 4,
          gameId: 'skill_studio',
        ),
        learningState: const LearningProfileState(),
      );
      expect(first.activityIds, hasLength(4));
      expect(first.freshCandidateCount, 4);
      expect(first.activityIds.toSet(), hasLength(4));
      expect(
        first.activityIds.every((id) {
          final activity = repository.activityById(id)!;
          return activity.classNumber == 4 &&
              activity.allCompetencyIds.contains(competencyId);
        }),
        isTrue,
      );

      expect(
        memory.recordRecords(
          classNumber: 4,
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
        classNumber: 4,
        competencyId: competencyId,
        history: memory.historyFor(
          classNumber: 4,
          gameId: 'skill_studio',
        ),
        learningState: const LearningProfileState(),
      );
      // The authored competency pool is finite (4). Once exhausted, least-
      // recent ordering must change rather than immediately replaying item 1.
      expect(second.freshCandidateCount, 0);
      expect(second.activityIds.first, isNot(first.activityIds.first));
      expect(second.activityIds.toSet(), first.activityIds.toSet());
    });

    test('diagnostic restart rotates exact items when alternatives exist', () {
      final repository = buildContentRepository();
      const engine = DiagnosticEngine(targetItemCount: 12);
      final first = engine.start(
        repository: repository,
        classNumber: 4,
        now: DateTime.utc(2026, 8, 23, 13),
      );
      final fingerprints = first.itemIds
          .map(repository.activityById)
          .where((activity) => activity != null)
          .map((activity) => missionActivityFingerprint(activity!))
          .toList(growable: false);
      final second = engine.start(
        repository: repository,
        classNumber: 4,
        now: DateTime.utc(2026, 8, 23, 14),
        recentItemIds: first.itemIds,
        recentContentFingerprints: fingerprints,
      );
      expect(second.itemIds, hasLength(first.itemIds.length));
      expect(second.itemIds, isNot(first.itemIds));
      expect(
        second.itemIds.toSet().intersection(first.itemIds.toSet()).length,
        lessThan(first.itemIds.length),
      );
    });
  });
}
