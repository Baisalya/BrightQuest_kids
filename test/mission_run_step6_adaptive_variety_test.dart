import 'dart:convert';

import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/learning/mission_run_models.dart';
import 'package:brightquest_kids/core/learning/mission_run_planner.dart';
import 'package:brightquest_kids/core/learning/mission_run_session_coordinator.dart';
import 'package:brightquest_kids/core/learning/mission_variety_intelligence.dart';
import 'package:brightquest_kids/core/learning/mission_variety_models.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const intelligence = MissionVarietyIntelligence();
  const planner = MissionRunPlanner();
  const coordinator = MissionRunSessionCoordinator();

  group('Step 6 mission variety intelligence', () {
    test(
        'weak competency is reinforced after immediate-miss cooldown has passed',
        () {
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      final learning = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          'c4_math_division': const SkillMastery(
            competencyId: 'c4_math_division',
            state: LearningEvidenceState.needsSupport,
            evidenceCount: 5,
            correctCount: 2,
            confidence: .35,
          ),
          'c4_math_multiplication': const SkillMastery(
            competencyId: 'c4_math_multiplication',
            state: LearningEvidenceState.secure,
            evidenceCount: 6,
            correctCount: 6,
            confidence: .9,
          ),
        },
        attemptEvidence: <AttemptEvidence>[
          _evidence(
            id: 'old-miss',
            competencyId: 'c4_math_division',
            correct: false,
            at: DateTime.utc(2026, 8, 23, 9),
          ),
          _evidence(
            id: 'later-1',
            competencyId: 'c4_math_multiplication',
            correct: true,
            at: DateTime.utc(2026, 8, 23, 9, 5),
          ),
          _evidence(
            id: 'later-2',
            competencyId: 'c4_math_add_sub',
            correct: true,
            at: DateTime.utc(2026, 8, 23, 9, 6),
          ),
        ],
      );

      final profile = intelligence.forLevel(
        level: level,
        levelProgress: LearningLevelProgress(),
        gameProgress: GameProgress(),
        learningState: learning,
        candidateCompetencyIds: const <String>{
          'c4_math_division',
          'c4_math_multiplication',
          'c4_math_add_sub',
        },
        now: DateTime.utc(2026, 8, 23, 10),
      );

      expect(profile.demand, AdaptiveMissionDemandBand.reinforce);
      expect(
          profile.cooldownCompetencyIds, isNot(contains('c4_math_division')));
      expect(
        profile.trainingPriorityFor('c4_math_division'),
        greaterThan(profile.trainingPriorityFor('c4_math_multiplication')),
      );
    });

    test(
        'a very recent miss is spaced before the same concept is drilled again',
        () {
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      final learning = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          'c4_math_division': const SkillMastery(
            competencyId: 'c4_math_division',
            state: LearningEvidenceState.needsSupport,
            evidenceCount: 5,
            correctCount: 2,
            confidence: .35,
          ),
          'c4_math_multiplication': const SkillMastery(
            competencyId: 'c4_math_multiplication',
            state: LearningEvidenceState.practising,
            evidenceCount: 4,
            correctCount: 3,
            confidence: .7,
          ),
        },
        attemptEvidence: <AttemptEvidence>[
          _evidence(
            id: 'fresh-miss',
            competencyId: 'c4_math_division',
            correct: false,
            at: DateTime.utc(2026, 8, 23, 10, 1),
          ),
        ],
      );

      final profile = intelligence.forLevel(
        level: level,
        levelProgress: LearningLevelProgress(),
        gameProgress: GameProgress(),
        learningState: learning,
        candidateCompetencyIds: const <String>{
          'c4_math_division',
          'c4_math_multiplication',
        },
        now: DateTime.utc(2026, 8, 23, 10, 2),
      );

      expect(profile.cooldownCompetencyIds, contains('c4_math_division'));
      expect(
        profile.gamePriorityFor('c4_math_division'),
        lessThan(profile.gamePriorityFor('c4_math_multiplication')),
      );
    });

    test('a due review overrides recent-miss cooldown', () {
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      final learning = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          'c4_math_division': const SkillMastery(
            competencyId: 'c4_math_division',
            state: LearningEvidenceState.reviewDue,
            evidenceCount: 6,
            correctCount: 4,
            confidence: .6,
          ),
        },
        attemptEvidence: <AttemptEvidence>[
          _evidence(
            id: 'fresh-miss',
            competencyId: 'c4_math_division',
            correct: false,
            at: DateTime.utc(2026, 8, 23, 10, 1),
          ),
        ],
        reviewTasks: <ReviewTask>[
          ReviewTask(
            id: 'review-div',
            competencyId: 'c4_math_division',
            classNumber: 4,
            dueIso: DateTime.utc(2026, 8, 23, 9).toIso8601String(),
            intervalIndex: 1,
          ),
        ],
      );

      final profile = intelligence.forLevel(
        level: level,
        levelProgress: LearningLevelProgress(),
        gameProgress: GameProgress(),
        learningState: learning,
        candidateCompetencyIds: const <String>{'c4_math_division'},
        now: DateTime.utc(2026, 8, 23, 10, 2),
      );

      expect(profile.demand, AdaptiveMissionDemandBand.spacedReview);
      expect(profile.reviewDueCompetencyIds, contains('c4_math_division'));
      expect(
          profile.cooldownCompetencyIds, isNot(contains('c4_math_division')));
      expect(profile.trainingPriorityFor('c4_math_division'), 120);
    });

    test('stretch policy is class-specific while keeping the same level tier',
        () {
      final c3 = learningLevelById('c3_math_operations:math_market:l2')!;
      final c5 = learningLevelById('c5_math_operations:math_market:l2')!;
      const learning = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          'strong-skill': SkillMastery(
            competencyId: 'strong-skill',
            state: LearningEvidenceState.secure,
            evidenceCount: 8,
            correctCount: 8,
            confidence: .95,
          ),
        },
      );
      final strongProgress = GameProgress(
        attempts: 10,
        correctAnswers: 9,
        mastery: .8,
      );

      final c3Profile = intelligence.forLevel(
        level: c3,
        levelProgress: LearningLevelProgress(bestRatio: .95),
        gameProgress: strongProgress,
        learningState: learning,
        candidateCompetencyIds: const <String>{'strong-skill'},
      );
      final c5Profile = intelligence.forLevel(
        level: c5,
        levelProgress: LearningLevelProgress(bestRatio: .95),
        gameProgress: strongProgress,
        learningState: learning,
        candidateCompetencyIds: const <String>{'strong-skill'},
      );

      expect(c3Profile.demand, AdaptiveMissionDemandBand.stretch);
      expect(c5Profile.demand, AdaptiveMissionDemandBand.stretch);
      expect(c5Profile.generatedGameBonus,
          greaterThan(c3Profile.generatedGameBonus));
      expect(c3.difficulty, 2);
      expect(c5.difficulty, 2);
    });

    test(
        'planner ranks adaptive competency preferences without breaking freshness',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      final candidates = planner.candidatesForLevel(
        repository: repository,
        level: level,
      );
      expect(candidates.map((item) => item.competencyId).toSet().length,
          greaterThan(1));

      const target = 'c4_math_division';
      final plan = planner.planForLevel(
        repository: repository,
        level: level,
        request: const MissionRunRequest(
          runSeed: 606,
          trainingItemCount: 5,
          gameItemCount: 5,
          selectionProfile: AdaptiveMissionSelectionProfile(
            demand: AdaptiveMissionDemandBand.reinforce,
            trainingCompetencyPriorities: <String, int>{target: 100},
            gameCompetencyPriorities: <String, int>{target: 100},
            reason: 'test reinforcement',
          ),
        ),
      );

      expect(plan.trainingItems.first.candidate.competencyId, target);
      expect(
          plan.gameItems.any((item) => item.candidate.competencyId == target),
          isTrue);
      expect(
        plan.gameItems
            .map((item) => item.candidate.competencyId)
            .toSet()
            .length,
        greaterThan(1),
      );
      expect(plan.hasTrainingGameOverlap, isFalse);
      expect(plan.hasVisibleContentOverlap, isFalse);
      expect(plan.hasInternalContentRepeat, isFalse);
      expect(plan.selectionDemand, AdaptiveMissionDemandBand.reinforce.name);
      expect(plan.difficulty, level.difficulty);
    });

    test(
        'exact mission freshness beats adaptive preference when an alternative exists',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      const selection = AdaptiveMissionSelectionProfile(
        demand: AdaptiveMissionDemandBand.reinforce,
        gameCompetencyPriorities: <String, int>{'c4_math_division': 100},
        reason: 'test freshness precedence',
      );
      final first = planner.planForLevel(
        repository: repository,
        level: level,
        request: const MissionRunRequest(
          runSeed: 607,
          trainingItemCount: 0,
          gameItemCount: 1,
          selectionProfile: selection,
        ),
      );
      final firstKey = first.gameItems.single.candidate.stableKey;
      final second = planner.planForLevel(
        repository: repository,
        level: level,
        request: MissionRunRequest(
          runSeed: 607,
          trainingItemCount: 0,
          gameItemCount: 1,
          history: MissionExposureHistory(activityKeys: <String>[firstKey]),
          selectionProfile: selection,
        ),
      );

      expect(second.gameItems.single.candidate.stableKey, isNot(firstKey));
      expect(second.difficulty, level.difficulty);
    });

    test(
        'session restore keeps the exact adaptive plan even if evidence later changes',
        () {
      final repository = buildContentRepository();
      final level = learningLevelById('c4_math_operations:math_market:l2')!;
      final learning = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          'c4_math_division': const SkillMastery(
            competencyId: 'c4_math_division',
            state: LearningEvidenceState.needsSupport,
            evidenceCount: 5,
            correctCount: 2,
            confidence: .35,
          ),
        },
      );
      final plan = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        learningState: learning,
        levelProgress: LearningLevelProgress(),
        gameProgress: GameProgress(),
        now: DateTime.utc(2026, 8, 23, 12),
      );
      final persistedData = Map<String, Object?>.from(
        jsonDecode(jsonEncode(coordinator.sessionDataFor(plan))) as Map,
      );
      final checkpoint = GameSessionCheckpoint(
        profileId: 'child-1',
        classNumber: 4,
        gameId: level.gameId,
        learningLevelId: level.id,
        difficulty: level.difficulty,
        stage: GameSessionStage.game,
        cursor: 2,
        score: 1,
        maxScore: 5,
        startedAtIso: '2026-08-23T12:00:00.000Z',
        updatedAtIso: '2026-08-23T12:03:00.000Z',
        data: persistedData,
      );
      final changedLearning = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          'c4_math_division': const SkillMastery(
            competencyId: 'c4_math_division',
            state: LearningEvidenceState.secure,
            evidenceCount: 10,
            correctCount: 10,
            confidence: .95,
          ),
        },
      );

      final restored = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        checkpoint: checkpoint,
        learningState: changedLearning,
        levelProgress: LearningLevelProgress(bestRatio: 1),
        gameProgress: GameProgress(
          attempts: 10,
          correctAnswers: 10,
          mastery: .9,
        ),
        now: DateTime.utc(2030),
      );

      expect(restored.runSeed, plan.runSeed);
      expect(restored.selectionDemand, plan.selectionDemand);
      expect(restored.selectionReason, plan.selectionReason);
      expect(
        restored.trainingItems.map((item) => item.candidate.stableKey).toList(),
        plan.trainingItems.map((item) => item.candidate.stableKey).toList(),
      );
      expect(
        restored.gameItems.map((item) => item.candidate.stableKey).toList(),
        plan.gameItems.map((item) => item.candidate.stableKey).toList(),
      );
    });

    test('single-competency worlds keep full runs and exact-tier safety', () {
      final repository = buildContentRepository();
      final level = learningLevelById('c5_math_fractions:fraction_pizza:l3')!;
      final learning = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          'c5_math_fraction_decimal_compare': const SkillMastery(
            competencyId: 'c5_math_fraction_decimal_compare',
            state: LearningEvidenceState.needsSupport,
            evidenceCount: 4,
            correctCount: 1,
            confidence: .3,
          ),
        },
      );

      final plan = coordinator.createOrRestoreForWorldLevel(
        repository: repository,
        level: level,
        learningState: learning,
        levelProgress: LearningLevelProgress(attempts: 2, bestRatio: .4),
        gameProgress: GameProgress(attempts: 5, correctAnswers: 2, mastery: .2),
        now: DateTime.utc(2026, 8, 23, 13),
      );

      expect(plan.trainingItems, hasLength(5));
      expect(plan.gameItems, hasLength(5));
      expect(plan.hasContentShortfall, isFalse);
      expect(plan.hasTrainingGameOverlap, isFalse);
      expect(plan.trainingItems.every((item) => item.candidate.difficulty == 3),
          isTrue);
      expect(plan.gameItems.every((item) => item.candidate.difficulty == 3),
          isTrue);
    });
  });
}

AttemptEvidence _evidence({
  required String id,
  required String competencyId,
  required bool correct,
  required DateTime at,
}) =>
    AttemptEvidence(
      id: id,
      profileId: 'child-1',
      classNumber: 4,
      competencyId: competencyId,
      itemId: 'item-$id',
      kind: LearningAttemptKind.independent,
      correct: correct,
      hintLevel: 0,
      retries: correct ? 0 : 1,
      responseTimeMs: 2000,
      confidence: correct ? .8 : .4,
      recordedAtIso: at.toIso8601String(),
      sourceGameId: 'math_market',
    );
