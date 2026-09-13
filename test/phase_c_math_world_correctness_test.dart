import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_learning_models.dart';
import 'package:brightquest_kids/core/nursery/nursery_practice_generator.dart';
import 'package:brightquest_kids/core/nursery/nursery_review_seed_planner.dart';
import 'package:brightquest_kids/core/nursery/nursery_spoken_labels.dart';
import 'package:brightquest_kids/core/qa/nursery_math_world_audit.dart';
import 'package:brightquest_kids/core/qa/nursery_math_world_reference.dart';
import 'package:flutter_test/flutter_test.dart';

NurseryContentPack _pack() => NurseryContentPack.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      ),
    );

void main() {
  group('Phase C Math + My World correctness', () {
    test('independent audit is release-blocker free', () {
      const audit = NurseryMathWorldAudit(generatedSeedsPerSkill: 256);
      final report = audit.audit(_pack());
      expect(report.findings, isEmpty, reason: report.findings.join('\n'));
    });

    test('all generated skills honor their non-repeat window', () {
      const generator = NurseryPracticeGenerator();
      final pack = _pack();
      for (final skill in pack.skills) {
        final requested = nurseryPhaseCNonRepeatWindow[skill.id];
        expect(requested, isNotNull, reason: skill.id);
        final window = requested!.clamp(2, 64).toInt();
        final seen = <String>{};
        for (var seed = 0; seed < window; seed += 1) {
          final practice = generator.generate(
            pack: pack,
            skill: skill,
            seed: seed,
          );
          final signature =
              '${practice.prompt}|${practice.correctResponseRule['value']}';
          expect(seen.add(signature), isTrue, reason: '${skill.id}/$seed');
        }
      }
    });

    test('counting and addition remain mathematically bounded', () {
      const generator = NurseryPracticeGenerator();
      final pack = _pack();
      for (final skillId in <String>[
        'math_count_0_5',
        'math_count_6_10',
        'math_add_objects',
        'math_add_numerals',
      ]) {
        final skill = pack.skillById(skillId)!;
        for (var seed = 0; seed < 256; seed += 1) {
          final practice = generator.generate(
            pack: pack,
            skill: skill,
            seed: seed,
          );
          final answer = int.parse(
            practice.correctResponseRule['value'] as String,
          );
          expect(answer, inInclusiveRange(0, 10), reason: '$skillId/$seed');
          if (skillId == 'math_count_6_10') {
            expect(answer, inInclusiveRange(6, 10), reason: '$skillId/$seed');
          }
          if (skillId.startsWith('math_add_')) {
            expect(answer, inInclusiveRange(2, 10), reason: '$skillId/$seed');
          }
        }
      }
    });

    test('My World generated visuals match the independent vocabulary catalog',
        () {
      const generator = NurseryPracticeGenerator();
      final pack = _pack();
      for (final entry in nurseryPhaseCWorldGeneratedCatalog.entries) {
        final skill = pack.skillById(entry.key)!;
        final seen = <String>{};
        for (var seed = 0; seed < entry.value.length; seed += 1) {
          final practice = generator.generate(
            pack: pack,
            skill: skill,
            seed: seed,
          );
          final visual = practice.visualTokens.single;
          final answer = practice.correctResponseRule['value'] as String;
          expect(entry.value[visual], answer, reason: '${entry.key}/$seed');
          seen.add('$visual|$answer');
        }
        expect(seen.length, entry.value.length, reason: entry.key);
      }
    });

    test('semantic spoken labels are stable for Math and My World', () {
      expect(
        nurserySpeakableText('How many apples are shown?'),
        'How many apples are shown?',
      );
      expect(
        nurserySpeakableText('★★ + ★ = how many stars?'),
        'star star plus star equals how many stars?',
      );
      expect(nurserySpokenLabel('red'), 'red');
      expect(nurserySpokenLabel('▲'), 'triangle');
      expect(nurserySpokenLabel('cat'), 'cat');
      expect(nurserySpokenLabel('apple'), 'apple');
      expect(nurserySpokenLabel('2 feet'), '2 feet');
    });

    test('review seed planner advances from the latest generated review', () {
      const planner = NurseryReviewSeedPlanner();
      const skillId = 'math_count_0_5';
      final first = planner.nextSeed(
          skillId: skillId, evidence: const <NurseryAttemptEvidence>[]);
      expect(
        planner.nextSeed(
            skillId: skillId, evidence: const <NurseryAttemptEvidence>[]),
        first,
      );

      final evidence = <NurseryAttemptEvidence>[
        NurseryAttemptEvidence(
          id: 'old',
          profileId: 'child-a',
          packId: NurseryContentPack.nurseryPackId,
          skillId: skillId,
          itemId: 'generated-old',
          kind: LearningAttemptKind.review,
          correct: true,
          hintLevel: 0,
          retries: 0,
          responseTimeMs: 1000,
          recordedAtIso: DateTime.utc(2026, 8, 20).toIso8601String(),
          contributesToMastery: true,
          generatedSeed: first,
        ),
        NurseryAttemptEvidence(
          id: 'new',
          profileId: 'child-a',
          packId: NurseryContentPack.nurseryPackId,
          skillId: skillId,
          itemId: 'generated-new',
          kind: LearningAttemptKind.review,
          correct: false,
          hintLevel: 0,
          retries: 0,
          responseTimeMs: 1000,
          recordedAtIso: DateTime.utc(2026, 8, 21).toIso8601String(),
          contributesToMastery: true,
          generatedSeed: first + 1,
        ),
      ];
      expect(
        planner.nextSeed(skillId: skillId, evidence: evidence),
        first + 2,
      );
    });

    test('high-risk My World wording stays precise', () {
      final pack = _pack();
      expect(
        pack.activityById('nursery.knowledge_shapes.t1')!.prompt,
        contains('front face'),
      );
      expect(
        pack.activityById('nursery.knowledge_animals.t1')!.prompt,
        contains('hooves'),
      );
      expect(
        pack.activityById('nursery.knowledge_body.t1')!.prompt,
        contains('end of each leg'),
      );
      expect(
        pack
            .activityById('nursery.knowledge_routines.t1')!
            .correctResponseRule['value'],
        'stay with the adult and wait until it is safe to cross',
      );
      expect(
        pack
            .activityById('nursery.knowledge_routines.i1')!
            .correctResponseRule['value'],
        'get dressed for the day',
      );
    });
  });
}
