import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_repository.dart';
import 'package:brightquest_kids/core/curriculum/content_contract.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_contract_validator.dart';
import 'package:brightquest_kids/core/curriculum/current_content_inventory.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readJson(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

CurriculumContract _contract() => CurriculumContract.fromJson(
      _readJson('assets/content/curriculum_map.json'),
    );

CurrentContentAudit _audit() => CurrentContentAudit.fromJson(
      _readJson('assets/content/current_content_audit.json'),
    );

ContentRepository _repository() => ContentRepository.fromJsonPacks(
      curriculumJson: _readJson('assets/content/curriculum_map.json'),
      schemaJson: _readJson('assets/content/content_schema_v1.json'),
      packJson: <Map<String, dynamic>>[
        _readJson('assets/content/class_3/pack.json'),
        _readJson('assets/content/class_4/pack.json'),
        _readJson('assets/content/class_5/pack.json'),
      ],
    );

Map<String, dynamic> _validActivity(CurriculumContract contract) {
  final classPack = contract.classPack(3)!;
  final competency = classPack.competencies.first;
  final outcome = classPack.learningOutcomes
      .firstWhere((value) => value.competencyId == competency.id);
  return <String, dynamic>{
    'id': 'c3_phase0_valid_activity',
    'classNumber': 3,
    'subject': competency.subject,
    'unitId': competency.unitId,
    'competencyId': competency.id,
    'learningOutcomeId': outcome.id,
    'activityType': 'guidedPractice',
    'difficulty': 1,
    'prompt': 'Show the number represented by 3 hundreds, 2 tens and 4 ones.',
    'correctResponseRule': <String, dynamic>{'type': 'exact', 'value': 324},
    'explanation': 'Three hundreds, two tens and four ones make 324.',
    'distractors': <Map<String, dynamic>>[
      <String, dynamic>{
        'value': 234,
        'misconceptionId': 'place_value_reversal',
      },
    ],
    'hints': <Map<String, dynamic>>[
      <String, dynamic>{'step': 1, 'text': 'Start with the hundreds.'},
    ],
    'narration': <String, dynamic>{
      'text':
          'Show the number represented by three hundreds, two tens and four ones.',
    },
    'locale': 'en-IN',
    'author': 'phase0-test',
    'reviewerOwnerId': 'primary_teacher_reviewer',
    'status': 'needsReview',
    'revision': 1,
    'generation': <String, dynamic>{
      'mode': 'authored',
      'deterministicSeed': null,
    },
  };
}

