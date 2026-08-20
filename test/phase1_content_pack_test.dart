import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_generators.dart';
import 'package:brightquest_kids/core/content/content_pack_validator.dart';
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

List<Map<String, dynamic>> _packJson() => <Map<String, dynamic>>[
      _readJson('assets/content/class_3/pack.json'),
      _readJson('assets/content/class_4/pack.json'),
      _readJson('assets/content/class_5/pack.json'),
    ];

ContentRepository _repository({DevelopmentPackAccessPolicy? accessPolicy}) =>
    ContentRepository.fromJsonPacks(
      curriculumJson: _readJson('assets/content/curriculum_map.json'),
      schemaJson: _readJson('assets/content/content_schema_v1.json'),
      packJson: _packJson(),
      accessPolicy: accessPolicy ?? DevelopmentPackAccessPolicy.disabled,
    );

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

Set<String> _errorCodes(ContentPackValidationResult result) =>
    result.errors.map((issue) => issue.code).toSet();

void main() {
  group('Phase 1 bundled class packs', () {
    test('all packs parse and preserve the complete legacy inventory', () {
      final repository = _repository();
      expect(repository.packs.map((pack) => pack.classNumber), <int>[3, 4, 5]);
      expect(repository.packs.map((pack) => pack.activities.length),
          everyElement(63));
      expect(repository.allActivities.length, 189);

      final inventory = currentContentInventory(repository);
      expect(inventory.length, 189);

      final audit = CurrentContentAudit.fromJson(
        _readJson('assets/content/current_content_audit.json'),
      );
      expect(audit.selectors.length, 88);
      final counts = currentContentSelectorCounts(inventory);
      for (final selector in audit.selectors) {
        expect(
          counts[selector.key],
          selector.expectedCurrentRecordCount,
          reason: 'Legacy selector drifted: ${selector.key}',
        );
      }

      const validator = CurriculumContractValidator();
      final result = validator.validate(
        contract: repository.curriculum,
        audit: audit,
        currentContent: inventory,
      );
      expect(result.errors, isEmpty);
    });

    test('activity IDs and commercial boundaries remain class scoped', () {
      final repository = _repository();
      final ids = <String>{};
      for (final pack in repository.packs) {
        expect(pack.commercial.priceInr, 299);
        expect(pack.commercial.purchaseModel, 'oneTimePerClass');
        expect(pack.commercial.paidEligibility, isFalse);
        expect(pack.development.lockable, isTrue);
        for (final activity in pack.activities) {
          expect(activity.classNumber, pack.classNumber);
          expect(activity.id, startsWith('c${pack.classNumber}_'));
          expect(ids.add(activity.id), isTrue, reason: activity.id);
          expect(activity.explanation.trim(), isNotEmpty);
          expect(activity.status, 'needsReview');
          expect(activity.reviewerOwnerId, 'primary_teacher_reviewer');
        }
      }
      expect(ids.length, 189);
    });

    test('locked packs expose one beginner demo per game, not whole units', () {
      final repository = _repository();
      for (final pack in repository.packs) {
        final samples = repository.freeSampleActivitiesForClass(
          pack.classNumber,
        );
        expect(samples, hasLength(8));
        expect(
            samples.map((activity) => activity.gameId).toSet(), hasLength(8));
        expect(
          samples.every((activity) => activity.difficulty == 1),
          isTrue,
        );
        expect(
          pack.commercial.freeSampleActivityIds.toSet(),
          samples.map((activity) => activity.id).toSet(),
        );
        expect(
          repository.curriculum
              .classPack(pack.classNumber)!
              .commercial
              .freeSampleCandidateActivityIds
              .toSet(),
          pack.commercial.freeSampleActivityIds.toSet(),
        );
        for (final unitId in samples.map((activity) => activity.unitId)) {
          expect(
            samples.where((activity) => activity.unitId == unitId).length,
            lessThan(
              pack.activities
                  .where((activity) => activity.unitId == unitId)
                  .length,
            ),
          );
        }
      }
    });

    test('missing explanation is rejected', () {
      final packs = _packJson();
      final broken = _deepCopy(packs.first);
      final activities = broken['activities'] as List<dynamic>;
      (activities.first as Map<String, dynamic>)['explanation'] = '';

      const validator = ContentPackValidator();
      final result = validator.validateAll(
        packs: <Map<String, dynamic>>[broken, packs[1], packs[2]],
        curriculum: CurriculumContract.fromJson(
          _readJson('assets/content/curriculum_map.json'),
        ),
      );
      expect(_errorCodes(result), contains('activity.explanation'));
    });

    test('duplicate activity IDs are rejected', () {
      final packs = _packJson();
      final broken = _deepCopy(packs.first);
      final activities = broken['activities'] as List<dynamic>;
      final first = activities[0] as Map<String, dynamic>;
      final second = activities[1] as Map<String, dynamic>;
      second['id'] = first['id'];

      const validator = ContentPackValidator();
      final result = validator.validateAll(
        packs: <Map<String, dynamic>>[broken, packs[1], packs[2]],
        curriculum: CurriculumContract.fromJson(
          _readJson('assets/content/curriculum_map.json'),
        ),
      );
      final codes = _errorCodes(result);
      expect(
        codes.contains('activity.duplicate_id') ||
            codes.contains('packs.duplicate_activity_id'),
        isTrue,
      );
    });

    test('a distractor equal to the answer is rejected', () {
      final packs = _packJson();
      final broken = _deepCopy(packs.first);
      final activities = broken['activities'] as List<dynamic>;
      final math = activities.firstWhere(
        (value) => (value as Map<String, dynamic>)['gameId'] == 'math_market',
      ) as Map<String, dynamic>;
      final answer =
          (math['correctResponseRule'] as Map<String, dynamic>)['value'];
      final distractors = math['distractors'] as List<dynamic>;
      (distractors.first as Map<String, dynamic>)['value'] = answer;

      const validator = ContentPackValidator();
      final result = validator.validateAll(
        packs: <Map<String, dynamic>>[broken, packs[1], packs[2]],
        curriculum: CurriculumContract.fromJson(
          _readJson('assets/content/curriculum_map.json'),
        ),
      );
      expect(
          _errorCodes(result), contains('activity.distractor_equals_answer'));
    });

    test('an impossible coding mission is rejected', () {
      final packs = _packJson();
      final broken = _deepCopy(packs.first);
      final activities = broken['activities'] as List<dynamic>;
      final coding = activities.firstWhere(
        (value) => (value as Map<String, dynamic>)['gameId'] == 'coding_maze',
      ) as Map<String, dynamic>;
      final payload = coding['payload'] as Map<String, dynamic>;
      payload['maxCommands'] = 0;
      payload['goalX'] = payload['startX'] == 0 ? 1 : 0;
      payload['goalY'] = payload['startY'];

      const validator = ContentPackValidator();
      final result = validator.validateAll(
        packs: <Map<String, dynamic>>[broken, packs[1], packs[2]],
        curriculum: CurriculumContract.fromJson(
          _readJson('assets/content/curriculum_map.json'),
        ),
      );
      expect(_errorCodes(result), contains('payload.coding_impossible'));
    });
  });

  group('Phase 1 generators', () {
    test('all generator families are deterministic and solvable', () {
      const generators = DeterministicContentGenerators();
      for (final classNumber in const <int>[3, 4, 5]) {
        for (final difficulty in const <int>[1, 2, 3]) {
          for (var seed = 0; seed < 30; seed += 1) {
            final math = generators.arithmetic(
              classNumber: classNumber,
              difficulty: difficulty,
              seed: seed,
            );
            final mathAgain = generators.arithmetic(
              classNumber: classNumber,
              difficulty: difficulty,
              seed: seed,
            );
            expect(math.text, mathAgain.text);
            expect(math.answer, mathAgain.answer);
            expect(math.choices, mathAgain.choices);
            expect(math.choices.toSet().length, math.choices.length);
            expect(
                math.choices.where((value) => value == math.answer).length, 1);

            final fraction = generators.fraction(
              classNumber: classNumber,
              difficulty: difficulty,
              seed: seed,
            );
            final selected = fraction.totalSlices * fraction.numerator;
            expect(selected % fraction.denominator, 0);
            expect(selected ~/ fraction.denominator,
                lessThanOrEqualTo(fraction.totalSlices));

            final grammar = generators.grammar(
              classNumber: classNumber,
              difficulty: difficulty,
              seed: seed,
            );
            expect(grammar.sentence, contains(grammar.noun));
            expect(grammar.sentence, contains(grammar.verb));
            expect(grammar.sentence, contains(grammar.adjective));

            final map = generators.mapDirection(
              classNumber: classNumber,
              difficulty: difficulty,
              seed: seed,
            );
            expect(map.choices.toSet().length, map.choices.length);
            expect(map.choices.where((value) => value == map.answer).length, 1);
          }
        }
      }
    });

    test('paid practice banks add 48 deterministic variants per class', () {
      final repository = _repository();
      for (final classNumber in const <int>[3, 4, 5]) {
        final generatedIds = <String>{
          ...repository
              .mathQuestionsForClass(classNumber)
              .map((item) => item.id)
              .where((id) => id.startsWith('gen_')),
          ...repository
              .fractionMissionsForClass(classNumber)
              .map((item) => item.id)
              .where((id) => id.startsWith('gen_')),
          ...repository
              .grammarMissionsForClass(classNumber)
              .map((item) => item.id)
              .where((id) => id.startsWith('gen_')),
          ...repository
              .mapQuestionsForClass(classNumber)
              .map((item) => item.id)
              .where((id) => id.startsWith('gen_')),
        };
        expect(
          generatedIds,
          hasLength(ContentRepository.generatedPracticeVariantCountPerClass),
        );
        for (final id in generatedIds) {
          final family = id.split('_')[1];
          final gameId = switch (family) {
            'math' => 'math_market',
            'fraction' => 'fraction_pizza',
            'grammar' => 'grammar_puzzle',
            'map' => 'map_quest',
            _ => throw StateError('Unexpected family $family'),
          };
          final activity = repository.activityForLegacyContent(
            classNumber: classNumber,
            gameId: gameId,
            legacyContentId: id,
          );
          expect(activity, isNotNull, reason: id);
          expect(activity!.generation.mode, 'generated');
          expect(activity.status, 'needsReview');
        }
      }
    });
  });

  group('Phase 1 compatibility and development locking', () {
    test('legacy curriculum and progress IDs survive schema-v5 round trip', () {
      expect(curriculumTopics.length, 24);
      expect(learningLevels.length, 72);
      final expectedLevelId = 'c3_math_operations:math_market:l1';
      expect(
          learningLevels.map((level) => level.id), contains(expectedLevelId));

      final snapshot = PlayerSnapshot();
      snapshot.activeProfile.gameProgress['math_market'] = GameProgress(
        attempts: 7,
        correctAnswers: 5,
        topicProgress: <String, TopicProgress>{
          'division': TopicProgress(
            attempts: 4,
            correctAnswers: 3,
            lastDifficulty: 2,
          ),
        },
      );
      snapshot.activeProfile.levelProgress[expectedLevelId] =
          LearningLevelProgress(
        attempts: 3,
        completedRuns: 1,
        bestScore: 8,
        bestMaxScore: 10,
        bestRatio: 0.8,
        earnedStars: 2,
      );

      final restored = PlayerSnapshot.fromJson(snapshot.toJson());
      expect(restored.schemaVersion, 5);
      expect(restored.activeProfile.gameProgress['math_market']!.attempts, 7);
      expect(
        restored.activeProfile.gameProgress['math_market']!
            .topicProgress['division']!.correctAnswers,
        3,
      );
      expect(restored.activeProfile.levelProgress[expectedLevelId]!.bestRatio,
          0.8);
    });

    test('development pack locks never alter the pack data itself', () {
      final repository = _repository(
        accessPolicy: const DevelopmentPackAccessPolicy(
          enabled: true,
          lockedClasses: <int>{4},
        ),
      );
      expect(repository.isClassPackUnlocked(3), isTrue);
      expect(repository.isClassPackUnlocked(4), isFalse);
      expect(repository.isClassPackUnlocked(5), isTrue);
      expect(repository.packForClass(4).activities.length, 63);
      expect(
        () => repository.mathQuestionsForClass(4),
        throwsA(isA<StateError>()),
      );
    });

    test('game UI no longer owns hard-coded class content banks', () {
      final bankSource =
          File('lib/core/content/game_content.dart').readAsStringSync();
      for (final legacyLookup in const <String>[
        'mathQuestionsForClass',
        'fractionMissionsForClass',
        'scienceQuestionsForClass',
        'storyMissionsForClass',
        'grammarMissionsForClass',
        'mapQuestionsForClass',
        'codingMissionsForClass',
        'recyclingItemsForClass',
        'evaluateReaction',
      ]) {
        expect(bankSource, isNot(contains(legacyLookup)));
      }

      const screens = <String>[
        'math_market_screen.dart',
        'fraction_pizza_screen.dart',
        'science_lab_screen.dart',
        'story_builder_screen.dart',
        'grammar_puzzle_screen.dart',
        'map_quest_screen.dart',
        'coding_maze_screen.dart',
        'recycling_challenge_screen.dart',
      ];
      for (final screen in screens) {
        final source = File('lib/features/games/$screen').readAsStringSync();
        expect(source, contains('BrightQuestScope.contentOf(context)'));
      }
    });
  });
}
