import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/learning/applied_mission_catalog.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/learning/lesson_engine.dart';
import 'package:brightquest_kids/core/learning/mastery_engine.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

AttemptEvidence _attempt(
  String id,
  LearningAttemptKind kind, {
  bool correct = true,
  int hintLevel = 0,
  int retries = 0,
}) =>
    AttemptEvidence(
      id: id,
      profileId: 'child-1',
      classNumber: 3,
      competencyId: 'c3_math_equal_sharing_division',
      itemId: id,
      kind: kind,
      correct: correct,
      hintLevel: hintLevel,
      retries: retries,
      responseTimeMs: 3000,
      confidence: 0.9,
      recordedAtIso: DateTime.utc(2026, 8, 20).toIso8601String(),
    );

void main() {
  group('Phase 3 teaching and mastery', () {
    test(
        'every competency has teach, guided, independent, transfer and review steps',
        () {
      final repository = buildContentRepository();
      const engine = LessonEngine();
      for (final classNumber in <int>[3, 4, 5]) {
        final flows = engine.buildClassDraftCoverage(
          repository: repository,
          classNumber: classNumber,
        );
        expect(flows.length, 37);
        for (final flow in flows) {
          expect(flow.hasTeaching, isTrue, reason: flow.competencyId);
          expect(flow.hasAssessment, isTrue, reason: flow.competencyId);
          final guided = flow.steps.firstWhere(
            (step) => step.kind == LessonStepKind.guidedTry,
          );
          expect(guided.hints.length, 2, reason: flow.competencyId);
          final transfer = flow.steps.firstWhere(
            (step) => step.kind == LessonStepKind.transfer,
          );
          expect(transfer.requiresIndependentResponse, isTrue);
          final exit = flow.steps.firstWhere(
            (step) => step.kind == LessonStepKind.exitTicket,
          );
          expect(exit.requiresIndependentResponse, isTrue);
          if (guided.activityId != null) {
            expect(exit.activityId, isNotNull, reason: flow.competencyId);
          } else {
            expect(exit.activityId, isNull, reason: flow.competencyId);
            expect(flow.reviewStatus, 'needsReview');
          }
        }
      }
    });

    test('runtime lessons use bundled blueprints and level difficulty', () {
      final repository = buildContentRepository();
      const engine = LessonEngine();
      expect(repository.learningBlueprints, hasLength(111));

      final blueprint = repository.learningBlueprintForCompetency(
        'c3_math_add_sub_3digit',
      )!;
      final flow = engine.buildForCompetency(
        repository: repository,
        classNumber: 3,
        competencyId: blueprint.competencyId,
      );
      expect(
        flow.steps
            .firstWhere((step) => step.kind == LessonStepKind.explanation)
            .body,
        blueprint.teach,
      );
      expect(
        flow.steps
            .firstWhere((step) => step.kind == LessonStepKind.workedExample)
            .body,
        blueprint.workedExample,
      );
      expect(
        flow.steps
            .firstWhere((step) => step.kind == LessonStepKind.review)
            .body,
        blueprint.reviewPrompt,
      );

      for (final level in levelsForGame(3, 'math_market')) {
        final levelFlow = engine.buildForLevel(
          repository: repository,
          level: level,
        );
        final exactDifficultyCompetencies = repository
            .activitiesForGame(
              level.classNumber,
              level.gameId,
              difficulty: level.difficulty,
            )
            .where((activity) => activity.difficulty == level.difficulty)
            .map((activity) => activity.competencyId)
            .toSet();
        expect(
          exactDifficultyCompetencies,
          contains(levelFlow.competencyId),
          reason: level.id,
        );
      }
    });

    test('repeated guessing cannot produce secure mastery', () {
      const mastery = MasteryEngine();
      final guessed = <AttemptEvidence>[
        _attempt('g1', LearningAttemptKind.independent, hintLevel: 1),
        _attempt('g2', LearningAttemptKind.transfer, retries: 2),
        _attempt('g3', LearningAttemptKind.review, hintLevel: 1),
      ];
      expect(mastery.guessingCannotSecure(guessed), isTrue);

      final secureEvidence = <AttemptEvidence>[
        _attempt('i1', LearningAttemptKind.independent),
        _attempt('i2', LearningAttemptKind.independent),
        _attempt('t1', LearningAttemptKind.transfer),
        _attempt('r1', LearningAttemptKind.review),
      ];
      expect(mastery.guessingCannotSecure(secureEvidence), isFalse);
    });
  });

  group('Phase 4 technical class-pack coverage', () {
    test(
        'all 111 competency blueprints remain review-blocked and complete structurally',
        () {
      var total = 0;
      for (final classNumber in <int>[3, 4, 5]) {
        final json = Map<String, dynamic>.from(
          jsonDecode(
            File('assets/content/class_$classNumber/learning_blueprints.json')
                .readAsStringSync(),
          ) as Map,
        );
        final rows = (json['blueprints'] as List).whereType<Map>().toList();
        expect(rows.length, 37);
        for (final row in rows) {
          expect(row['classNumber'], classNumber);
          expect((row['teach'] as String).trim(), isNotEmpty);
          expect((row['workedExample'] as String).trim(), isNotEmpty);
          expect((row['reviewPrompt'] as String).trim(), isNotEmpty);
          expect((row['review'] as Map)['status'], 'needsReview');
          total += 1;
        }
      }
      expect(total, 111);
    });
  });

  group('Phase 6 applied missions', () {
    test('every major subject has three safe multi-skill missions per class',
        () {
      final repository = buildContentRepository();
      const catalog = AppliedMissionCatalog();
      for (final classNumber in <int>[3, 4, 5]) {
        final missions = catalog.forClass(repository.curriculum, classNumber);
        final bySubject = <String, int>{};
        for (final mission in missions) {
          bySubject[mission.subject] = (bySubject[mission.subject] ?? 0) + 1;
          expect(mission.competencyIds.toSet().length, greaterThanOrEqualTo(2));
          expect(mission.safeLocalInputOnly, isTrue);
        }
        for (final subject in <String>[
          'maths',
          'english',
          'science',
          'evs',
          'social',
          'coding',
        ]) {
          expect(bySubject[subject], 3, reason: 'Class $classNumber $subject');
        }
      }
    });
  });
}
