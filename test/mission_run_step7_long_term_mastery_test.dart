import 'dart:convert';

import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_models.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_models.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/learning/learning_progress_engine.dart';
import 'package:brightquest_kids/core/learning/mission_mastery_intelligence.dart';
import 'package:brightquest_kids/core/learning/mission_mastery_models.dart';
import 'package:brightquest_kids/core/learning/mission_run_models.dart';
import 'package:brightquest_kids/core/learning/mission_run_planner.dart';
import 'package:brightquest_kids/core/learning/mission_variety_models.dart';
import 'package:brightquest_kids/core/learning/parent_report_engine.dart';
import 'package:brightquest_kids/core/models/game_models.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const progressEngine = LearningProgressEngine();
  const masteryEngine = MissionMasteryIntelligence();
  const planner = MissionRunPlanner();

  group('Step 7 long-term retention loop', () {
    test('secure mastery continues into bounded maintenance review', () {
      final learnedAt = DateTime.utc(2026, 8, 1, 10);
      var state = _demonstratedState(learnedAt);
      final competency = state.skillMastery.keys.single;
      final firstDue = state.reviewTasks.single.dueAt!;
      state = progressEngine.refreshReviewStates(state, firstDue);
      state = progressEngine.recordEvidence(
        state,
        _evidence(
          id: 'review-1',
          competencyId: competency,
          itemId: 'review-item',
          kind: LearningAttemptKind.review,
          correct: true,
          at: firstDue,
        ),
      );

      expect(
          state.skillMastery[competency]!.state, LearningEvidenceState.secure);
      expect(state.reviewTasks.single.completed, isFalse);
      expect(state.skillMastery[competency]!.nextReviewIso, isNotNull);
      expect(
        state.reviewTasks.single.intervalIndex,
        lessThanOrEqualTo(4),
      );

      final maintenanceDue = state.reviewTasks.single.dueAt!;
      state = progressEngine.refreshReviewStates(state, maintenanceDue);
      expect(state.skillMastery[competency]!.state,
          LearningEvidenceState.reviewDue);
    });

    test(
        'due World evidence becomes review evidence and a miss reopens mastery',
        () {
      final learnedAt = DateTime.utc(2026, 8, 1, 10);
      var state = _demonstratedState(learnedAt);
      final competency = state.skillMastery.keys.single;
      final due = state.reviewTasks.single.dueAt!;
      state = progressEngine.refreshReviewStates(state, due);

      state = progressEngine.recordEvidence(
        state,
        _evidence(
          id: 'world-retention-miss',
          competencyId: competency,
          itemId: 'fresh-world-item',
          kind: LearningAttemptKind.independent,
          correct: false,
          at: due,
        ),
      );

      expect(state.attemptEvidence.last.kind, LearningAttemptKind.review);
      expect(state.skillMastery[competency]!.state,
          LearningEvidenceState.reviewDue);
      expect(state.reviewTasks.single.completed, isFalse);
      expect(state.reviewTasks.single.dueAt!.isAfter(due), isTrue);
    });

    test('legacy secure profile is revived without a schema migration', () {
      final lastSeen = DateTime.utc(2026, 7, 1, 10);
      const competency = 'c3_math_equal_sharing_division';
      final state = LearningProfileState(
        attemptEvidence: <AttemptEvidence>[
          _evidence(
            id: 'legacy-review',
            competencyId: competency,
            itemId: 'legacy-item',
            kind: LearningAttemptKind.review,
            correct: true,
            at: lastSeen,
          ),
        ],
        skillMastery: <String, SkillMastery>{
          competency: SkillMastery(
            competencyId: competency,
            state: LearningEvidenceState.secure,
            evidenceCount: 4,
            correctCount: 4,
            independentCorrectCount: 4,
            transferCorrectCount: 1,
            delayedReviewSuccesses: 1,
            confidence: .9,
          ),
        },
        reviewTasks: <ReviewTask>[
          ReviewTask(
            id: 'review:3:$competency',
            competencyId: competency,
            classNumber: 3,
            dueIso: DateTime.utc(2026, 7, 1).toIso8601String(),
            intervalIndex: 4,
            completed: true,
          ),
        ],
      );

      final refreshed = progressEngine.refreshReviewStates(
        state,
        DateTime.utc(2026, 7, 2),
      );
      expect(refreshed.skillMastery[competency]!.nextReviewIso, isNotNull);
      expect(refreshed.reviewTasks.single.completed, isFalse);
      expect(refreshed.reviewTasks.single.intervalIndex, 4);
    });
  });

  group('Step 7 conservative mastery intelligence', () {
    test('repeating one item cannot satisfy distinct-evidence security', () {
      const competency = 'repeat-skill';
      final state = LearningProfileState(
        attemptEvidence: <AttemptEvidence>[
          for (var index = 0; index < 6; index += 1)
            _evidence(
              id: 'repeat-$index',
              competencyId: competency,
              itemId: 'same-item',
              kind: index == 4
                  ? LearningAttemptKind.transfer
                  : index == 5
                      ? LearningAttemptKind.review
                      : LearningAttemptKind.independent,
              correct: true,
              at: DateTime.utc(2026, 8, 1 + index),
            ),
        ],
        skillMastery: const <String, SkillMastery>{
          competency: SkillMastery(
            competencyId: competency,
            state: LearningEvidenceState.secure,
            evidenceCount: 6,
            correctCount: 6,
            independentCorrectCount: 6,
            transferCorrectCount: 1,
            delayedReviewSuccesses: 1,
            confidence: .95,
          ),
        },
      );

      final insight = masteryEngine.forCompetency(
        learningState: state,
        classNumber: 3,
        competencyId: competency,
        now: DateTime.utc(2026, 8, 10),
      );
      expect(insight.distinctIndependentItems, 1);
      expect(insight.status, isNot(LongTermMasteryStatus.secure));
    });

    test('Class 5 security requires broader independent evidence than Class 3',
        () {
      final c3 = masteryEngine.expectationForClass(3);
      final c4 = masteryEngine.expectationForClass(4);
      final c5 = masteryEngine.expectationForClass(5);
      expect(c3.minimumDistinctIndependentItems, 2);
      expect(c4.minimumDistinctIndependentItems, 2);
      expect(c5.minimumDistinctIndependentItems, 3);
      expect(c5.confidenceThreshold, greaterThan(c3.confidenceThreshold));
    });

    test('aggregate legacy evidence is not misreported as not started', () {
      const competency = 'aggregate-only';
      final insight = masteryEngine.forCompetency(
        learningState: const LearningProfileState(
          skillMastery: <String, SkillMastery>{
            competency: SkillMastery(
              competencyId: competency,
              state: LearningEvidenceState.needsSupport,
              evidenceCount: 3,
              correctCount: 1,
            ),
          },
        ),
        classNumber: 3,
        competencyId: competency,
      );
      expect(insight.status, LongTermMasteryStatus.needsPractice);
    });
  });

  group('Step 7 linked-skill mission selection', () {
    test('candidate JSON keeps authored related competency metadata', () {
      const candidate = MissionCandidate(
        activityId: 'a',
        legacyContentId: 'legacy-a',
        classNumber: 4,
        gameId: 'math_market',
        topicId: 'topic',
        competencyId: 'primary',
        relatedCompetencyIds: <String>['linked'],
        difficulty: 2,
        activityType: 'choice',
        responseRuleType: 'exact',
        source: MissionContentSource.authored,
        mechanic: LearningGameMechanic.decision,
        archetypeId: 'family',
        contentFingerprint: 'prompt',
      );
      final restored = MissionCandidate.fromJson(
        Map<String, Object?>.from(
          jsonDecode(jsonEncode(candidate.toJson())) as Map,
        ),
      );
      expect(restored.relatedCompetencyIds, ['linked']);
      expect(restored.allCompetencyIds, {'primary', 'linked'});

      final legacyJson = candidate.toJson()..remove('relatedCompetencyIds');
      expect(
          MissionCandidate.fromJson(legacyJson).relatedCompetencyIds, isEmpty);
    });

    test('weak authored related competency can pull linked mission forward',
        () {
      final repository = buildContentRepository();
      final levels = levelsForClass(4);
      LearningLevel? level;
      MissionCandidate? linked;
      for (final candidateLevel in levels) {
        for (final candidate in planner.candidatesForLevel(
          repository: repository,
          level: candidateLevel,
        )) {
          if (candidate.relatedCompetencyIds.isNotEmpty) {
            level = candidateLevel;
            linked = candidate;
            break;
          }
        }
        if (level != null) break;
      }
      expect(level, isNotNull);
      expect(linked, isNotNull);

      final target = linked!.relatedCompetencyIds.first;
      final plan = planner.planForLevel(
        repository: repository,
        level: level!,
        request: MissionRunRequest(
          runSeed: 707,
          trainingItemCount: 1,
          gameItemCount: 1,
          selectionProfile: AdaptiveMissionSelectionProfile(
            trainingCompetencyPriorities: <String, int>{target: 1000},
            reason: 'linked skill review test',
          ),
        ),
      );
      expect(plan.trainingItems.first.candidate.allCompetencyIds,
          contains(target));
    });

    test('stretch can prefer authored linked-skill game activity', () {
      final repository = buildContentRepository();
      final levels = levelsForClass(5);
      LearningLevel? level;
      for (final candidateLevel in levels) {
        if (planner
            .candidatesForLevel(repository: repository, level: candidateLevel)
            .any((item) => item.relatedCompetencyIds.isNotEmpty)) {
          level = candidateLevel;
          break;
        }
      }
      expect(level, isNotNull);
      final plan = planner.planForLevel(
        repository: repository,
        level: level!,
        request: const MissionRunRequest(
          runSeed: 708,
          trainingItemCount: 0,
          gameItemCount: 1,
          selectionProfile: AdaptiveMissionSelectionProfile(
            demand: AdaptiveMissionDemandBand.stretch,
            mixedSkillGameBonus: 1000,
            reason: 'mixed skill stretch test',
          ),
        ),
      );
      expect(plan.gameItems.single.candidate.relatedCompetencyIds, isNotEmpty);
    });
  });

  group('Step 7 World and parent signals', () {
    test('completed retention-due level outranks ordinary forward progression',
        () async {
      final repository = buildContentRepository();
      final controller = GameController();
      await controller.load();
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      controller.completeLearningLevel(level: level, score: 5, maxScore: 5);
      controller.completeLearningLevel(level: level, score: 5, maxScore: 5);
      final ordinaryNext =
          controller.nextRecommendedWorldLevelForSubject(SubjectWorld.maths);
      expect(ordinaryNext?.id, isNot(level.id));

      final competency = planner
          .candidatesForLevel(repository: repository, level: level)
          .first
          .competencyId;
      final learnedAt = DateTime.utc(2026, 8, 1, 10);
      for (final entry in <(String, LearningAttemptKind)>[
        ('world-independent-1', LearningAttemptKind.independent),
        ('world-independent-2', LearningAttemptKind.independent),
        ('world-transfer', LearningAttemptKind.transfer),
      ]) {
        controller.recordLearningEvidence(
          _evidence(
            id: entry.$1,
            competencyId: competency,
            itemId: 'item-${entry.$1}',
            kind: entry.$2,
            correct: true,
            at: learnedAt.add(Duration(
              minutes: controller.attemptEvidence.length,
            )),
          ),
          saveImmediately: false,
        );
      }
      final due = controller.reviewTasks.single.dueAt!;
      controller.dueReviewTasks(now: due);

      final longTermNext = controller.nextLongTermWorldLevelForSubject(
        repository,
        SubjectWorld.maths,
        now: due,
      );
      expect(longTermNext?.id, level.id);
      expect(
        controller.masteryInsightForLevel(repository, level, now: due).status,
        LongTermMasteryStatus.retentionDue,
      );
    });

    test('parent report exposes conservative long-term signal', () {
      final repository = buildContentRepository();
      final competency = repository.curriculum.classPack(3)!.competencies.first;
      final state = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          competency.id: SkillMastery(
            competencyId: competency.id,
            state: LearningEvidenceState.needsSupport,
            evidenceCount: 3,
            correctCount: 1,
            confidence: .3,
          ),
        },
      );
      final report = const ParentReportEngine().build(
        curriculum: repository.curriculum,
        learning: state,
        classNumber: 3,
        now: DateTime.utc(2026, 8, 23),
      );
      final row = report.rows.firstWhere(
        (item) => item.competencyId == competency.id,
      );
      expect(row.longTermStatus, LongTermMasteryStatus.needsPractice);
      expect(row.longTermLabel, 'Needs practice');
      expect(report.weekly.needsSupport, 1);
    });
  });
}

