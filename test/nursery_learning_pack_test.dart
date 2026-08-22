import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/curriculum/content_contract.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_learning_models.dart';
import 'package:brightquest_kids/core/nursery/nursery_practice_generator.dart';
import 'package:brightquest_kids/core/nursery/nursery_progress_engine.dart';
import 'package:brightquest_kids/core/nursery/nursery_response_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readJson(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

NurseryContentPack _pack() => NurseryContentPack.fromJson(
      _readJson('assets/content/nursery/pack_v1.json'),
    );

NurseryAttemptEvidence _evidence({
  required String id,
  required String itemId,
  required LearningAttemptKind kind,
  required DateTime at,
  bool correct = true,
  int hintLevel = 0,
  int retries = 0,
  bool contributesToMastery = true,
}) =>
    NurseryAttemptEvidence(
      id: id,
      profileId: 'child-a',
      packId: NurseryContentPack.nurseryPackId,
      skillId: 'alpha_uppercase',
      itemId: itemId,
      kind: kind,
      correct: correct,
      hintLevel: hintLevel,
      retries: retries,
      responseTimeMs: 1200,
      recordedAtIso: at.toIso8601String(),
      contributesToMastery: contributesToMastery,
    );

void main() {
  group('Nursery content contract', () {
    test('bundled pack has complete reviewable v1 coverage', () {
      final pack = _pack();
      expect(pack.packId, NurseryContentPack.nurseryPackId);
      expect(pack.contentVersion, 1);
      expect(pack.skills, hasLength(32));
      expect(pack.activities, hasLength(132));
      expect(pack.letterAssociations, hasLength(26));
      expect(pack.letterAssociations.first.uppercase, 'A');
      expect(pack.letterAssociations.last.uppercase, 'Z');
      final discoveryAssets = <String>{};
      for (final letter in pack.letterAssociations) {
        expect(letter.examples.length, greaterThanOrEqualTo(8),
            reason: letter.uppercase);
        for (final example in letter.examples) {
          expect(example.word, isNotEmpty, reason: letter.uppercase);
          expect(example.picture, isNotEmpty, reason: example.word);
          expect(example.soundCue, isNotEmpty, reason: example.word);
          expect(example.displayPhrase, isNotEmpty, reason: example.word);
          expect(File(example.assetPath).existsSync(), isTrue,
              reason: example.assetPath);
          expect(discoveryAssets.add(example.assetPath), isTrue,
              reason: example.assetPath);
        }
      }
      expect(discoveryAssets.length, greaterThanOrEqualTo(200));
      expect(pack.commercial.permanentOneTimePriceInr, 299);
      expect(pack.commercial.paidEligibility, isFalse);
      expect(pack.commercial.freeSampleActivityIds, hasLength(4));
      expect(pack.releaseGates.allExternalGatesRecorded, isFalse);
      expect(pack.review.status, ContentReviewState.needsReview);

      for (final skill in pack.skills) {
        final activities = pack.activitiesForSkill(skill.id);
        expect(activities.where((item) => item.isGuided), isNotEmpty,
            reason: skill.id);
        expect(activities.where((item) => item.isIndependent).length,
            greaterThanOrEqualTo(2),
            reason: skill.id);
        expect(activities.where((item) => item.isTransfer), isNotEmpty,
            reason: skill.id);
        expect(skill.generatorFamily, isNotNull, reason: skill.id);
      }
      expect(
        pack.activities.where((activity) => activity.isTrace),
        everyElement(predicate<NurseryActivity>(
          (activity) => !activity.masteryEligible,
        )),
      );
    });
  });

  group('Nursery response evaluator', () {
    const evaluator = NurseryResponseEvaluator();

    test('choice evaluator accepts only the authored answer and preserves case',
        () {
      final uppercase = _pack().activityById('nursery.alpha_uppercase.g1')!;
      expect(evaluator.evaluate(uppercase, 'A').correct, isTrue);
      expect(evaluator.evaluate(uppercase, 'a').correct, isFalse);
      expect(evaluator.evaluate(uppercase, 'B').correct, isFalse);

      final lowercase = _pack().activityById('nursery.alpha_lowercase.g1')!;
      expect(evaluator.evaluate(lowercase, 'a').correct, isTrue);
      expect(evaluator.evaluate(lowercase, 'A').correct, isFalse);
    });

    test('answer explanation follows the current activity, not worked example',
        () {
      final activity = _pack().activityById('nursery.alpha_uppercase.t1')!;
      final explanation = evaluator.explanationFor(activity);
      expect(evaluator.correctResponseLabel(activity), 'S');
      expect(explanation.text, 'SUN starts with S.');
      expect(explanation.visualTokens, <String>['SUN', '→', 'S']);
      expect(explanation.text, isNot(contains('Apple')));
      expect(explanation.visualTokens, isNot(contains('A')));
    });

    test('pair matching requires the complete exact mapping', () {
      final activity = _pack().activities.firstWhere(
            (item) => item.interaction == 'pairMatch',
          );
      final expected = Map<String, String>.from(
        activity.correctResponseRule['pairs'] as Map,
      );
      expect(evaluator.evaluate(activity, expected).correct, isTrue);
      final broken = Map<String, String>.from(expected);
      broken[broken.keys.first] = 'wrong';
      expect(evaluator.evaluate(activity, broken).correct, isFalse);
    });

    test('sorting requires the complete exact mapping', () {
      final activity = _pack().activities.firstWhere(
            (item) => item.interaction == 'sortBuckets',
          );
      final expected = Map<String, String>.from(
        activity.correctResponseRule['assignments'] as Map,
      );
      expect(evaluator.evaluate(activity, expected).correct, isTrue);
      expect(evaluator.evaluate(activity, <String, String>{}).correct, isFalse);
    });

    test('tracing checks ordered guide checkpoints, not handwriting quality',
        () {
      final activity = _pack().activities.firstWhere((item) => item.isTrace);
      final count =
          (activity.correctResponseRule['checkpointCount'] as num).toInt();
      final ordered = List<int>.generate(count, (index) => index);
      expect(evaluator.evaluate(activity, ordered).correct, isTrue);
      expect(evaluator.evaluate(activity, ordered.reversed.toList()).correct,
          isFalse);
      expect(activity.masteryEligible, isFalse);
    });
  });

  group('Nursery deterministic generated practice', () {
    const generator = NurseryPracticeGenerator();

    test('every skill generator is deterministic and bounded', () {
      final pack = _pack();
      for (final skill in pack.skills) {
        final first = generator.generate(pack: pack, skill: skill, seed: 90210);
        final second =
            generator.generate(pack: pack, skill: skill, seed: 90210);
        expect(second.id, first.id, reason: skill.id);
        expect(second.prompt, first.prompt, reason: skill.id);
        expect(
          second.options.map((option) => option.id).toList(),
          first.options.map((option) => option.id).toList(),
          reason: skill.id,
        );
        final ids = first.options.map((option) => option.id).toList();
        expect(ids.toSet().length, ids.length, reason: skill.id);
        expect(ids.length, greaterThanOrEqualTo(2), reason: skill.id);
        expect(first.skillId, skill.id);
        expect(first.correctResponseRule['type'], 'choice');
        expect(ids, contains(first.correctResponseRule['value']));
      }
    });

    test('alphabet generators use expanded words deterministically', () {
      final pack = _pack();
      final wordSkill = pack.skillById('alpha_word_picture')!;
      final beginningSkill = pack.skillById('alpha_beginning_sound')!;
      final generatedWords = <String>{};
      for (var seed = 0; seed < 300; seed += 1) {
        final practice = generator.generate(
          pack: pack,
          skill: wordSkill,
          seed: seed,
        );
        generatedWords.add(practice.correctResponseRule['value'] as String);
        final beginning = generator.generate(
          pack: pack,
          skill: beginningSkill,
          seed: seed,
        );
        expect(beginning.prompt, isNot(contains('begins Box')));
        expect(beginning.prompt, isNot(contains('begins X-ray')));
        expect(beginning.prompt, isNot(contains('begins Xylophone')));
      }
      expect(generatedWords.length, greaterThan(100));
      expect(generatedWords, contains('Ant'));
      expect(generatedWords, contains('Banana'));
      expect(generatedWords, contains('Butterfly'));
      expect(generatedWords, contains('Carrot'));
    });

    test('generated early addition never exceeds 10', () {
      final pack = _pack();
      final skill = pack.skillById('math_add_objects')!;
      for (var seed = 0; seed < 200; seed += 1) {
        final practice =
            generator.generate(pack: pack, skill: skill, seed: seed);
        final answer =
            int.parse(practice.correctResponseRule['value'] as String);
        expect(answer, inInclusiveRange(2, 10), reason: 'seed $seed');
      }
    });
  });

  group('Nursery evidence and migration', () {
    const engine = NurseryProgressEngine();

    test('mastery needs two distinct clean independent items and transfer', () {
      final start = DateTime.utc(2026, 8, 20, 10);
      var state = const NurseryLearningState();
      state = engine.record(
        state,
        _evidence(
          id: 'i1',
          itemId: 'independent-a',
          kind: LearningAttemptKind.independent,
          at: start,
        ),
      );
      state = engine.record(
        state,
        _evidence(
          id: 'i1-repeat',
          itemId: 'independent-a',
          kind: LearningAttemptKind.independent,
          at: start.add(const Duration(minutes: 1)),
        ),
      );
      expect(
        state.skillMastery['alpha_uppercase']!.cleanIndependentCorrectCount,
        1,
      );
      state = engine.record(
        state,
        _evidence(
          id: 'i2',
          itemId: 'independent-b',
          kind: LearningAttemptKind.independent,
          at: start.add(const Duration(minutes: 2)),
        ),
      );
      state = engine.record(
        state,
        _evidence(
          id: 't1',
          itemId: 'transfer-a',
          kind: LearningAttemptKind.transfer,
          at: start.add(const Duration(minutes: 3)),
        ),
      );
      expect(
        state.skillMastery['alpha_uppercase']!.state,
        LearningEvidenceState.masteredNow,
      );
      expect(state.reviewTasks, hasLength(1));
    });

    test('early review cannot secure mastery; due review can', () {
      final start = DateTime.utc(2026, 8, 20, 10);
      var state = const NurseryLearningState();
      for (final entry in <(String, String, LearningAttemptKind)>[
        ('i1', 'independent-a', LearningAttemptKind.independent),
        ('i2', 'independent-b', LearningAttemptKind.independent),
        ('t1', 'transfer-a', LearningAttemptKind.transfer),
      ]) {
        state = engine.record(
          state,
          _evidence(
            id: entry.$1,
            itemId: entry.$2,
            kind: entry.$3,
            at: start,
          ),
        );
      }
      state = engine.record(
        state,
        _evidence(
          id: 'too-early',
          itemId: 'review-generated',
          kind: LearningAttemptKind.review,
          at: start.add(const Duration(hours: 2)),
        ),
      );
      expect(
        state.skillMastery['alpha_uppercase']!.cleanDelayedReviewSuccesses,
        0,
      );
      expect(
        state.skillMastery['alpha_uppercase']!.state,
        LearningEvidenceState.masteredNow,
      );

      final due = DateTime.parse(state.reviewTasks.single.dueIso);
      state = engine.refreshReviewStates(state, due);
      expect(
        state.skillMastery['alpha_uppercase']!.state,
        LearningEvidenceState.reviewDue,
      );
      state = engine.record(
        state,
        _evidence(
          id: 'due-review',
          itemId: 'review-generated-2',
          kind: LearningAttemptKind.review,
          at: due.add(const Duration(minutes: 1)),
        ),
      );
      expect(
        state.skillMastery['alpha_uppercase']!.state,
        LearningEvidenceState.secure,
      );
      expect(state.reviewTasks.single.completed, isTrue);
    });

    test('tracing evidence is retained but never creates mastery', () {
      final state = engine.record(
        const NurseryLearningState(),
        _evidence(
          id: 'trace',
          itemId: 'trace-a',
          kind: LearningAttemptKind.guided,
          at: DateTime.utc(2026, 8, 20),
          contributesToMastery: false,
        ),
      );
      expect(state.attemptEvidence, hasLength(1));
      expect(state.skillMastery, isEmpty);
    });

    test('schema v5 profile migrates additively to v6 Nursery state', () {
      final legacy = <String, Object?>{
        'schemaVersion': 5,
        'activeProfileId': 'child-a',
        'profiles': <String, Object?>{
          'child-a': ChildProfileSnapshot(id: 'child-a', name: 'A').toJson(),
        },
      };
      final restored = PlayerSnapshot.fromJson(legacy);
      expect(restored.schemaVersion, 6);
      expect(restored.activeProfile.selectedClass, inInclusiveRange(3, 5));
      expect(restored.activeProfile.nurseryLearning.attemptEvidence, isEmpty);
      expect(restored.toJson()['profiles'], isA<Map>());
      expect(
        (restored.activeProfile.toJson()['nurseryLearning'] as Map)['packId'],
        NurseryContentPack.nurseryPackId,
      );
    });
  });
}