void main() {
  group('Phase 0 curriculum contract', () {
    test('parses and technically validates against all current content', () {
      final contract = _contract();
      final audit = _audit();
      final inventory = currentContentInventory(_repository());
      const validator = CurriculumContractValidator();

      final result = validator.validate(
        contract: contract,
        audit: audit,
        currentContent: inventory,
      );

      expect(
        result.errors,
        isEmpty,
        reason: result.errors.map((value) => value.toString()).join('\n'),
      );
      expect(result.isValid, isTrue);
      expect(inventory, hasLength(189));
      expect(audit.selectors, hasLength(88));
    });

    test('has exactly Classes 3–5 with 30–40 competencies each', () {
      final contract = _contract();
      expect(
        contract.classes.map((value) => value.classNumber).toSet(),
        <int>{3, 4, 5},
      );
      for (final classPack in contract.classes) {
        expect(classPack.competencies.length, inInclusiveRange(30, 40));
        expect(classPack.competencies, hasLength(37));
      }
    });

    test('all curriculum IDs are unique and stay inside their class boundary',
        () {
      final contract = _contract();
      final ids = <String>{};
      for (final classPack in contract.classes) {
        final prefix = 'c${classPack.classNumber}_';
        final classIds = <String>[
          ...classPack.units.map((value) => value.id),
          ...classPack.learningOutcomes.map((value) => value.id),
          ...classPack.competencies.map((value) => value.id),
          ...classPack.currentContentMappings.map((value) => value.id),
        ];
        for (final id in classIds) {
          expect(id.startsWith(prefix), isTrue, reason: id);
          expect(ids.add(id), isTrue, reason: 'Duplicate curriculum ID: $id');
        }
      }
    });

    test('current selectors have exhaustive same-class competency mappings',
        () {
      final contract = _contract();
      final audit = _audit();
      final inventory = currentContentInventory(_repository());
      final counts = currentContentSelectorCounts(inventory);
      final audited = <String>{for (final value in audit.selectors) value.key};

      expect(audited, counts.keys.toSet());
      for (final classPack in contract.classes) {
        final competencyIds =
            classPack.competencies.map((value) => value.id).toSet();
        for (final mapping in classPack.currentContentMappings) {
          expect(mapping.disposition, 'mapped');
          expect(mapping.competencyIds, isNotEmpty);
          for (final competencyId in mapping.competencyIds) {
            expect(
              competencyIds.contains(competencyId),
              isTrue,
              reason: '${mapping.id} -> $competencyId',
            );
          }
        }
      }
    });

    test('₹299 class packs are blocked from paid claims while unreviewed', () {
      final contract = _contract();
      for (final classPack in contract.classes) {
        expect(classPack.commercial.permanentOneTimePriceInr, 299);
        expect(classPack.commercial.purchaseModel, 'oneTimePerClass');
        expect(classPack.commercial.paidEligibility, isFalse);
        expect(classPack.boundaries.approvalState, 'pendingHumanReview');
        expect(
          classPack.competencies.every(
            (value) => value.review.status == ContentReviewState.needsReview,
          ),
          isTrue,
        );
      }
      final reviewer = contract.reviewers
          .firstWhere((value) => value.id == 'primary_teacher_reviewer');
      expect(reviewer.ownerName, isNull);
      expect(reviewer.state, 'requiredUnassigned');
    });

    test('content schema v1 requires competency, evidence and review metadata',
        () {
      final schema = _readJson('assets/content/content_schema_v1.json');
      expect(schema[r'$schema'], contains('2020-12'));
      expect(schema['additionalProperties'], isFalse);
      final defs = Map<String, dynamic>.from(schema[r'$defs'] as Map);
      final activity = Map<String, dynamic>.from(defs['activity'] as Map);
      final required = Set<String>.from(activity['required'] as List);
      expect(
        required,
        containsAll(<String>{
          'id',
          'classNumber',
          'unitId',
          'competencyId',
          'learningOutcomeId',
          'correctResponseRule',
          'explanation',
          'distractors',
          'hints',
          'narration',
          'author',
          'reviewerOwnerId',
          'status',
          'revision',
          'generation',
        }),
      );
    });

    test('valid content passes the Phase 0 activity validator', () {
      final contract = _contract();
      const validator = ContentActivityValidator();
      final result = validator.validate(_validActivity(contract), contract);
      expect(
        result.errors,
        isEmpty,
        reason: result.errors.map((value) => value.toString()).join('\n'),
      );
    });

    test('invalid class, cross-class references and missing explanations fail',
        () {
      final contract = _contract();
      const validator = ContentActivityValidator();

      final invalidClass = _validActivity(contract)..['classNumber'] = 6;
      expect(validator.validate(invalidClass, contract).isValid, isFalse);

      final crossClass = _validActivity(contract);
      final class4Competency = contract.classPack(4)!.competencies.first;
      crossClass['competencyId'] = class4Competency.id;
      expect(validator.validate(crossClass, contract).isValid, isFalse);

      final missingExplanation = _validActivity(contract)
        ..remove('explanation');
      expect(
        validator.validate(missingExplanation, contract).isValid,
        isFalse,
      );
    });

    test('approved content cannot bypass named reviewer ownership', () {
      final contract = _contract();
      const validator = ContentActivityValidator();
      final activity = _validActivity(contract)..['status'] = 'approved';
      final result = validator.validate(activity, contract);
      expect(result.isValid, isFalse);
      expect(
        result.errors.map((value) => value.code),
        contains('content.approval_without_reviewer'),
      );
    });

    test('generated content requires a deterministic seed', () {
      final contract = _contract();
      const validator = ContentActivityValidator();
      final activity = _validActivity(contract)
        ..['generation'] = <String, dynamic>{
          'mode': 'generated',
          'deterministicSeed': null,
        };
      final result = validator.validate(activity, contract);
      expect(result.isValid, isFalse);
      expect(
        result.errors.map((value) => value.code),
        contains('content.generation_seed'),
      );
    });

    test('legacy runtime IDs and save schema stay unchanged', () {
      expect(curriculumTopics, hasLength(24));
      expect(learningLevels, hasLength(72));
      expect(
        learningLevelById('c3_math_operations:math_market:l1'),
        isNotNull,
      );
      expect(
        learningLevelById('c5_coding_repeat:coding_maze:l3'),
        isNotNull,
      );

      final snapshot = PlayerSnapshot();
      expect(snapshot.schemaVersion, 5);
      final roundTrip = PlayerSnapshot.fromJson(snapshot.toJson());
      expect(roundTrip.schemaVersion, 5);
      expect(roundTrip.activeProfileId, snapshot.activeProfileId);
      expect(roundTrip.profiles.keys, snapshot.profiles.keys);
    });

    test('current inventory IDs are deterministic and unique', () {
      final first = currentContentInventory(_repository());
      final second = currentContentInventory(_repository());
      expect(first.map((value) => value.id), second.map((value) => value.id));
      expect(first.map((value) => value.id).toSet(), hasLength(first.length));
      expect(
        first.where((value) => value.gameId == 'rewards_room'),
        isEmpty,
      );
    });
  });
}