LearningProfileState _demonstratedState(DateTime learnedAt) {
  var state = const LearningProfileState();
  for (final entry in <(String, LearningAttemptKind)>[
    ('independent-1', LearningAttemptKind.independent),
    ('independent-2', LearningAttemptKind.independent),
    ('transfer', LearningAttemptKind.transfer),
  ]) {
    state = const LearningProgressEngine().recordEvidence(
      state,
      _evidence(
        id: entry.$1,
        competencyId: 'c3_math_equal_sharing_division',
        itemId: 'item-${entry.$1}',
        kind: entry.$2,
        correct: true,
        at: learnedAt.add(Duration(minutes: state.attemptEvidence.length)),
      ),
    );
  }
  return state;
}

AttemptEvidence _evidence({
  required String id,
  required String competencyId,
  required String itemId,
  required LearningAttemptKind kind,
  required bool correct,
  required DateTime at,
}) =>
    AttemptEvidence(
      id: id,
      profileId: 'child-1',
      classNumber: competencyId.startsWith('c5_')
          ? 5
          : competencyId.startsWith('c4_')
              ? 4
              : 3,
      competencyId: competencyId,
      itemId: itemId,
      kind: kind,
      correct: correct,
      hintLevel: 0,
      retries: 0,
      responseTimeMs: 1200,
      confidence: 1,
      recordedAtIso: at.toIso8601String(),
      sourceGameId: 'math_market',
    );
