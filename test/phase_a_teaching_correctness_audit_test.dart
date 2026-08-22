import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_activity.dart';
import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/qa/teaching_correctness_audit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  group('Phase A teaching correctness audit', () {
    test(
        'whole bundled app has no release-blocking simulated correctness issue',
        () {
      final repository = buildContentRepository();
      final report = const TeachingCorrectnessAudit(
        generatedSeedsPerSkill: 64,
        generatedSeedsPerClassFamily: 64,
      ).auditRepository(repository);

      final blockers = report.findings
          .where((finding) => finding.releaseBlocking)
          .map((finding) => finding.toString())
          .toList();
      expect(
        blockers,
        isEmpty,
        reason: blockers.join('\n'),
      );
      expect(report.checksRun, greaterThan(1000));
    });

    test('alphabet simulator covers authored and deterministic generated work',
        () {
      final nursery = buildContentRepository().nurseryPack!;
      final report = const TeachingCorrectnessAudit(
        generatedSeedsPerSkill: 128,
      ).auditNurseryPack(
        nursery,
        includeSkill: (skill) => skill.domainId == 'alphabet',
      );

      expect(
        report.findings.where((finding) => finding.releaseBlocking),
        isEmpty,
        reason: report.findings.join('\n'),
      );
      expect(report.checksRun, greaterThan(1000));
    });

    test('audit catches a SUN question scored as the wrong first letter', () {
      final nursery = buildContentRepository().nurseryPack!;
      final skill = nursery.skillById('alpha_uppercase')!;
      final source = nursery.activityById('nursery.alpha_uppercase.t1')!;
      final broken = NurseryActivity(
        id: source.id,
        skillId: source.skillId,
        phase: source.phase,
        interaction: source.interaction,
        prompt: source.prompt,
        narration: source.narration,
        hint: source.hint,
        successFeedback: source.successFeedback,
        wrongFeedback: source.wrongFeedback,
        options: source.options,
        payload: source.payload,
        correctResponseRule: const <String, dynamic>{
          'type': 'choice',
          'value': 'C',
        },
        masteryEligible: source.masteryEligible,
        review: source.review,
      );

      final report = const TeachingCorrectnessAudit().auditNurseryActivity(
        skill: skill,
        activity: broken,
      );

      expect(
        report.findings.map((finding) => finding.code),
        contains('nursery.authored.first_letter_answer_mismatch'),
      );
    });

    test('audit catches authored early addition with a wrong scored sum', () {
      final nursery = buildContentRepository().nurseryPack!;
      final skill = nursery.skillById('math_add_numerals')!;
      final source = nursery.activityById('nursery.math_add_numerals.g1')!;
      final broken = NurseryActivity(
        id: source.id,
        skillId: source.skillId,
        phase: source.phase,
        interaction: source.interaction,
        prompt: source.prompt,
        narration: source.narration,
        hint: source.hint,
        successFeedback: source.successFeedback,
        wrongFeedback: source.wrongFeedback,
        options: source.options,
        payload: source.payload,
        correctResponseRule: const <String, dynamic>{
          'type': 'choice',
          'value': '3',
        },
        masteryEligible: source.masteryEligible,
        review: source.review,
      );

      final report = const TeachingCorrectnessAudit().auditNurseryActivity(
        skill: skill,
        activity: broken,
      );

      expect(
        report.findings.map((finding) => finding.code),
        contains('nursery.authored.addition_answer_mismatch'),
      );
    });

    test('audit catches a Class 5 arithmetic activity with a wrong score', () {
      final repository = buildContentRepository();
      final source = repository.activityById('c5_math_market_q08')!;
      final broken = ContentActivity(
        id: source.id,
        legacyContentId: source.legacyContentId,
        classNumber: source.classNumber,
        gameId: source.gameId,
        topicId: source.topicId,
        subject: source.subject,
        unitId: source.unitId,
        competencyId: source.competencyId,
        relatedCompetencyIds: source.relatedCompetencyIds,
        learningOutcomeId: source.learningOutcomeId,
        relatedLearningOutcomeIds: source.relatedLearningOutcomeIds,
        activityType: source.activityType,
        difficulty: source.difficulty,
        prompt: source.prompt,
        correctResponseRule: const <String, dynamic>{
          'type': 'exactNumber',
          'value': 576,
        },
        explanation: source.explanation,
        distractors: source.distractors,
        hints: source.hints,
        narrationText: source.narrationText,
        locale: source.locale,
        author: source.author,
        reviewerOwnerId: source.reviewerOwnerId,
        status: source.status,
        revision: source.revision,
        generation: source.generation,
        payload: source.payload,
      );

      final report =
          const TeachingCorrectnessAudit().auditClassActivity(broken);

      expect(
        report.findings.map((finding) => finding.code),
        contains('class.authored.arithmetic_answer_mismatch'),
      );
    });

    test('number simulator covers math answers and bounded generated variants',
        () {
      final nursery = buildContentRepository().nurseryPack!;
      final report = const TeachingCorrectnessAudit(
        generatedSeedsPerSkill: 128,
      ).auditNurseryPack(
        nursery,
        includeSkill: (skill) => skill.domainId == 'math',
      );

      expect(
        report.findings.where((finding) => finding.releaseBlocking),
        isEmpty,
        reason: report.findings.join('\n'),
      );
      expect(report.checksRun, greaterThan(1000));
    });
  });

  group('Phase A schema-contract drift checks', () {
    test('Nursery schema metadata matches expanded picture-card contract', () {
      final schema = Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/schema_v1.json').readAsStringSync(),
        ) as Map,
      );
      final contract = Map<String, dynamic>.from(
        schema['letterAssociationContract'] as Map,
      );
      final requiredPerLetter =
          (contract['requiredExamplesPerLetter'] as num).toInt();
      final requiredTotal =
          (contract['requiredTotalPictureCards'] as num).toInt();
      final nursery = buildContentRepository().nurseryPack!;
      final assets = <String>{};

      expect(requiredPerLetter, greaterThanOrEqualTo(8));
      expect(requiredTotal, greaterThanOrEqualTo(200));
      for (final letter in nursery.letterAssociations) {
        expect(
          letter.examples.length,
          greaterThanOrEqualTo(requiredPerLetter),
          reason: letter.uppercase,
        );
        for (final example in letter.examples) {
          expect(assets.add(example.assetPath), isTrue,
              reason: example.assetPath);
          expect(File(example.assetPath).existsSync(), isTrue);
        }
      }
      expect(assets.length, greaterThanOrEqualTo(requiredTotal));

      final rawPack = Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      );
      final requiredTopLevel =
          List<String>.from(schema['requiredTopLevel'] as List);
      for (final field in requiredTopLevel) {
        expect(rawPack.containsKey(field), isTrue, reason: field);
      }
      final supportedInteractions =
          Set<String>.from(schema['supportedInteractions'] as List);
      final supportedRuleTypes =
          Set<String>.from(schema['supportedRuleTypes'] as List);
      for (final rawActivity
          in (rawPack['activities'] as List).whereType<Map>()) {
        expect(
          supportedInteractions,
          contains(rawActivity['interaction']),
          reason: '${rawActivity['id']}',
        );
        final rule = Map<String, dynamic>.from(
          rawActivity['correctResponseRule'] as Map,
        );
        expect(
          supportedRuleTypes,
          contains(rule['type']),
          reason: '${rawActivity['id']}',
        );
      }
    });
  });
}
