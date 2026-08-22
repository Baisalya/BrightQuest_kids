import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/learning/activity_response_evaluator.dart';
import 'package:brightquest_kids/core/learning/diagnostic_engine.dart';
import 'package:brightquest_kids/core/qa/class_curriculum_hardening_audit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

Map<String, dynamic> _json(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

void main() {
  group('Phase E Classes 3-5 curriculum hardening', () {
    test('all class packs carry the 63 legacy + 48 Skill Studio records', () {
      final repository = buildContentRepository();
      expect(repository.allActivities, hasLength(333));
      for (final classNumber in const <int>[3, 4, 5]) {
        final pack = repository.packForClass(classNumber);
        expect(pack.activities, hasLength(111));
        expect(
          pack.activities
              .where((activity) => activity.gameId == 'skill_studio'),
          hasLength(48),
        );
        expect(
          repository.curriculum.classPack(classNumber)!.competencies,
          hasLength(37),
        );
      }
    });

    test('independent technical curriculum audit has no blocking findings', () {
      final repository = buildContentRepository();
      final report = const ClassCurriculumHardeningAudit().audit(repository);
      expect(
        report.releaseBlockingFindings,
        isEmpty,
        reason: report.findings.join('\n'),
      );
      expect(
        report.constructedResponseGapIds,
        <String>{
          'c3_eng_short_composition',
          'c5_eng_explain_justify',
        },
      );
    });

    test('productive writing stays practice-only instead of fake mastery', () {
      final repository = buildContentRepository();
      for (final competencyId in const <String>[
        'c3_eng_short_composition',
        'c5_eng_explain_justify',
      ]) {
        final classNumber = competencyId.startsWith('c3_') ? 3 : 5;
        final activities = repository
            .activitiesForCompetency(classNumber, competencyId)
            .where((activity) => activity.gameId == 'skill_studio')
            .toList(growable: false);
        expect(activities, hasLength(4));
        expect(
          activities.every(
            (activity) => activity.payload['masteryEligible'] == false,
          ),
          isTrue,
        );
        expect(
          activities.every(
            (activity) =>
                activity.payload['evidenceScope'] ==
                'practiceOnlyConstructedResponsePending',
          ),
          isTrue,
        );
      }
    });

    test('diagnostic never converts practice-only writing into scored evidence',
        () {
      final repository = buildContentRepository();
      for (final classNumber in const <int>[3, 5]) {
        final progress = const DiagnosticEngine(targetItemCount: 100).start(
          repository: repository,
          classNumber: classNumber,
          now: DateTime.utc(2026, 8, 22),
        );
        for (final activityId in progress.itemIds) {
          final activity = repository.activityById(activityId)!;
          expect(activity.payload['masteryEligible'], isNot(false),
              reason: activity.id);
        }
      }
    });

    test('Phase E removed old generic blueprint placeholders', () {
      const generic = <String>[
        'Learn the idea in small steps:',
        'Use a new example to show that you can:',
        'Apply this idea in a different situation:',
        'Remember and explain one example of:',
      ];
      for (final classNumber in const <int>[3, 4, 5]) {
        final raw = _json(
          'assets/content/class_$classNumber/learning_blueprints.json',
        );
        final source = jsonEncode(raw);
        for (final phrase in generic) {
          expect(source, isNot(contains(phrase)), reason: 'Class $classNumber');
        }
      }
    });

    test('capitalization and editing choices are scored case-sensitively', () {
      final repository = buildContentRepository();
      const evaluator = ActivityResponseEvaluator();
      final cases = <(String, String, String)>[
        (
          'c3_skill_studio_eng_punctuation_capitals_g1',
          'Rina plays outside.',
          'rina plays outside.'
        ),
        (
          'c4_skill_studio_eng_punctuation_t1',
          'Can we leave now?',
          'can we leave now?'
        ),
        (
          'c5_skill_studio_eng_punctuation_editing_m1',
          'Ravi and Meena are preparing their project.',
          'ravi and Meena are preparing their project'
        ),
      ];
      for (final entry in cases) {
        final activity = repository.activityById(entry.$1)!;
        expect(activity.correctResponseRule['type'], 'exactTextCaseSensitive');
        expect(evaluator.evaluate(activity, entry.$2).correct, isTrue);
        expect(evaluator.evaluate(activity, entry.$3).correct, isFalse);
      }
    });

    test('known ambiguous teaching regressions stay corrected', () {
      final repository = buildContentRepository();
      expect(
        repository.activityById('c3_math_market_q04')!.explanation,
        '125 + 75 = 125 + 25 + 50 = 150 + 50 = 200.',
      );
      expect(
        repository
            .activityById('c3_grammar_puzzle_grammar3_5')!
            .payload['sentence'],
        'A gentle breeze blows.',
      );
      expect(
        repository
            .activityById('c5_grammar_puzzle_grammar5_6')!
            .payload['sentence'],
        'A determined athlete trains.',
      );
      expect(
        repository.activityById('c3_map_quest_map3_2')!.prompt,
        'The park is north of your school. Which way do you travel?',
      );
      expect(
        repository.allActivities
            .where((activity) => activity.gameId == 'recycling_challenge')
            .every(
              (activity) => activity.explanation
                  .contains('Real local recycling rules can differ.'),
            ),
        isTrue,
      );
    });
  });
}
